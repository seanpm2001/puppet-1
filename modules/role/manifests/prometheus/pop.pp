class role::prometheus::pop {
    system::role { 'prometheus::pop':
        description => 'Prometheus server (cache pop data centres)',
    }

    include ::profile::base::production
    include ::profile::base::firewall

    require ::profile::prometheus::ops

    include ::profile::alerts::deploy::prometheus

    include ::profile::prometheus::rsyncd

    class { '::httpd':
        # 'rewrite' is used by ::profile::prometheus::ops
        modules => ['proxy', 'proxy_http', 'rewrite'],
    }
}
