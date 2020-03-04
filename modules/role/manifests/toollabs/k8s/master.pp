# filtertags: labs-project-tools
class role::toollabs::k8s::master(
    $use_puppet_certs = false,
) {
    include ::toollabs::base
    include ::toollabs::infrastructure
    include ::profile::base::firewall
    include ::profile::toolforge::prometheus_fixup

    $master_host = hiera('k8s::master_host', $::fqdn)
    $etcd_url = prefix(suffix(hiera('k8s::etcd_hosts'), ':2379'), 'https://')

    if $use_puppet_certs {
        $ssl_cert_path = '/etc/kubernetes/ssl/cert.pem'
        $ssl_key_path = '/etc/kubernetes/ssl/server.key'

    } else {
        $ssl_certificate_name = 'toolforge'
        acme_chief::cert { $ssl_certificate_name:
            key_group  => 'kube',
            puppet_svc => 'kube-apiserver',
        }
        $ssl_cert_path = "/etc/acmecerts/${ssl_certificate_name}/live/rsa-2048.chained.crt"
        $ssl_key_path = "/etc/acmecerts/${ssl_certificate_name}/live/rsa-2048.key"
    }

    # Set our host allowed paths
    $host_automounts = [
        '/etc/ldap.conf',
        '/etc/ldap.yaml',
        '/etc/novaobserver.yaml',
        '/var/run/nslcd/socket',
    ]
    $host_path_prefixes_allowed = [
        '/data/project/',
        '/data/scratch/',
        '/etc/wmcs-project',
        '/mnt/nfs',
        '/public/dumps/',
    ]
    $host_automounts_string = join($host_automounts, ',')
    $host_path_prefixes_allowed_string = join($host_path_prefixes_allowed, ',')


    $docker_registry = hiera('docker::registry')

    class { '::profile::kubernetes::master':
        etcd_urls                => $etcd_url,
        service_cluster_ip_range => '192.168.0.0/17',
        apiserver_count          => 1,
        accessible_to            => 'all',
        expose_puppet_certs      => $use_puppet_certs,
        ssl_cert_path            => $ssl_cert_path,
        ssl_key_path             => $ssl_key_path,
        authz_mode               => 'abac',
        admission_controllers    => {
            'NamespaceLifecycle' => '',
            'ResourceQuota'      => '',
            'LimitRanger'        => '',
            'UidEnforcer'        => '',
            'RegistryEnforcer'   => "--enforced-docker-registry=${docker_registry}",
            'HostAutomounter'    => "--host-automounts=${host_automounts_string}",
            'HostPathEnforcer'   => "--host-paths-allowed=${host_automounts_string} --host-path-prefixes-allowed=${host_path_prefixes_allowed_string}",
        },
    }
}
