# == Class: profile::webperf::processors
#
# Provision the webperf data processors. Consumes from Kafka (incl. EventLogging),
# and produces to StatsD and Graphite.
#
# Contact: Performance Team
# See also: <https://wikitech.wikimedia.org/wiki/Webperf>
#
# Services:
#
# - statsv
# - navtiming
# - coal
#
class profile::webperf::processors(
    String       $statsd        = lookup('statsd'),
    Stdlib::Fqdn $graphite_host = lookup('graphite_host'),
){

    $statsd_parts = split($statsd, ':')
    $statsd_host = $statsd_parts[0]
    $statsd_port = 0 + Integer($statsd_parts[1])

    # statsv is on main kafka, not analytics or jumbo kafka.
    # Note that at any given time, all statsv varnishkafka producers are
    # configured to send to only one kafka cluster (usually main-eqiad).
    # statsv in an inactive datacenter will not process any messages, as
    # varnishkafka will not produce any messages to that DC's kafka cluster.
    # This is configured by the value of the hiera param
    # profile::cache::kafka::statsv::kafka_cluster_name when the statsv varnishkafka
    # profile is included (as of this writing on text caches).
    $kafka_main_config = kafka_config('main')
    $kafka_main_brokers = $kafka_main_config['brokers']['ssl_string']

    $kafka_ssl_cafile = profile::base::certificates::get_trusted_ca_path()

    # Consume statsd metrics from Kafka and emit them to statsd.
    class { '::webperf::statsv':
        kafka_brokers           => $kafka_main_brokers,
        kafka_security_protocol => 'SSL',
        kafka_api_version       => $kafka_main_config['api_version'],
        statsd_host             => '127.0.0.1',  # relay through statsd_exporter
        statsd_port             => 9125,
        kafka_ssl_cafile        => $kafka_ssl_cafile,
    }
    class { 'profile::prometheus::statsd_exporter': }

    # EventLogging is on the jumbo kafka. Unlike the main one, this
    # is not yet mirrored to other data centers, so for prod,
    # assume eqiad.
    $kafka_config  = kafka_config('jumbo', 'eqiad')
    $kafka_brokers = $kafka_config['brokers']['ssl_string']

    # Aggregate client-side latency measurements collected via the
    # NavigationTiming MediaWiki extension and send them to Graphite.
    # See <https://www.mediawiki.org/wiki/Extension:NavigationTiming>
    class { '::webperf::navtiming':
        kafka_brokers           => $kafka_brokers,
        kafka_security_protocol => 'SSL',
        statsd_host             => $statsd_host,
        statsd_port             => $statsd_port,
        kafka_ssl_cafile        => $kafka_ssl_cafile,
    }

    # navtiming exports Prometheus metrics on port 9230.
    if $::realm == 'labs' {
        ferm::service { 'prometheus-navtiming-exporter':
            proto  => 'tcp',
            port   => '9230',
            srange => '$LABS_NETWORKS',
        }
    }

    # Make a valid target for coal, and set up what's needed for the consumer
    # Consumes from the jumbo-eqiad cluster, just like navtiming
    class { '::coal::processor':
        kafka_brokers           => $kafka_brokers,
        kafka_security_protocol => 'SSL',
        graphite_host           => $graphite_host,
        kafka_ssl_cafile        => $kafka_ssl_cafile,
    }
}
