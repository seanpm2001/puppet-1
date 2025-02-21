class profile::openstack::eqiad1::puppetmaster::frontend(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::eqiad1::designate_hosts'),
    $puppetmasters = lookup('profile::openstack::eqiad1::puppetmaster::servers'),
    $puppetmaster_ca = lookup('profile::openstack::eqiad1::puppetmaster::ca'),
    $puppetmaster_webhostname = lookup('profile::openstack::eqiad1::puppetmaster::web_hostname'),
    $encapi_db_host = lookup('profile::openstack::eqiad1::puppetmaster::encapi::db_host'),
    $encapi_db_name = lookup('profile::openstack::eqiad1::puppetmaster::encapi::db_name'),
    $encapi_db_user = lookup('profile::openstack::eqiad1::puppetmaster::encapi::db_user'),
    $encapi_db_pass = lookup('profile::openstack::eqiad1::puppetmaster::encapi::db_pass'),
    $labweb_hosts = lookup('profile::openstack::eqiad1::labweb_hosts'),
    $cert_secret_path = lookup('profile::openstack::eqiad1::puppetmaster::cert_secret_path'),
    ) {
    class {'::profile::openstack::base::puppetmaster::frontend':
        openstack_controllers    => $openstack_controllers,
        designate_hosts          => $designate_hosts,
        puppetmasters            => $puppetmasters,
        puppetmaster_ca          => $puppetmaster_ca,
        puppetmaster_webhostname => $puppetmaster_webhostname,
        encapi_db_host           => $encapi_db_host,
        encapi_db_name           => $encapi_db_name,
        encapi_db_user           => $encapi_db_user,
        encapi_db_pass           => $encapi_db_pass,
        labweb_hosts             => $labweb_hosts,
        cert_secret_path         => $cert_secret_path,
    }
}
