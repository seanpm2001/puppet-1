# Class: profile::hive::monitoring::metastore
#
# Sets up Prometheus based monitoring for the Hive Metastore.
# This profile takes care of installing the Prometheus exporter and setting
# up its configuration file, but it does not instruct the target JVM to use it.
#
class profile::hive::monitoring::metastore {
    $jmx_exporter_config_file = '/etc/prometheus/hive_metastore_jmx_exporter.yaml'
    $prometheus_jmx_exporter_hive_metastore_port = 9183
    profile::prometheus::jmx_exporter { "hive_metastore_${::hostname}":
        hostname    => $::hostname,
        port        => $prometheus_jmx_exporter_hive_metastore_port,
        config_file => $jmx_exporter_config_file,
        config_dir  => '/etc/prometheus',
        source      => 'puppet:///modules/profile/hive/prometheus_hive_metastore_jmx_exporter.yaml',
    }
}
