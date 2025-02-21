class profile::openstack::base::puppetmaster::frontend(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    $puppetmasters = lookup('profile::openstack::base::puppetmaster::servers'),
    $puppetmaster_ca = lookup('profile::openstack::base::puppetmaster::ca'),
    $puppetmaster_webhostname = lookup('profile::openstack::base::puppetmaster::web_hostname'),
    $encapi_db_host = lookup('profile::openstack::base::puppetmaster::encapi::db_host'),
    $encapi_db_name = lookup('profile::openstack::base::puppetmaster::encapi::db_name'),
    $encapi_db_user = lookup('profile::openstack::base::puppetmaster::encapi::db_user'),
    $encapi_db_pass = lookup('profile::openstack::base::puppetmaster::encapi::db_pass'),
    $labweb_hosts = lookup('profile::openstack::base::labweb_hosts'),
    $cert_secret_path = lookup('profile::openstack::base::puppetmaster::cert_secret_path'),
    ) {

    include ::network::constants
    include ::profile::backup::host
    include ::profile::conftool::client
    include ::profile::conftool::master

    # validatelabsfqdn will look up an instance certname in nova
    #  and make sure it's for an actual instance before signing
    file { '/usr/local/sbin/validatelabsfqdn.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/validatelabsfqdn.py',
    }

    class {'profile::openstack::base::puppetmaster::common':
        openstack_controllers => $openstack_controllers,
        designate_hosts       => $designate_hosts,
        encapi_db_host        => $encapi_db_host,
        encapi_db_name        => $encapi_db_name,
        encapi_db_user        => $encapi_db_user,
        encapi_db_pass        => $encapi_db_pass,
        labweb_hosts          => $labweb_hosts,
    }

    $designate_ips = $designate_hosts.map |$host| { ipresolve($host, 4) }
    $designate_ips_v6 = $designate_hosts.map |$host| { ipresolve($host, 6) }
    $openstack_controller_ips = $openstack_controllers.map |$host| { ipresolve($host, 4) }
    $openstack_controller_ips_v6 = $openstack_controllers.map |$host| { ipresolve($host, 6) }

    if ! defined(Class['puppetmaster::certmanager']) {
        class { 'puppetmaster::certmanager':
            remote_cert_cleaners => flatten([
                $designate_ips,
                $designate_ips_v6,
                $openstack_controller_ips,
                $openstack_controller_ips_v6,
            ])
        }
    }

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => '/usr/local/sbin/validatelabsfqdn.py',
    }

    class { '::profile::puppetmaster::frontend':
        ca_server        => $puppetmaster_ca,
        web_hostname     => $puppetmaster_webhostname,
        config           => $config,
        secure_private   => false,
        servers          => $puppetmasters,
        extra_auth_rules => template('profile/openstack/base/puppetmaster/extra_auth_rules.conf.erb'),
    }

    # The above profile will make a standard vhost for $web_hostname.
    #  We also want to support clients using simple 'puppet'
    #   as the master name.  There's some DNS magic elsewhere
    #   so that VMs can refer to 'puppet' and get a deployment-appropriate
    #   puppetmaster.
    ::puppetmaster::web_frontend { 'puppet':
        master           => $puppetmaster_ca,
        workers          => $puppetmasters[$::fqdn],
        bind_address     => $::puppetmaster::bind_address,
        priority         => 40,
        cert_secret_path => $cert_secret_path,
    }

    $labs_networks = join($network::constants::labs_networks, ' ')
    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    $labweb_ips_v6 = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>), AAAA)")
    ferm::rule{'puppetmaster_balancer':
        ensure => 'present',
        rule   => "saddr (${labs_networks}
                          ${labweb_ips} ${labweb_ips_v6})
                          proto tcp dport 8140 ACCEPT;",
    }

    ferm::rule{'puppetcertcleaning':
        ensure => 'present',
        rule   => "saddr (@resolve((${join($designate_hosts,' ')}))
                          @resolve((${join($designate_hosts,' ')}), AAAA))
                        proto tcp dport 22 ACCEPT;",
    }

    file {'/etc/labspuppet':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    openstack::db::project_grants { 'labspuppet':
        access_hosts => flatten([$openstack_controllers, keys($puppetmasters)]),
        db_name      => $encapi_db_name,
        db_user      => $encapi_db_user,
        db_pass      => $encapi_db_pass,
    }
}
