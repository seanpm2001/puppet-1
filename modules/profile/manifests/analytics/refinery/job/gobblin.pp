# == Class profile::analytics::refinery::job::gobblin
# Declares gobblin jobs to import data from Kafka into Hadoop.
# (Gobblin is a replacement for Camus).
#
# These jobs will eventually be moved to Airflow.
#
# Description of Gobblin jobs declared here:
#
# - webrequest
#   Ingests webrequest_text and webrequest_upload topics into
#   /wmf/data/raw/webrequest/.
#
# - netflow
#   Ingests the netflow topic into /wmf/data/raw/netflow.
#
# - event_default
#   Ingests all streams with consumers.analytics_hadoop_ingestion.job_name == 'event_default'
#   set in stream config to /wmf/data/raw/event
#
# - eventlogging_legacy
#   Ingests legacy EventLogging streams. (No datacenter topic prefixes, topics start with
#   'eventlogging_'.)
#
#
# == Parameters
#
# [*gobblin_shaded_jar*]
#   Path to shaded jar that will be used to launch gobblin.
#   You should set this in your role hiera to a versioned gobblin-wmf jar.
#   Usually this is deployed alongside of analytics/refinery artifacts.
#
class profile::analytics::refinery::job::gobblin(
    Stdlib::Unixpath $gobblin_jar_file = lookup('profile::analytics::refinery::job::test::gobblin_jar_file'),
) {
    require ::profile::analytics::refinery
    $refinery_path = $::profile::analytics::refinery::path



    # analytics-hadoop gobblin jobs should all use analytics-hadoop.sysconfig.properties.
    Profile::Analytics::Refinery::Job::Gobblin_job {
        sysconfig_properties_file => "${refinery_path}/gobblin/common/analytics-hadoop.sysconfig.properties",
        # By default, gobblin_job will use a jobconfig_properties_file of
        # ${refinery_path}/gobblin/jobs/${title}.pull
        gobblin_jar_file          => $gobblin_jar_file,
    }


    profile::analytics::refinery::job::gobblin_job { 'webrequest':
        # webrequest is large. Run it every 10 minutes to keep pressure on Kafka
        # low (pulling more often means it is more likely for data to be in Kafka's cache).
        # The 5 minutes offset from calendar hour is to mitigate out-of-order events
        # messing up with _IMPORTED flags generation.
        interval         => '*-*-* *:05/10:00',
    }

    profile::analytics::refinery::job::gobblin_job { 'netflow':
        # netflow data is unique.  The producer does some minutely aggregation, so all
        # timestamps are alligned with minutes and 0 seconds, e.g. 2021-07-07 18:00:00.
        # This makes gobblin behave when run exactly at an hourly boundry.
        # Gobblin writes _IMPORTED flags only if it notices that it finishes importing
        # for a given hour during a run.  If run at e.g. 10:00:00, it is very
        # unlikely that that specific gobblin run will import any data for hour 10:00;
        # the latest timestamp it will import is 09:59.
        # We want at lesat one gobblin run to see timestamps on either side of the hour.
        # Run at 5 and 35 minutes after the hour.
        # Bug: https://phabricator.wikimedia.org/T286343
        interval         => '*-*-* *:05,35:00',
    }

    profile::analytics::refinery::job::gobblin_job { 'event_default':
        interval         => '*-*-* *:05:00',
    }

    profile::analytics::refinery::job::gobblin_job { 'eventlogging_legacy':
        interval         => '*-*-* *:10:00',
    }
}
