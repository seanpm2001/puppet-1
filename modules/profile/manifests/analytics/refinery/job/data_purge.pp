# == Class profile::analytics::refinery::job::data_purge
#
# Installs systemd-timer jobs to drop old hive partitions,
# delete old data from HDFS and sanitize EventLogging data.
#
# [*deploy_jobs*]
#   Temporary flag to avoid deploying jobs on new hosts.
#   Default: true
#
class profile::analytics::refinery::job::data_purge (
    $public_druid_host = lookup('profile::analytics::refinery::job::data_purge::public_druid_host', { 'default_value' => undef }),
    $use_kerberos = lookup('profile::analytics::refinery::job::data_purge::use_kerberos', { 'default_value' => false }),
) {
    require ::profile::analytics::refinery

    $mediawiki_private_log_file      = "${profile::analytics::refinery::log_dir}/drop-mediawiki-private-partitions.log"
    $geoeditors_log_file             = "${profile::analytics::refinery::log_dir}/drop-geoeditor-daily-partitions.log"
    $query_clicks_log_file           = "${profile::analytics::refinery::log_dir}/drop-query-clicks.log"
    $public_druid_snapshots_log_file = "${profile::analytics::refinery::log_dir}/drop-druid-public-snapshots.log"
    $mediawiki_xmldumps_log_file     = "${profile::analytics::refinery::log_dir}/drop-mediawiki-xmldumps.log"
    $el_unsanitized_log_file         = "${profile::analytics::refinery::log_dir}/drop-el-unsanitized-events.log"
    $data_quality_hourly_log_file    = "${profile::analytics::refinery::log_dir}/drop-data-quality-hourly.log"

    # Shortcut to refinery path
    $refinery_path = $profile::analytics::refinery::path

    # Shortcut var to DRY up commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${refinery_path}/python"
    $systemd_env = {
        'PYTHONPATH' => "\${PYTHONPATH}:${refinery_path}/python",
    }

    # Send an email to analytics in case of failure
    $mail_to = 'analytics-alerts@wikimedia.org'

    # Keep this many days of raw webrequest data.
    $raw_retention_days = 31
    kerberos::systemd_timer { 'refinery-drop-webrequest-raw-partitions':
        description  => 'Drop Webrequest raw data imported on HDFS following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-webrequest-partitions -d ${raw_retention_days} -D wmf_raw -l /wmf/data/raw/webrequest -w raw",
        interval     => '*-*-* 00/4:15:00',
        environment  => $systemd_env,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }

    # Keep this many days of refined webrequest data.
    $refined_retention_days = 90
    kerberos::systemd_timer { 'refinery-drop-webrequest-refined-partitions':
        description  => 'Drop Webrequest refined data imported on HDFS following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-webrequest-partitions -d ${refined_retention_days} -D wmf -l /wmf/data/wmf/webrequest -w refined",
        interval     => '*-*-* 00/4:45:00',
        environment  => $systemd_env,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }

    # Keep this many days of eventlogging data.
    $eventlogging_retention_days = 90
    kerberos::systemd_timer { 'refinery-drop-eventlogging-partitions':
        description  => 'Drop Eventlogging data imported on HDFS following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-eventlogging-partitions -d ${eventlogging_retention_days} -l /wmf/data/raw/eventlogging",
        interval     => '*-*-* 00/4:15:00',
        environment  => $systemd_env,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }

    kerberos::systemd_timer { 'refinery-drop-eventlogging-client-side-partitions':
        description  => 'Drop Eventlogging Client Side data imported on HDFS following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-eventlogging-partitions -d ${eventlogging_retention_days} -l /wmf/data/raw/eventlogging_client_side",
        interval     => '*-*-* 00/4:30:00',
        environment  => $systemd_env,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }

    # keep this many days of mediawiki application logs
    $mediawiki_log_retention_days = 90
    kerberos::systemd_timer { 'refinery-drop-apiaction-partitions':
        description  => 'Drop API action data imported on HDFS following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-older-than --database='wmf_raw' --tables='apiaction' --base-path='/wmf/data/raw/mediawiki/mediawiki_ApiAction' --path-format='hourly/(?P<year>[0-9]+)(/(?P<month>[0-9]+)(/(?P<day>[0-9]+)(/(?P<hour>[0-9]+))?)?)?' --older-than='${mediawiki_log_retention_days}' --execute='7b23bc5ba9222501c96c6a138fc7a130'",
        interval     => '*-*-* 00/4:15:00',
        environment  => $systemd_env,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
        # TODO: remove after 2019-09-22
    }

    kerberos::systemd_timer { 'refinery-drop-cirrussearchrequestset-partitions':
        description  => 'Drop CirrusSearch request data imported on HDFS following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-older-than --database='wmf_raw' --tables='cirrussearchrequestset' --base-path='/wmf/data/raw/mediawiki/mediawiki_CirrusSearchRequestSet' --path-format='hourly/(?P<year>[0-9]+)(/(?P<month>[0-9]+)(/(?P<day>[0-9]+)(/(?P<hour>[0-9]+))?)?)?' --older-than='${mediawiki_log_retention_days}' --execute='81b857ad25536ccfd96f574c0b8f20fd'",
        interval     => '*-*-* 00/4:25:00',
        environment  => $systemd_env,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
        # TODO: remove after 2019-09-22
    }

    # keep this many days of druid webrequest sampled
    # Currently being tested as systemd timer, see below
    $druid_webrequest_sampled_retention_days = 60
    kerberos::systemd_timer { 'refinery-drop-webrequest-sampled-druid':
        description  => 'Drop Druid Webrequest sampled data from deep storage following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-druid-deep-storage-data -d ${druid_webrequest_sampled_retention_days} webrequest_sampled_128",
        interval     => '*-*-* 05:15:00',
        environment  => $systemd_env,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }


    # keep this many public druid mediawiki history refined snapshots
    # runs once a month
    if $public_druid_host {
        $druid_public_keep_snapshots = 4
        $mediawiki_history_reduced_basename = 'mediawiki_history_reduced'
        kerberos::systemd_timer { 'refinery-druid-drop-public-snapshots':
            description  => 'Drop Druid Public snapshots from deep storage following data retention policies.',
            command      => "${refinery_path}/bin/refinery-drop-druid-snapshots -d ${mediawiki_history_reduced_basename} -t ${public_druid_host} -s ${druid_public_keep_snapshots} -f ${public_druid_snapshots_log_file}",
            environment  => $systemd_env,
            interval     => 'Mon,Tue,Wed,Thu,Fri *-*-15 09:00:00',
            user         => 'analytics',
            use_kerberos => $use_kerberos,
        }
    }

    # keep this many mediawiki history snapshots, 6 minimum
    # runs once a month
    $keep_snapshots = 6
    kerberos::systemd_timer { 'mediawiki-history-drop-snapshot':
        description  => 'Drop snapshots from multiple raw and refined mediawiki datasets, configured in the refinery-drop script.',
        command      => "${refinery_path}/bin/refinery-drop-mediawiki-snapshots -s ${keep_snapshots}",
        environment  => $systemd_env,
        interval     => '*-*-15 06:15:00',
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }

    # keep this many days of banner activity success files
    # runs once a day
    $banner_activity_retention_days = 90
    kerberos::systemd_timer { 'refinery-drop-banner-activity':
        description  => 'Clean old Banner Activity _SUCCESS flags from HDFS.',
        command      => "${refinery_path}/bin/refinery-drop-banner-activity-partitions -d ${banner_activity_retention_days} -l /wmf/data/wmf/banner_activity",
        environment  => $systemd_env,
        interval     => '*-*-* 02:00:00',
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }

    # Create, rotate and delete EventLogging salts (for hashing).
    # Local directory for salt files:
    $refinery_config_dir = $::profile::analytics::refinery::config_dir
    file { ["${refinery_config_dir}/salts", "${refinery_config_dir}/salts/eventlogging_sanitization"]:
        ensure => 'directory',
        owner  => 'analytics',
    }

    file { '/usr/local/bin/refinery-eventlogging-saltrotate':
        content => template('profile/analytics/refinery/job/refinery-eventlogging-saltrotate.erb'),
        mode    => '0550',
        owner   => 'analytics',
        group   => 'analytics',
    }

    # Timer runs at midnight (salt rotation time):
    kerberos::systemd_timer { 'refinery-eventlogging-saltrotate':
        description  => 'Create, rotate and delete cryptographic salts for EventLogging sanitization.',
        command      => '/usr/local/bin/refinery-eventlogging-saltrotate',
        environment  => $systemd_env,
        interval     => '*-*-* 00:00:00',
        user         => 'analytics',
        use_kerberos => $use_kerberos,
        require      => File['/usr/local/bin/refinery-eventlogging-saltrotate']
    }

    # EventLogging sanitization. Runs in two steps.
    # Common parameters for both jobs:
    $eventlogging_sanitization_job_config = {
        'input_path'          => '/wmf/data/event',
        'database'            => 'event_sanitized',
        'output_path'         => '/wmf/data/event_sanitized',
        'whitelist_path'      => '/wmf/refinery/current/static_data/eventlogging/whitelist.yaml',
        'salts_path'          => '/user/hdfs/salts/eventlogging_sanitization',
        'parallelism'         => '16',
        'should_email_report' => true,
        'to_emails'           => 'analytics-alerts@wikimedia.org',
    }
    # Execute 1st sanitization pass, right after data collection. Runs once per hour.
    # Job starts a couple minutes after the hour, to leave time for the salt files to be updated.
    profile::analytics::refinery::job::refine_job { 'sanitize_eventlogging_analytics_immediate':
        job_class           => 'org.wikimedia.analytics.refinery.job.refine.EventLoggingSanitization',
        monitor_class       => 'org.wikimedia.analytics.refinery.job.refine.EventLoggingSanitizationMonitor',
        job_config          => $eventlogging_sanitization_job_config,
        spark_driver_memory => '16G',
        spark_max_executors => '128',
        spark_extra_opts    => '--conf spark.ui.retainedStage=20 --conf spark.ui.retainedTasks=1000 --conf spark.ui.retainedJobs=100',
        interval            => '*-*-* *:02:00',
    }
    # Execute 2nd sanitization pass, after 45 days of collection.
    # Runs once per day at a less busy time.
    profile::analytics::refinery::job::refine_job { 'sanitize_eventlogging_analytics_delayed':
        job_class           => 'org.wikimedia.analytics.refinery.job.refine.EventLoggingSanitization',
        monitor_class       => 'org.wikimedia.analytics.refinery.job.refine.EventLoggingSanitizationMonitor',
        job_config          => $eventlogging_sanitization_job_config.merge({
            'since' => 1104,
            'until' => 1080,
        }),
        spark_driver_memory => '16G',
        spark_max_executors => '128',
        spark_extra_opts    => '--conf spark.ui.retainedStage=20 --conf spark.ui.retainedTasks=1000 --conf spark.ui.retainedJobs=100',
        interval            => '*-*-* 06:00:00',
    }

    # Drop unsanitized EventLogging data from the event database after retention period.
    # Runs once a day.
    kerberos::systemd_timer { 'drop-el-unsanitized-events':
        description  => 'Drop unsanitized EventLogging data from the event database after retention period.',
        command      => "${refinery_path}/bin/refinery-drop-older-than --database='event' --tables='^(?!wmdebanner)[A-Za-z0-9]+$$' --base-path='/wmf/data/event' --path-format='(?!WMDEBanner)[A-Za-z0-9]+/year=(?P<year>[0-9]+)(/month=(?P<month>[0-9]+)(/day=(?P<day>[0-9]+)(/hour=(?P<hour>[0-9]+))?)?)?' --older-than='90' --execute='05c2f816807c528cf138bd0be2bdaba4' --log-file='${el_unsanitized_log_file}'",
        interval     => '*-*-* 00:00:00',
        environment  => $systemd_env,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }

    # drop data older than 2 months from cu_changes table, which is sqooped in
    # runs once a month
    $geoeditors_private_retention_days = 80
    kerberos::systemd_timer { 'mediawiki-raw-cu-changes-drop-month':
        description  => 'Drop raw Mediawiki cu_changes from Hive/HDFS following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-hive-partitions -d ${geoeditors_private_retention_days} -D wmf_raw -t mediawiki_private_cu_changes -l 1 -f ${mediawiki_private_log_file}",
        environment  => $systemd_env,
        interval     => '*-*-16 05:00:00',
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }

    # drop data older than 2 months from geoeditors_daily table
    # runs once a month
    # Temporary stopped to prevent data to be dropped.
    kerberos::systemd_timer { 'mediawiki-geoeditors-drop-month':
        ensure       => absent,
        description  => 'Drop Geo-editors data from Hive/HDFS following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-hive-partitions -d ${geoeditors_private_retention_days} -D wmf -t geoeditors_daily -l 1 -f ${geoeditors_log_file}",
        environment  => $systemd_env,
        interval     => '*-*-16 06:00:00',
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }

    # drop monthly xmldumps data (pages_meta_history) after 80 days (last day of month as reference)
    # runs once a month
    $xmldumps_retention_days = 80
    file { '/usr/local/bin/refinery-drop-mediawiki-xmldumps-pages_meta_history':
        content => template('profile/analytics/refinery/job/refinery-drop-mediawiki-xmldumps-pages_meta_history.sh.erb'),
        mode    => '0550',
        owner   => 'analytics',

    }
    kerberos::systemd_timer { 'mediawiki-drop-xmldumps-pages_meta_history':
        description  => 'Drop xmldumps pages_meta_history data from HDFS after 80 days.',
        command      => '/usr/local/bin/refinery-drop-mediawiki-xmldumps-pages_meta_history',
        interval     => '*-*-20 06:00:00',
        user         => 'analytics',
        use_kerberos => $use_kerberos,
        require      => File['/usr/local/bin/refinery-drop-mediawiki-xmldumps-pages_meta_history'],
    }

    # keep this many days of search query click files
    # runs once a day
    $query_clicks_retention_days = 90
    kerberos::systemd_timer { 'refinery-drop-query-clicks':
        ensure                    => absent,
        description               => 'Drop cirrus click logs from Hive/HDFS following data retention policies.',
        command                   => "${refinery_path}/bin/refinery-drop-hive-partitions -d ${query_clicks_retention_days} -D discovery -t query_clicks_hourly,query_clicks_daily -f ${query_clicks_log_file}",
        monitoring_contact_groups => 'team-discovery',
        environment               => $systemd_env,
        interval                  => '*-*-* 03:30:00',
        user                      => 'hdfs',
        use_kerberos              => $use_kerberos,
    }

    # Drop old records in data quality hourly table. Runs once a day.
    kerberos::systemd_timer { 'drop-data-quality-hourly':
        description  => 'Drop old records in data quality hourly table.',
        command      => "${refinery_path}/bin/refinery-drop-older-than --database='wmf' --tables='data_quality_hourly' --base-path='/wmf/data/wmf/data_quality/hourly' --path-format='.+/.+/year=(?P<year>[0-9]+)(/month=(?P<month>[0-9]+)(/day=(?P<day>[0-9]+)(/hour=(?P<hour>[0-9]+))?)?)?' --older-than='90' --skip-trash --execute='e96222d1885ff1b86d61a455b151c094' --log-file='${data_quality_hourly_log_file}'",
        interval     => '*-*-* 00:00:00',
        environment  => $systemd_env,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }
}
