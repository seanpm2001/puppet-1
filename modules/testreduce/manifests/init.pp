# == Class: testreduce
#
# This file provides the testreduce code repository
#
class testreduce(
    Boolean $install_node,
){

    if $install_node {
        if debian::codename::eq('stretch') {
            fail('Should not be installing nodejs on Debian Stretch.')
        }
        ensure_packages(['nodejs', 'npm'])
    }

    group { 'testreduce':
        ensure => present,
        system => true,
    }

    user { 'testreduce':
        gid        => 'testreduce',
        home       => '/srv/testreduce',
        managehome => false,
        system     => true,
    }

    file { '/var/log/testreduce':
        ensure => directory,
        owner  => 'testreduce',
        group  => 'testreduce',
        mode   => '0755',
    }

    file { '/etc/testreduce':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    git::clone { 'mediawiki/services/parsoid/testreduce':
        owner     => 'root',
        group     => 'wikidev',
        directory => '/srv/testreduce',
        # FIXME: Is this notification required?
        # There can be multiple services that might
        # be instantiated using the code from this
        # repository. The only way to notify all those
        # services would be hardcode all their names here.
        #
        # notify    => Service[$instance_name],
    }
}
