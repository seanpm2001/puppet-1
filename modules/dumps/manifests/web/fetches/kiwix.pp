class dumps::web::fetches::kiwix(
    $user = undef,
    $group = undef,
    $xmldumpsdir = undef,
    $miscdatasetsdir = undef,
) {
    ensure_packages('rsync')

    file { "${xmldumpsdir}/kiwix":
        ensure => 'link',
        target => "${miscdatasetsdir}/kiwix",
        owner  => $user,
        group  => $group,
        mode   => '0644',
    }

    file { '/usr/local/bin/kiwix-rsync-cron.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/fetches/kiwix-rsync-cron.sh',
    }

    systemd::timer::job { 'kiwix-mirror-update':
        ensure             => present,
        description        => 'Regular jobs to update kiwix mirror',
        user               => $user,
        monitoring_enabled => false,
        send_mail          => true,
        environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command            => "/bin/bash /usr/local/bin/kiwix-rsync-cron.sh ${miscdatasetsdir}",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 0/2:15:0'},
        require            => File['/usr/local/bin/kiwix-rsync-cron.sh'],
    }
}
