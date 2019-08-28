# == Class: pmacct
#
# Install and manage Fastnetmon
#
# === Parameters
#
#  [*networks*]
#    List of Networks we care about
#    Default: []
#  [*graphite_host*]
#    Hostname of the Graphite ingester
#    Optional

class fastnetmon(
  Array[Stdlib::IP::Address,1] $networks = [],
  Optional[Stdlib::Host] $graphite_host = undef,
  ) {

    require_package('fastnetmon','python3-geoip2')

    file { '/etc/fastnetmon.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('fastnetmon/fastnetmon.conf.erb'),
        require => Package['fastnetmon'],
        notify  => Service['fastnetmon'],
    }

    file { '/etc/networks_list':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('fastnetmon/networks_list.erb'),
        require => Package['fastnetmon'],
        notify  => Service['fastnetmon'],
    }

    file { '/usr/local/bin/fastnetmon_notify.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/fastnetmon/fastnetmon_notify.py',
    }

    file { '/usr/local/bin/fastnetmon_notify':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/fastnetmon/fastnetmon_notify',
    }

    service { 'fastnetmon':
        ensure => running,
        enable => true,
    }
}
