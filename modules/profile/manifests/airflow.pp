# == Class profile::airflow
# Creates airflow::instance resources for each of $airflow_instances
#
# === Parameters
#
# [*airflow_instances*]
#   Hash of airflow::instance parameters keyed by name.  This will be
#   passed directly to the create_resources function. E.g.
#       myinstanceA:
#           service_user: ...
#           ...
#       myinstanceB:
#           service_user: ...
#           connections:
#             analytics-mariadb:
#               conn_type: mysql
#               host: ...
#               ...
#           ...
#
# [*airflow_instances_secrets*]
#   Any sensitive parameters that you don't want to put directly into puppet hiera
#   airflow_instances should be defined in puppet private hiera in this variable.
#   This is the exact same structure as $airflow_instances and will be merged on
#   top of it before being passed to create_resources.  The params here should be keyed by
#   the same instance names as in $airflow_instances.  E.g.
#       myinstanceA:
#           db_password: SECRET
#       myinstanceB:
#           db_password: SECRET
#           connections:
#             analytics-mariadb:
#               login: myuser
#               password: SECRET
#
#   Default: {}
#
# [*use_wmf_defaults]
#   If true, defaults for WMF Data Engineering airflow deployments
#   will be merged into each of the provided instance's params.
#   This reduces Hiera boilerplate needed with conventions we use to deploy Airflow.
#   Default: true
#
#   Notably:
#   - A scap::target for airflow-dags/$title is declared.
#     This target is expected to be for the data-engineering/airflow-dags
#     repository, and contains the instance specific dags_folder inside
#     at $title/dags.
#   - dags_folder will default to /srv/deployment/airflow-dags/$title/$title/dags
#   - Ferm will default to only allowing $ANALYTICS_NETWORKS to the airflow instance services.
#   - Common Airflow connections are configured.
#
# [*airflow_database_host_default*]
#   Hostname used in the default sql_alchemy_conn when use_wmf_defaults is true.
#   Default: an-coord1001.eqiad.wmnet
#
class profile::airflow(
    Hash    $airflow_instances             = lookup('profile::airflow::instances'),
    Hash    $airflow_instances_secrets     = lookup('profile::airflow::instances_secrets', { 'default_value' => {} }),
    Boolean $use_wmf_defaults              = lookup('profile::airflow::use_wmf_defaults', { 'default_value' => true }),
    String  $airflow_database_host_default = lookup('profile::airflow::database_host_default', { 'default_value' => 'an-coord1001.eqiad.wmnet' })
) {

    # If use_wmf_defaults, merge in smart per instance wmf defaults.
    $airflow_instances_with_defaults = $use_wmf_defaults ? {
        # Not $use_wmf_defaults, keep $airflow_instances as provided.
        default => $airflow_instances,

        # If $use_wmf_defaults, create a dynamic set of defaults for each instance's params
        # and merge those defaults in to create a new Hash of
        # { instance name => instance_params (with smart defaults) }
        true    => $airflow_instances.reduce({}) |$instances_accumulator, $key_value| {
            $instance_name = $key_value[0]
            $instance_params = $key_value[1]
            $airflow_home = "/srv/airflow-${instance_name}"
            # This is where scap will deploy
            $deployment_dir = "/srv/deployment/airflow-dags/${instance_name}"


            # Used in places where '-', etc. won't work, like database names.
            $instance_name_normalized = regsubst($instance_name, '\W', '_', 'G')


            # scap::targets should use the same $ensure for the airflow::instance.
            $scap_target_ensure = $instance_params['ensure'] ? {
                undef   => 'present',
                default => $instance_params['ensure']
            }

            # We don't want to deep_merge scap_targets, but allow a full override
            # if provided in $instance_params. I.e. If the configured instance
            # explicitly declares scap_targets, ONLY use those scap_targets,
            # don't use our smart scap_target defaults.
            $default_scap_targets = has_key($instance_params, 'scap_targets') ? {
                true    => undef,
                default => {
                    "airflow-dags/${instance_name}" => {
                        'deploy_user' => $instance_params['service_user'],
                        # The service user (that runs airflow) will be managed
                        # by airflow::instance, but the deploy_airflow ssh key
                        # is only used for scap deployments.  scap::target should
                        # not manage the user, but it should manage the ssh key.
                        'manage_user' => false,
                        'manage_ssh_key' => true,
                        # key_name must match a keyholder::agent declared in profile::keyholder::server::agents,
                        # which also must match an ssh keypair added in puppet private repo
                        # in modules/secret/secrets/keyholder.
                        'key_name' => 'deploy_airflow',
                        'ensure' => $scap_target_ensure
                    },
                }
            }


            # Default WMF (analytics cluster, for now) specific instance params.
            $default_wmf_instance_params = {
                'airflow_home' => $airflow_home,
                'ferm_srange' => '$ANALYTICS_NETWORKS',
                'scap_targets' => $default_scap_targets,
                'airflow_config' => {
                    'core' => {
                        'dags_folder' => "/srv/deployment/airflow-dags/${instance_name}/${instance_name}/dags",
                        'security' => 'kerberos',
                        'executor' => 'LocalExecutor',

                        # NOTE: @db_user and @db_password should be provided via
                        # $airflow_instances_secrets as the $db_user and $db_password params.
                        # This ERb template string will be rendered in airflow::instance
                        # with those values.
                        'sql_alchemy_conn' => "mysql://<%= @db_user %>:<%= @db_password %>@${airflow_database_host_default}/airflow_${instance_name_normalized}?ssl_ca=/etc/ssl/certs/Puppet_Internal_CA.pem",

                        # The amount of parallelism as a setting to the executor. This defines
                        # the max number of task instances that should run simultaneously
                        # on this airflow installation.
                        # This value was 32 by default, but we have decided to increase it to
                        # backfill more quickly, and globally run more concurrent jobs. But, by doing
                        # so, we assume that most tasks are low intensive in resources.
                        # You can always set some restriction per dag with max_active_tasks, and per
                        # task with max_active_tis_per_dag. Example: a task using a significative
                        # amount of memory from the cluster should set its max_active_tis_per_dag to 1.
                        # This would be recommanded for intensive
                        # tasks for example.
                        'parallelism' => '64',

                        # The maximum number of task instances allowed to run concurrently in each DAG.
                        # To calculate the number of tasks that is running concurrently for a DAG, add
                        # up the number of running tasks for all DAG runs of the DAG.
                        # This value has been set lower than the default (16). An example scenario when
                        # this would be useful is when you want to stop a new dag with an early start
                        # date from stealing all the executor slots in a cluster.
                        # Currently, dag_concurrency = 2 * max_active_runs_per_dag
                        # This is configurable at the DAG level with max_active_tasks.
                        # TODO Rename me max_active_tasks_per_dag after Airflow is upgraded to 2.2.0.
                        'dag_concurrency' => '6',

                        # The maximum number of active DAG runs per DAG. The scheduler will not create
                        # more DAG runs if it reaches the limit. This is configurable at the DAG level
                        # with max_active_runs, which is defaulted as max_active_runs_per_dag.
                        # The goal is to avoid 1 dag to take all resources. But in the same time, to
                        # keep some parallelism:
                        #   - for faster backfill
                        #   - for faster backfill
                        'max_active_runs_per_dag' => '3',

                        # The number of retries each task is going to have by default. Can be
                        # overridden at dag or task level.
                        # It is increased from 0 to 5 to let a chance for closing minor problems like
                        # db connection problems.
                        # It could be modified per task with the `retries` parameter. For example, to
                        # avoid a very compute-intensive (large) task to retry.
                        'default_task_retries' => '5',
                    },

                },
                'connections' => {
                    'fs_local' => {
                        'conn_type' => 'fs',
                        'description' => 'Local filesystem on the Airflow Scheduler node',
                    },
                },
                'environment_extra' => {
                    # data-engineering/airflow-dags has custom airflow hooks that can use
                    # Skein to launch jobs in yarn. Skein will be default write runtime
                    # config files into ~/.skein.  A home dir might not exist for the
                    # user running airflow, so set SKEIN_CONFIG to write into AIRFLOW_HOME/.skein
                    # (/srv/airflow-$instance_name is default airflow home in airflow::instance)
                    'SKEIN_CONFIG' => "${airflow_home}/.skein",
                    # By putting $deployment_dir on python path, it lets dags .py files
                    # import python modules from there, e.g. import wmf_airflow_common
                    # or import $instance_name/conf/dag_config.py
                    'PYTHONPATH' => $deployment_dir,
                }
            }

            # Merge this instance's params with the smart wmf defaults we just constructed.
            $merged_instance_params = deep_merge($default_wmf_instance_params, $instance_params)

            # $instances_accumulator is just the reduce accumulator.
            # Merge it with the instance_name -> params we just created to
            # build up a new Hash of instances with smart defaults.
            deep_merge(
                $instances_accumulator,
                { $instance_name => $merged_instance_params },
            )
        },
    }

    # Finally, merge any airflow secrets into our airflow instances...
    $_airflow_instances = deep_merge($airflow_instances_with_defaults, $airflow_instances_secrets)

    # and declare the airflow::instances using our final Hash.
    create_resources('airflow::instance', $_airflow_instances)
}
