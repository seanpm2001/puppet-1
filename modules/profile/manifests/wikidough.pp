class profile::wikidough (
    Stdlib::Fqdn              $service_domain   = lookup('profile::wikidough::service_domain'),
    Dnsdist::Resolver         $resolver         = lookup('profile::wikidough::dnsdist::resolver'),
    Dnsdist::TLS_common       $tls_common       = lookup('profile::wikidough::dnsdist::tls_common'),
    Dnsdist::TLS_config       $tls_doh          = lookup('profile::wikidough::dnsdist::tls_doh'),
    Dnsdist::TLS_config       $tls_dot          = lookup('profile::wikidough::dnsdist::tls_dot'),
    Dnsdist::Webserver_config $webserver_config = lookup('profile::wikidough::dnsdist::webserver_config', {'merge' => hash}),
    Dnsdist::Http_headers     $custom_headers   = lookup('profile::wikidough::dnsdist::custom_headers'),
) {

    include network::constants
    include passwords::wikidough::dnsdist

    motd::script { 'root-commands-warning':
        ensure   => 'present',
        priority => 1,
        content  => template('profile/wikidough/motd.erb'),
    }

    ferm::service { 'wikidough-doh':
        proto   => 'tcp',
        notrack => true,
        port    => 443,
    }

    ferm::service { 'wikidough-dot':
        proto   => 'tcp',
        notrack => true,
        port    => 853,
    }

    ferm::service { 'wikidough-dnsdist-webserver':
        proto  => 'tcp',
        port   => $webserver_config['port'],
        srange => '$PRODUCTION_NETWORKS',
    }

    class { 'dnsrecursor':
        listen_addresses         => [$resolver['ip']],
        allow_from               => ['127.0.0.0/8'],
        max_tcp_per_client       => 0,
        client_tcp_timeout       => 5,
        dnssec                   => 'validate',
        allow_forward_zones      => false,
        allow_incoming_ecs       => true,
        allow_qname_minimisation => true,
        allow_dot_to_auth        => true,
        install_from_component   => true,
        do_ipv6                  => true,
        allow_edns_padding       => true,
        edns_padding_from        => '127.0.0.0/8',
        edns_padding_mode        => 'padded-queries-only',
    }

    acme_chief::cert { 'wikidough':
        puppet_svc => 'dnsdist',
        key_group  => '_dnsdist',
    }

    class { 'dnsdist':
        resolver         => $resolver,
        tls_common       => $tls_common,
        tls_config_doh   => $tls_doh,
        tls_config_dot   => $tls_dot,
        enable_console   => true,
        console_key      => $passwords::wikidough::dnsdist::console_key,
        enable_webserver => true,
        webserver        => $webserver_config,
        enable_landing   => true,
        landing_text     => file('profile/wikidough/index.html'),
        custom_headers   => $custom_headers,
        require          => Class['dnsrecursor'],
    }

    monitoring::service { 'check_wikidough_doh_ipv4':
        description   => 'Wikidough DoH Check (IPv4)',
        check_command => "check_https_url_custom_ip!${service_domain}!${facts['ipaddress']}!/",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidough',
    }

    monitoring::service { 'check_wikidough_dot_ipv4':
        description   => 'Wikidough DoT Check (IPv4)',
        check_command => "check_tcp_ssl!${facts['ipaddress']}!853",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidough',
    }

    monitoring::service { 'check_wikidough_doh_ipv6':
        description   => 'Wikidough DoH Check (IPv6)',
        check_command => "check_https_url_custom_ip!${service_domain}!${facts['ipaddress6']}!/",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidough',
    }

    monitoring::service { 'check_wikidough_dot_ipv6':
        description   => 'Wikidough DoT Check (IPv6)',
        check_command => "check_tcp_ssl!${facts['ipaddress6']}!853",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidough',
    }

    class { 'auditd':
        log_to_disk    => false,
        rule_root_cmds => true,
        send_to_syslog => true,
    }

}
