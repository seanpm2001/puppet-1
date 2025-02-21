class profile::acme_chief::cloud (
    String $active_host = lookup('profile::acme_chief::active'),
    String $passive_host = lookup('profile::acme_chief::passive'),
    String $designate_sync_auth_url = lookup('profile::acme_chief::cloud::designate_sync_auth_url'),
    String $designate_sync_username = lookup('profile::acme_chief::cloud::designate_sync_username'),
    String $designate_sync_password = lookup('profile::acme_chief::cloud::designate_sync_password'),
    Array[String] $designate_sync_project_names = lookup('profile::acme_chief::cloud::designate_sync_project_names'),
    String $designate_sync_region_name = lookup('profile::acme_chief::cloud::designate_sync_region_name'),
    Boolean $designate_sync_tidyup_enabled = lookup('profile::acme_chief::cloud::designate_sync_tidyup_enabled'),
) {
    if $::fqdn == $passive_host {
        $active_host_ip = ipresolve($active_host, 4, $::nameservers[0])
        security::access::config { 'acme-chief':
            content  => "+ : acme-chief : ${active_host_ip}\n",
            priority => 60,
        }
    }

    ensure_packages(['python3-keystoneauth1', 'python3-designateclient'])

    file { '/usr/local/bin/acme-chief-designate-sync.py':
        ensure  => present,
        owner   => 'acme-chief',
        group   => 'acme-chief',
        mode    => '0544',
        require => [
            Package['acme-chief'],
            Package['python3-keystoneauth1'],
            Package['python3-designateclient'],
        ],
        source  => 'puppet:///modules/acme_chief/designate-sync.py'
    }

    file { '/usr/local/bin/acme-chief-designate-tidyup.py':
        ensure  => present,
        owner   => 'acme-chief',
        group   => 'acme-chief',
        mode    => '0544',
        require => [
            Package['acme-chief'],
            Package['python3-keystoneauth1'],
            Package['python3-designateclient'],
        ],
        source  => 'puppet:///modules/acme_chief/designate-tidyup.py'
    }
    $ensure_tidyup = ($designate_sync_tidyup_enabled and $::fqdn == $active_host)? {
        true    => present,
        default => absent,
    }
    cron { 'acme-chief-designate-tidyup':
        ensure   => $ensure_tidyup,
        command  => '/usr/local/bin/acme-chief-designate-tidyup.py | logger -t acme-chief-designate-tidyup',
        user     => 'acme-chief',
        minute   => '0',
        hour     => '*',
        weekday  => '*',
        month    => '*',
        monthday => '*',
        require  => File['/usr/local/bin/acme-chief-designate-tidyup.py'],
    }

    file { '/etc/acme-chief/designate-sync-config.yaml':
        ensure  => present,
        owner   => 'acme-chief',
        group   => 'acme-chief',
        mode    => '0400',
        content => to_yaml({
            'OS_AUTH_URL'      => $designate_sync_auth_url,
            'OS_USERNAME'      => $designate_sync_username,
            'OS_PASSWORD'      => $designate_sync_password,
            'OS_PROJECT_NAMES' => $designate_sync_project_names,
            'OS_REGION_NAME'   => $designate_sync_region_name
        })
    }

    file { '/usr/local/bin/create_acme_le_account.py':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        require => [
            Package['acme-chief'],
            Package['python3-keystoneauth1'],
            Package['python3-designateclient'],
        ],
        content => template('acme_chief/create_acme_le_account.py.erb'),
    }
}
