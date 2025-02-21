class profile::openstack::base::puppetmaster::common(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::puppetmaster::common::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::puppetmaster::common::designate_hosts'),
    $encapi_db_host = lookup('profile::openstack::base::puppetmaster::common::encapi_db_host'),
    $encapi_db_name = lookup('profile::openstack::base::puppetmaster::common::encapi_db_name'),
    $encapi_db_user = lookup('profile::openstack::base::puppetmaster::common::encapi_db_user'),
    $encapi_db_pass = lookup('profile::openstack::base::puppetmaster::common::encapi_db_pass'),
    $labweb_hosts = lookup('profile::openstack::base::labweb_hosts'),
) {
    include profile::openstack::base::puppetmaster::enc_client

    $labs_networks = join($network::constants::labs_networks, ' ')
    class { '::openstack::puppet::master::encapi':
        mysql_host            => $encapi_db_host,
        mysql_db              => $encapi_db_name,
        mysql_username        => $encapi_db_user,
        mysql_password        => $encapi_db_pass,
        labweb_hosts          => $labweb_hosts,
        openstack_controllers => $openstack_controllers,
        designate_hosts       => $designate_hosts,
    }

    # Update labs/private repo.
    class { 'puppetmaster::gitsync':
        run_every_minutes => 1,
    }

    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    $labweb_aaaa = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>), AAAA)")

    ferm::rule{'puppetmaster':
        ensure => 'present',
        rule   => "saddr (${labs_networks}
                          @resolve((${join($labweb_hosts,' ')}))
                          @resolve((${join($labweb_hosts,' ')}), AAAA))
                          proto tcp dport 8141 ACCEPT;",
    }

    ferm::rule{'puppetbackend':
        ensure => 'present',
        rule   => "saddr (@resolve((${join($designate_hosts,' ')}))
                          @resolve((${join($designate_hosts,' ')}), AAAA)
                          @resolve((${join($labweb_hosts,' ')}))
                          @resolve((${join($labweb_hosts,' ')}), AAAA)
                          @resolve((${join($openstack_controllers,' ')}))
                          @resolve((${join($openstack_controllers,' ')}), AAAA))
                          proto tcp dport 8101 ACCEPT;",
    }

    ferm::rule{'puppetbackendgetter':
        ensure => 'present',
        rule   => "saddr (${labs_networks}
                          @resolve((${join($labweb_hosts,' ')}))
                          @resolve((${join($labweb_hosts,' ')}), AAAA))
                          proto tcp dport 8100 ACCEPT;",
    }
}
