# = Class: profile::toolforge::checker
#
# Exposes a set of web endpoints that perform an explicit check for
# a particular set of internal services, and response OK (200) or not
# (anything else).
#
# Used for external monitoring / collection of availability metrics
#
class profile::toolforge::checker {
    include profile::toolforge::grid::base
    include profile::toolforge::grid::submit_host
    include profile::toolforge::k8s::client

    # Packages needed by the uwsgi services
    ensure_packages([
        'python3-flask',
        'python3-ldap3',
        'python3-psycopg2',
        'python3-pymysql',
        'python3-redis',
        'python3-requests',
        'python3-yaml',
    ])

    # For etcd checks, we need the puppet certs to act as client
    $puppet_cert_pub  = "/var/lib/puppet/ssl/certs/${::fqdn}.pem"
    $puppet_cert_priv = "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem"
    $puppet_cert_ca   = '/var/lib/puppet/ssl/certs/ca.pem'
    $install_dir = '/var/lib/toolschecker'
    $wsgi_file = "${install_dir}/toolschecker.py"
    $etcd_cert_pub    = "${install_dir}/etcd/${::fqdn}.pem"
    $etcd_cert_priv   = "${install_dir}/etcd/${::fqdn}.priv"
    $etcd_cert_ca     = "${install_dir}/etcd/ca.pem"

    $checks = {
        'cron'                            => '/cron',
        'db_toolsdb'                      => '/db/toolsdb',
        'db_wikilabelsrw'                 => '/db/wikilabelsrw',
        'dns_private'                     => '/dns/private',
        'etcd_kubernetes'                 => '/etcd/k8s',
        'grid_continuous_stretch'         => '/grid/continuous/stretch',
        'grid_start_stretch'              => '/grid/start/stretch',
        'kubernetes_nodes_ready'          => '/k8s/nodes/ready',
        'ldap'                            => '/ldap',
        'nfs_dumps'                       => '/nfs/dumps',
        'nfs_home'                        => '/nfs/home',
        'nfs_secondary_cluster_showmount' => '/nfs/secondary_cluster_showmount',
        'redis'                           => '/redis',
        'self'                            => '/self',
        'webservice_gridengine'           => '/webservice/gridengine',
        'webservice_kubernetes'           => '/webservice/kubernetes',
    }

    $check_names = keys($checks).map |$name| { "toolschecker_${name}" }

    $checks.each |String $name, String $path| {
        # Provision a separate uwsgi service for each check endpoint.
        # This is done so that we can use 'harakiri mode' which will terminate
        # the entire uwsgi process if a request takes longer than the
        # configured maximum response time.
        uwsgi::app { "toolschecker_${name}":
            settings => {
                uwsgi => {
                    need-plugins     => 'python3',
                    master           => true,
                    chdir            => $install_dir,
                    wsgi-file        => $wsgi_file,
                    callable         => 'app',
                    uwsgi-socket     => "/tmp/uwsgi-${name}.sock",
                    chmod-socket     => 664,
                    processes        => 1,
                    harakiri         => 300,
                    harakiri-verbose => true,
                    die-on-term      => true,
                    env              => [
                        'LANG=C.UTF-8',
                        'PYTHONENCODING=utf-8',
                    ],
                },
            },
            require  => File[$wsgi_file],
        }
    }

    # Reverse proxy in front the collection of uwsgi containers
    nginx::site { 'toolschecker-nginx':
        content => template('profile/toolforge/checker/nginx.erb'),
        require => Uwsgi::App[$check_names],
    }

    file { $install_dir:
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
        before => File[$wsgi_file],
    }

    file { "${install_dir}/etcd":
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0500',
    }

    file { $etcd_cert_pub:
        ensure => present,
        source => "file://${puppet_cert_pub}",
        owner  => 'www-data',
        group  => 'www-data',
    }

    file { $etcd_cert_priv:
        ensure    => present,
        source    => "file://${puppet_cert_priv}",
        owner     => 'www-data',
        group     => 'www-data',
        mode      => '0600',
        show_diff => false,
    }

    file { $etcd_cert_ca:
        ensure => present,
        source => "file://${puppet_cert_ca}",
        owner  => 'www-data',
        group  => 'www-data',
    }

