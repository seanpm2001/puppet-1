# List of available backup filesets
class profile::backup::filesets(
    Stdlib::Unixpath $helmfile_general_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # This has been taken straight from old files/backup/disklist-*
    bacula::director::fileset { 'root':
        includes     => [ '/' ]
    }
    bacula::director::fileset { 'cloudweb-srv-backup':
        includes => [ '/srv/backup' ]
    }
    # TODO: remove this when geowiki site is no longer needed.
    # https://phabricator.wikimedia.org/T190059
    bacula::director::fileset { 'a-geowiki-data-private-bare':
        includes => [ '/srv/geowiki/data-private-bare' ]
    }
    bacula::director::fileset { 'home':
        includes => [ '/home' ]
    }
    bacula::director::fileset { 'srv-autoinstall':
        includes => [ '/srv/autoinstall' ]
    }
    bacula::director::fileset { 'srv-tftpboot':
        includes => [ '/srv/tftpboot' ]
    }
    bacula::director::fileset { 'srv-wikimedia':
        includes => [ '/srv/wikimedia' ]
    }
    bacula::director::fileset { 'srv-org-wikimedia':
        includes => [ '/srv/org/wikimedia' ]
    }
    bacula::director::fileset { 'srv-doc':
        includes => [ '/srv/doc' ]
    }
    bacula::director::fileset { 'var-lib-archiva':
        includes     => [ '/var/lib/archiva' ],
    }
    bacula::director::fileset { 'var-lib-jenkins-config':
        includes     => [ '/var/lib/jenkins/config.xml' ],
    }
    bacula::director::fileset { 'gerrit-repo-data':
        includes => [ '/srv/gerrit/git', '/srv/gerrit/plugins/lfs' ]
    }
    bacula::director::fileset { 'srv-carbon-whisper-coal':
        includes => [ '/srv/carbon/whisper/coal' ]
    }
    bacula::director::fileset { 'srv-carbon-whisper-daily':
        includes => [ '/srv/carbon/whisper/daily' ]
    }
    bacula::director::fileset { 'var-lib-graphite-web-graphite-db':
        includes => [ '/var/lib/graphite-web/graphite.db' ]
    }
    bacula::director::fileset { 'var-lib-jenkins-backups':
        includes => [ '/var/lib/jenkins/backups' ]
    }
    bacula::director::fileset { 'gitlab':
        includes => [ '/srv/gitlab-backup/latest', '/etc/gitlab/config_backup/latest' ]
    }
    bacula::director::fileset { 'var-lib-mailman3':
        includes => [
            # Contains pipermail archives
            '/var/lib/mailman',
            # Contains various data files and state that isn't in MariaDB
            '/var/lib/mailman3',
        ],
        excludes => [
            # In progress digests, see T279237#7025093
            '/var/lib/mailman3/lists/*/digest.mmdf',
            # Queue state
            '/var/lib/mailman3/queue/',
            # Packaged stuff
            '/var/lib/mailman3/web/static/',
        ],
    }
    bacula::director::fileset { 'var-lib-puppet-ssl':
        includes => [ '/var/lib/puppet/ssl', '/var/lib/puppet/server/ssl' ]
    }
    bacula::director::fileset { 'var-lib-puppet-volatile':
        includes => [ '/var/lib/puppet/volatile' ]
    }
    bacula::director::fileset { 'var-opendj-backups':
        includes => [ '/var/opendj/backups' ]
    }
    bacula::director::fileset { 'var-vmail':
        includes => [ '/var/vmail' ]
    }
    bacula::director::fileset { 'mysql-srv-backups':
        includes => [ '/srv/backups' ]
    }
    bacula::director::fileset { 'krb-srv-backup':
        includes => [ '/srv/backup' ]
    }
    bacula::director::fileset { 'mysql-srv-backups-dumps-latest':
        includes => [ '/srv/backups/dumps/latest' ]
    }
    bacula::director::fileset { 'mysql-srv-backups-snapshots-latest':
        includes => [ '/srv/backups/snapshots/latest' ]
    }
    bacula::director::fileset { 'static-codereview':
        includes => [ '/srv/org/wikimedia/static-codereview' ]
    }
    bacula::director::fileset { 'rt-static':
        includes => [ '/srv/org/wikimedia/static-rt' ]
    }
    bacula::director::fileset { 'srv-deployment':
        includes => [ '/srv' ]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-pfalse-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-pfalse-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-pfalse-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-pfalse-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-ptrue-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-ptrue-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-ptrue-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-ptrue-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-pfalse-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-pfalse-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-pfalse-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-pfalse-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-ptrue-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-ptrue-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-ptrue-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-ptrue-itrue',]
    }
    bacula::director::fileset { 'bpipe-mysql-xfalse-ptrue-itrue':
        includes => [],
        plugins  => [ 'bpipe-mysql-xfalse-ptrue-itrue'],
    }
    bacula::director::fileset { 'var-lib-grafana':
        includes => [ '/var/lib/grafana' ],
    }
    bacula::director::fileset { 'srv-repos':
        includes => [ '/srv/repos' ],
    }
    bacula::director::fileset { 'openldap':
        includes => [ '/var/run/openldap-backup' ],
    }
    bacula::director::fileset { 'contint':
        includes => [ '/srv', '/var/lib/zuul', '/var/lib/jenkins' ],
        excludes => [
            '/srv/docker',
            '/srv/jenkins/builds',
            '/var/lib/jenkins/builds',
        ],
    }
    bacula::director::fileset { 'etcd':
        includes => [ '/srv/backups/etcd' ]
    }

    bacula::director::fileset { 'librenms':
        includes => [ '/var/lib/librenms', '/srv/librenms' ]
    }

    bacula::director::fileset { 'smokeping':
        includes => [ '/var/lib/smokeping', '/var/cache/smokeping' ]
    }

    bacula::director::fileset { 'rancid':
        includes => [ '/var/lib/rancid' ]
    }

    bacula::director::fileset { 'hadoop-namenode-backup':
        includes => [ '/srv/backup/hadoop/namenode' ]
    }

    bacula::director::fileset { 'postgresql':
        includes => [ '/srv/postgres-backup/' ]
    }

    bacula::director::fileset { 'netbox':
        includes => [ '/srv/netbox-dumps/',
                    ]
    }

    bacula::director::fileset { 'netbox-postgres':
        includes => [ '/srv/postgres-backup/',
                    ]
    }

    bacula::director::fileset { 'arclamp-application-data':
        includes => [ '/srv/xenon/' ]
    }

    bacula::director::fileset { 'analytics-meta-mysql-lvm-backup':
        includes => [ '/srv/backup/mysql/analytics-meta' ]
    }

    bacula::director::fileset { 'pki-root-cfssl':
        includes => [ '/etc/cfssl' ]
    }
    # Kubernetes mediawiki releases repository. See T299648
    bacula::director::fileset { 'mediawiki-k8s-releases-repository':
        includes => [ "${helmfile_general_dir}/mediawiki/release"]
    }
}
