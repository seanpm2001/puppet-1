# @summary profile to configure the idp
# @param ldap_config a hash containing the ldap configeration
class profile::idp(
    Array[Stdlib::Host]               $prometheus_nodes          = lookup('prometheus_nodes'),
    Hash                              $ldap_config               = lookup('ldap', Hash, hash, {}),
    Apereo_cas::LogLevel              $log_level                 = lookup('profile::idp::log_level'),
    Enum['ldaps', 'ldap']             $ldap_schema               = lookup('profile::idp::ldap_schema'),
    Boolean                           $enable_ldap               = lookup('profile::idp::enable_ldap'),
    Boolean                           $ldap_start_tls            = lookup('profile::idp::ldap_start_tls'),
    String                            $keystore_password         = lookup('profile::idp::keystore_password'),
    String                            $key_password              = lookup('profile::idp::key_password'),
    String                            $tgc_signing_key           = lookup('profile::idp::tgc_signing_key'),
    String                            $tgc_encryption_key        = lookup('profile::idp::tgc_encryption_key'),
    Wmflib::HTTP::SameSite            $tgc_cookie_same_site      = lookup('profile::idp::tgc_cookie_same_site'),
    Boolean                           $tgc_cookie_pin_to_session = lookup('profile::idp::tgc_cookie_pin_to_session'),
    String                            $webflow_signing_key       = lookup('profile::idp::webflow_signing_key'),
    String                            $webflow_encryption_key    = lookup('profile::idp::webflow_encryption_key'),
    String                            $u2f_signing_key           = lookup('profile::idp::u2f_signing_key'),
    String                            $u2f_encryption_key        = lookup('profile::idp::u2f_encryption_key'),
    Integer                           $max_session_length        = lookup('profile::idp::max_session_length'),
    Hash[String,Hash]                 $services                  = lookup('profile::idp::services'),
    Array[String[1]]                  $ldap_attribute_list       = lookup('profile::idp::ldap_attributes'),
    Array[String]                     $actuators                 = lookup('profile::idp::actuators'),
    Stdlib::HTTPSUrl                  $server_name               = lookup('profile::idp::server_name'),
    Array[Stdlib::Fqdn]               $idp_nodes                 = lookup('profile::idp::idp_nodes'),
    Boolean                           $is_staging_host           = lookup('profile::idp::is_staging_host'),
    Boolean                           $memcached_enable          = lookup('profile::idp::memcached_enable'),
    Stdlib::Port                      $memcached_port            = lookup('profile::idp::memcached_port'),
    Apereo_cas::Memcached::Transcoder $memcached_transcoder      = lookup('profile::idp::memcached_transcoder'),
    Boolean                           $enable_u2f                = lookup('profile::idp::enable_u2f'),
    Boolean                           $u2f_jpa_enable            = lookup('profile::idp::u2f_jpa_enable'),
    String                            $u2f_jpa_username          = lookup('profile::idp::u2f_jpa_username'),
    String                            $u2f_jpa_password          = lookup('profile::idp::u2f_jpa_password'),
    Stdlib::Host                      $u2f_jpa_server            = lookup('profile::idp::u2f_jpa_server'),
    String                            $u2f_jpa_db                = lookup('profile::idp::u2f_jpa_db'),
    Boolean                           $enable_cors               = lookup('profile::idp::enable_cors'),
    Boolean                           $cors_allow_credentials    = lookup('profile::idp::cors_allow_credentials'),
    Array[Stdlib::HTTPSUrl]           $cors_allowed_origins      = lookup('profile::idp::cors_allowed_origins'),
    Array[String]                     $cors_allowed_headers      = lookup('profile::idp::cors_allowed_headers'),
    Array[Wmflib::HTTP::Method]       $cors_allowed_methods      = lookup('profile::idp::cors_allowed_methods'),
    Optional[Integer]                 $u2f_token_expiry_days     = lookup('profile::idp::u2f_token_expiry_days'),
    Boolean                           $envoy_termination         = lookup('profile::idp::envoy_termination'),
    Array[Apereo_cas::Delegate]       $delegated_authenticators  = lookup('profile::idp::delegated_authenticators'),
){

    ensure_packages(['python3-pymysql'])
    include passwords::ldap::production
    class{ 'sslcert::dhparam': }
    if $envoy_termination {
      include profile::tlsproxy::envoy
      $ferm_port = 443
    } else {
      # In cloud we use the shared wmfcloud proxy for tls termination
      $ferm_port = 8080
    }

    class {'tomcat': }

    $jmx_port = 9200
    $jmx_config = '/etc/prometheus/cas_jmx_exporter.yaml'
    $jmx_jar = '/usr/share/java/prometheus/jmx_prometheus_javaagent.jar'
    $java_opts = "-javaagent:${jmx_jar}=${facts['networking']['ip']}:${jmx_port}:${jmx_config}"
    $groovy_source = 'puppet:///modules/profile/idp/global_principal_attribute_predicate.groovy'
    $log_dir = '/var/log/cas'

    $cas_daemon_user = 'tomcat'

    if $is_staging_host {
        apt::repository{ 'component-idp-test':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/idp-test',
        }
    }

    $ldap_port = $ldap_schema ? {
      'ldap'  => 389,
      default => 636,
    }
    $ldap_uris = ["${ldap_schema}://${ldap_config[ro-server]}:${ldap_port}",
                  "${ldap_schema}://${ldap_config[ro-server-fallback]}:${ldap_port}"]
    class { 'apereo_cas':
        server_name               => $server_name,
        server_prefix             => '/',
        server_port               => 8080,
        server_enable_ssl         => false,
        tomcat_proxy              => true,
        groovy_source             => $groovy_source,
        prometheus_nodes          => $prometheus_nodes,
        keystore_content          => secret('casserver/thekeystore'),
        keystore_password         => $keystore_password,
        key_password              => $key_password,
        tgc_signing_key           => $tgc_signing_key,
        tgc_encryption_key        => $tgc_encryption_key,
        tgc_cookie_same_site      => $tgc_cookie_same_site,
        tgc_cookie_pin_to_session => $tgc_cookie_pin_to_session,
        webflow_signing_key       => $webflow_signing_key,
        webflow_encryption_key    => $webflow_encryption_key,
        u2f_signing_key           => $u2f_signing_key,
        u2f_encryption_key        => $u2f_encryption_key,
        enable_ldap               => $enable_ldap,
        ldap_start_tls            => $ldap_start_tls,
        ldap_uris                 => $ldap_uris,
        ldap_base_dn              => $ldap_config['base-dn'],
        ldap_group_cn             => $ldap_config['group_cn'],
        ldap_attribute_list       => $ldap_attribute_list,
        log_level                 => $log_level,
        ldap_bind_pass            => $passwords::ldap::production::proxypass,
        ldap_bind_dn              => $ldap_config['proxyagent'],
        services                  => $services,
        idp_nodes                 => $idp_nodes,
        java_opts                 => $java_opts,
        max_session_length        => $max_session_length,
        actuators                 => $actuators,
        daemon_user               => $cas_daemon_user,
        log_dir                   => $log_dir,
        memcached_enable          => $memcached_enable,
        memcached_port            => $memcached_port,
        memcached_transcoder      => $memcached_transcoder,
        enable_u2f                => $enable_u2f,
        u2f_jpa_enable            => $u2f_jpa_enable,
        u2f_jpa_username          => $u2f_jpa_username,
        u2f_jpa_password          => $u2f_jpa_password,
        u2f_jpa_server            => $u2f_jpa_server,
        u2f_jpa_db                => $u2f_jpa_db,
        u2f_token_expiry_days     => $u2f_token_expiry_days,
        enable_cors               => $enable_cors,
        cors_allow_credentials    => $cors_allow_credentials,
        cors_allowed_origins      => $cors_allowed_origins,
        cors_allowed_headers      => $cors_allowed_headers,
        cors_allowed_methods      => $cors_allowed_methods,
        delegated_authenticators  => $delegated_authenticators,
    }

    systemd::unit{'tomcat9':
        override => true,
        restart  => true,
        content  => "[Service]\nReadWritePaths=${apereo_cas::log_dir}\n",
    }

    ferm::service {'cas-https':
        proto => 'tcp',
        port  => $ferm_port,
    }

    profile::prometheus::jmx_exporter{ "idp_${facts['networking']['hostname']}":
        hostname    => $facts['networking']['hostname'],
        port        => $jmx_port,
        config_dir  => $jmx_config.dirname,
        config_file => $jmx_config,
        content     => file('profile/idp/cas_jmx_exporter.yaml'),
    }
    if $memcached_enable {
        class {'profile::idp::memcached':
            idp_nodes => $idp_nodes,
        }
    }
    file {'/usr/local/sbin/cas-manage-u2f':
      ensure => file,
      owner  => root,
      mode   => '0500',
      source => 'puppet:///modules/profile/idp/cas_manage_u2f.py',
    }

    profile::logoutd::script {'idp':
        source => 'puppet:///modules/apereo_cas/idp-logout.py',
    }

}