    file { $wsgi_file:
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/toolforge/checker/toolschecker.py',
        notify => Uwsgi::App[$check_names],
    }

    # TODO(T279078): move to hiera?
    $config = {
        'CRON_PATH'     => '/data/project/toolschecker/crontest.txt',
        'DEBUG'         => true,
        'DUMPS_PATH'    => '/public/dumps/public/enwiki',
        'ETCD_K8S' => [
            "tools-k8s-etcd-13.${::labsproject}.eqiad1.wikimedia.cloud",
            "tools-k8s-etcd-14.${::labsproject}.eqiad1.wikimedia.cloud",
            "tools-k8s-etcd-15.${::labsproject}.eqiad1.wikimedia.cloud",
        ],
        'ETCD_AUTH' => {
            'KEY'  => $etcd_cert_priv,
            'CERT' => $etcd_cert_pub,
            'CA'   => $etcd_cert_ca,
        },
        'NFS_HOME_PATH' => '/data/project/toolschecker/nfs-test/',
        'PROJECT'       => $::labsproject,
        'TOOLS_DOMAIN'  => 'tools.wmflabs.org',
    }
    file { "${install_dir}/config.yaml":
        ensure  => 'present',
        owner   => 'root',
        group   => 'www-data',
        mode    => '0440',
        content => to_yaml($config),
        notify  => Uwsgi::App[$check_names],
    }

    file { "${install_dir}/replica.my.cnf":
        ensure => present,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0400',
        source => '/data/project/toolschecker/replica.my.cnf',
        before => File[$wsgi_file],
    }

    file { "${install_dir}/postgres.my.cnf":
        ensure => present,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0400',
        source => '/data/project/toolschecker/postgres.my.cnf',
        before => File[$wsgi_file],
    }

    file { "${install_dir}/kubernetes.json":
        ensure => absent,
    }
    file { "${install_dir}/kube-config.yaml":
        ensure => present,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0400',
        source => '/data/project/toolschecker/.kube/config',
        before => File[$wsgi_file],
    }
    file { "${install_dir}/client.crt":
        ensure => present,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0400',
        source => '/data/project/toolschecker/.toolskube/client.crt',
        before => File[$wsgi_file],
    }
    file { "${install_dir}/client.key":
        ensure => present,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0400',
        source => '/data/project/toolschecker/.toolskube/client.key',
        before => File[$wsgi_file],
    }

    # Allow the www-data user to perform actions as related tools.
    sudo::user { 'www-data':
        privileges => [
            "ALL=(${::labsproject}.toolschecker) NOPASSWD: ALL",
            "ALL=(${::labsproject}.toolschecker-k8s-ws) NOPASSWD: ALL",
            "ALL=(${::labsproject}.toolschecker-ge-ws) NOPASSWD: ALL",
        ],
    }

    # Configure the $HOME of the toolschecker tool. Assumes that the basic
    # Toolforge tool user and its homedir has already been provisioned by
    # other means.

    # Directory to write NFS read/write check files to
    file { '/data/project/toolschecker/nfs-test':
        ensure => directory,
        owner  => 'www-data',
        group  => "${::labsproject}.toolschecker",
        mode   => '0755',
        before => File[$wsgi_file],
    }

    # Configure the $HOME of the toolschecker-ge-ws tool. Assumes that the
    # basic Toolforge tool user and its homedir has already been provisioned
    # by other means.

    # "Hello world" php app
    file { '/data/project/toolschecker-ge-ws/public_html/index.php':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/checker/service.php',
        before => File[$wsgi_file],
    }

    # Configure the $HOME of the toolschecker-k8s-ws tool. Assumes that the
    # basic Toolforge tool user and its homedir has already been provisioned
    # by other means.

    # "Hello world" php app
    file { '/data/project/toolschecker-k8s-ws/public_html/index.php':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/checker/service.php',
        before => File[$wsgi_file],
    }

    file { '/usr/local/sbin/toolscheckerctl':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/profile/toolforge/checker/toolscheckerctl.py',
    }
}
# vim:sw=4:ts=4:sts=4:et:
