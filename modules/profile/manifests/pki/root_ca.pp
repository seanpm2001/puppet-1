# @summary Configure a cfssl root ca with no API end point
# @param common_name The common name to use on the CA cert
# @param names The certificate authority names used for intermediates
# @param key_params The key algorithm and size used for intermediates
# @param gen_csr if true genrate a CSR.  this is only needed when bootstrapping
# @param db_driver The db driver to use
# @param db_user The db user to use
# @param db_pass The db pass to use
# @param db_name The db name to use
# @param db_host The db host to use
# @param profiles a Hash of signing profiles
# @param auth_keys A hash of auth_keys, this is not actually use as we don't configure the API end point
#   but is required as a security measure in case the API service is started by accident
# @param intermedites An array of intermediate certificates to create.  This profile ensures the certificates are
#   created however you will need to manually copy the created certificate to the puppet repo
class profile::pki::root_ca(
  String                        $common_name   = lookup('profile::pki::root_ca::common_name'),
  String                        $vhost         = lookup('profile::pki::root_ca::vhost'),
  Array[Cfssl::Name]            $names         = lookup('profile::pki::root_ca::names'),
  Cfssl::Key                    $key_params    = lookup('profile::pki::root_ca::key_params'),
  Cfssl::DB_driver              $db_driver     = lookup('profile::pki::root_ca::db_driver'),
  String                        $db_user       = lookup('profile::pki::root_ca::db_user'),
  Sensitive[String[1]]          $db_pass       = lookup('profile::pki::root_ca::db_pass'),
  String                        $db_name       = lookup('profile::pki::root_ca::db_name'),
  Stdlib::Host                  $db_host       = lookup('profile::pki::root_ca::db_host'),
  Hash[String, Cfssl::Profile]  $profiles      = lookup('profile::pki::root_ca::profiles'),
  Hash[String, Cfssl::Auth_key] $auth_keys     = lookup('profile::pki::root_ca::auth_keys'),
  Array[String[3]]              $intermediates = lookup('profile::pki::root_ca::intermediates'),
) {
  $crl_base_url = "http://${vhost}/${common_name}/crl"
  $ocsp_base_url = "http://${vhost}/${common_name}/ocsp"
  class {'cfssl': }
  cfssl::signer {$common_name:
    profiles         => $profiles,
    default_crl_url  => $crl_base_url,
    default_ocsp_url => $ocsp_base_url,
    db_driver        => $db_driver,
    db_user          => $db_user,
    db_pass          => $db_pass,
    db_host          => $db_host,
    db_name          => $db_name,
    auth_keys        => $auth_keys,
    manage_services  => false,
  }
  cfssl::cert {"${common_name}_ocsp_signing_cert":
    key           => $key_params,
    names         => $names,
    signer_config => {'config_dir' => "${cfssl::signer_dir}/${common_name}"},
    profile       => 'ocsp',
    require       => Cfssl::Signer[$common_name],
  }
  $intermediates.each |$intermediate| {
    cfssl::cert {$intermediate:
      key           => $key_params,
      names         => $names,
      signer_config => {'config_dir' => "${cfssl::signer_dir}/${common_name}"},
      profile       => 'intermediate',
      require       => Cfssl::Signer[$common_name],
    }
  }
}
