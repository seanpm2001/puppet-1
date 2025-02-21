# Class: profile::ceph::mon
#
# This profile configures Ceph monitor hosts with the mon and mgr daemons
class profile::ceph::mon(
    Array[Stdlib::Fqdn]  $openstack_controllers = lookup('profile::ceph::openstack_controllers'),
    Hash[String,Hash]    $mon_hosts        = lookup('profile::ceph::mon::hosts'),
    Hash[String,Hash]    $osd_hosts        = lookup('profile::ceph::osd::hosts'),
    Stdlib::IP::Address  $cluster_network  = lookup('profile::ceph::cluster_network'),
    Stdlib::IP::Address  $public_network   = lookup('profile::ceph::public_network'),
    Stdlib::Unixpath     $data_dir         = lookup('profile::ceph::data_dir'),
    String               $fsid             = lookup('profile::ceph::fsid'),
    String               $ceph_repository_component  = lookup('profile::ceph::ceph_repository_component'),
    Array[Stdlib::Fqdn]  $cinder_backup_nodes        = lookup('profile::ceph::cinder_backup_nodes'),
    Ceph::Auth::Conf     $ceph_auth_conf             = lookup('profile::ceph::auth::load_all::configuration'),
) {
    require 'profile::ceph::auth::load_all'

    include network::constants

    $client_networks = [
        $network::constants::all_network_subnets['production']['eqiad']['private']['labs-hosts1-b-eqiad']['ipv4'],
        $network::constants::all_network_subnets['production']['codfw']['private']['labs-hosts1-b-codfw']['ipv4'],
    ]

    $mon_addrs = $mon_hosts.map | $key, $value | { $value['public']['addr'] }
    $osd_addrs = $osd_hosts.map | $key, $value | { $value['public']['addr'] }

    $openstack_controller_ips = $openstack_controllers.map |$host| { ipresolve($host, 4) }
    $cinder_backup_nodes_ips  = $cinder_backup_nodes.map |$host| { ipresolve($host, 4) }
    $ferm_srange = join(concat($mon_addrs, $osd_addrs, $client_networks, $openstack_controller_ips, $cinder_backup_nodes_ips), ' ')
    ferm::service { 'ceph_mgr_v2':
        proto  => 'tcp',
        port   => 6800,
        srange => "(${ferm_srange})",
        before => Class['ceph::common'],
    }
    ferm::service { 'ceph_mgr_v1':
        proto  => 'tcp',
        port   => 6801,
        srange => "(${ferm_srange})",
        before => Class['ceph::common'],
    }
    ferm::service { 'ceph_mon_peers_v1':
        proto  => 'tcp',
        port   => 6789,
        srange => "(${ferm_srange})",
        before => Class['ceph::common'],
    }
    ferm::service { 'ceph_mon_peers_v2':
        proto  => 'tcp',
        port   => 3300,
        srange => "(${ferm_srange})",
        before => Class['ceph::common'],
    }

    class { 'ceph::common':
        home_dir                  => $data_dir,
        ceph_repository_component => $ceph_repository_component,
    }

    class { 'ceph::config':
        cluster_network     => $cluster_network,
        enable_libvirt_rbd  => false,
        enable_v2_messenger => true,
        fsid                => $fsid,
        mon_hosts           => $mon_hosts,
        osd_hosts           => $osd_hosts,
        public_network      => $public_network,
    }

    class { 'ceph::mon':
        data_dir   => $data_dir,
        fsid       => $fsid,
        admin_auth => $ceph_auth_conf['admin'],
        mon_auth   => $ceph_auth_conf["mon.${::hostname}"],
    }

    Class['ceph::mon'] -> Class['ceph::mgr']

    class { 'ceph::mgr':
        data_dir => $data_dir,
        mgr_auth => $ceph_auth_conf["mgr.${::hostname}"],
    }

    # This adds latency stats between from this mon to the rest of the ceph fleet
    class { 'prometheus::node_pinger':
        nodes_to_ping => $osd_hosts.keys() + $mon_hosts.keys(),
    }
}
