# Class: profile::hive::monitoring::server
#
# Sets up Prometheus based monitoring for the Hive Server.
# This profile takes care of installing the Prometheus exporter and setting
# up its configuration file, but it does not instruct the target JVM to use it.
#
class profile::hive::monitoring::server {
    $jmx_exporter_config_file = '/etc/prometheus/hive_server_jmx_exporter.yaml'
    $prometheus_jmx_exporter_hive_server_port = 10100
    profile::prometheus::jmx_exporter { "hive_server_${::hostname}":
        hostname    => $::hostname,
        port        => $prometheus_jmx_exporter_hive_server_port,
        config_file => $jmx_exporter_config_file,
        config_dir  => '/etc/prometheus',
        source      => 'puppet:///modules/profile/hive/prometheus_hive_server_jmx_exporter.yaml',
    }
}
