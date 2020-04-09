class openstack::serverpackages::rocky::stretch(
){
    $stretch_bpo_packages = [
      'librados2',
      'librgw2',
      'librbd1',
      'python-rados',
      'python-rbd',
      'ceph-common',
      'python-cephfs',
      'libradosstriper1',
    ]

    apt::pin { 'openstack-rocky-stretch-bpo':
        package  => join($stretch_bpo_packages, ' '),
        pin      => 'release n=stretch-backports',
        priority => '1002',
    }

    # Force these packages to come from the nochange bpo
    #  even if they're available in the wikimedia repo.
    # This gets us the versions we require.
    $stretch_bpo_nochange_packages = [
      'uwsgi-plugin-python3',
      'uwsgi-core',
      'uwsgi-plugin-python',
    ]

    apt::pin { 'openstack-rocky-stretch-bpo-nochange':
        package  => join($stretch_bpo_nochange_packages, ' '),
        pin      => 'release n=stretch-rocky-backports-nochange',
        priority => '1002',
    }

    # Don't install systemd from stretch-backports or bpo -- T247013
    apt::pin { 'systemd':
        pin      => 'release n=stretch',
        package  => 'systemd libpam-systemd',
        priority => '1001',
    }

    apt::repository { 'openstack-rocky-stretch':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'stretch-rocky-backports',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-rocky-stretch-apt-upgrade'],
    }

    apt::repository { 'openstack-rocky-stretch-nochange':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'stretch-rocky-backports-nochange',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-rocky-stretch-apt-upgrade'],
    }

    # Overlay a tooz driver that has an encoding bug.  This bug is present
    #  in version of this package found in the rocky apt repo, 1.62.0-1~bpo9+1.
    #  It is likely fixed in any future version, so this should probably not be
    #  forwarded to S.
    #
    # Upstream bug: https://bugs.launchpad.net/python-tooz/+bug/1530888
    require_package('python3-tooz')
    file { '/usr/lib/python3/dist-packages/tooz/drivers/memcached.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/openstack/rocky/toozpatch/tooz-memcached.py',
        require => Package['python3-tooz'];
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-rocky-stretch-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-rocky-stretch'],
                        Apt::Repository['openstack-rocky-stretch-nochange']],
        subscribe   => [Apt::Repository['openstack-rocky-stretch'],
                        Apt::Repository['openstack-rocky-stretch-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-rocky-stretch-apt-upgrade'] -> Package <| |>
}
