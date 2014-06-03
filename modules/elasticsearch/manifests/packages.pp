# == Class: elasticsearch::packages
#
# Provisions Elasticsearch package and dependencies.
#
class elasticsearch::packages {
    if ! defined ( Package['openjdk-7-jdk'] ) {
        package { 'openjdk-7-jdk':
            ensure => 'present',
        }
    }

    package { 'elasticsearch':
        require => Package['openjdk-7-jdk'],
        ensure  => 'present',
    }

    if ! defined ( Package['curl'] ) {
        package { 'curl': ensure => present }
    }
}
