class profile::prometheus::memcached_exporter (
    String              $arguments        = lookup('profile::prometheus::memcached_exporter::arguments'),
) {
    prometheus::memcached_exporter { 'default':
        arguments => $arguments,
    }
}
