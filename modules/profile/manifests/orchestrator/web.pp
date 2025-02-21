class profile::orchestrator::web {
    class { 'httpd':
        modules => ['headers', 'proxy', 'proxy_http', 'rewrite', 'ssl', 'macro'],
    }
    class { 'sslcert::dhparam': }

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)
    include profile::idp::client::httpd

    ferm::service { 'orchestrator-http-https':
        proto => 'tcp',
        port  =>  '(http https)',
    }

    profile::auto_restarts::service { 'apache2': }
}
