# mediawiki maintenance server
class profile::mediawiki::maintenance(
    $maintenance_server = hiera('maintenance_server'),
) {

    # Deployment
    include ::scap::scripts

    file { $::mediawiki::scap::mediawiki_staging_dir:
        ensure => link,
        target => '/srv/mediawiki'
    }
    $ensure = $maintenance_server ? {
        $::fqdn => 'present',
        undef   => 'absent',
        default => 'absent',
    }

    # Mediawiki maintenance scripts (cron jobs)
    class { 'mediawiki::maintenance::pagetriage': ensure => $ensure }
    class { 'mediawiki::maintenance::translationnotifications': ensure => $ensure }
    class { 'mediawiki::maintenance::updatetranslationstats': ensure => $ensure }
    class { 'mediawiki::maintenance::wikidata': ensure => $ensure, ensure_testwiki => $ensure }
    class { 'mediawiki::maintenance::echo_mail_batch': ensure => $ensure }
    class { 'mediawiki::maintenance::parsercachepurging': ensure => $ensure }
    class { 'mediawiki::maintenance::cleanup_upload_stash': ensure => $ensure }
    class { 'mediawiki::maintenance::tor_exit_node': ensure => $ensure }
    class { 'mediawiki::maintenance::update_flaggedrev_stats': ensure => $ensure }
    class { 'mediawiki::maintenance::refreshlinks': ensure => $ensure }
    class { 'mediawiki::maintenance::update_special_pages': ensure => $ensure }
    class { 'mediawiki::maintenance::purge_abusefilter': ensure => $ensure }
    class { 'mediawiki::maintenance::purge_checkuser': ensure => $ensure }
    class { 'mediawiki::maintenance::purge_expired_userrights': ensure => $ensure }
    class { 'mediawiki::maintenance::purge_securepoll': ensure => $ensure }
    class { 'mediawiki::maintenance::jobqueue_stats': ensure => $ensure }
    class { 'mediawiki::maintenance::db_lag_stats': ensure => $ensure }
    class { 'mediawiki::maintenance::cirrussearch': ensure => $ensure }
    class { 'mediawiki::maintenance::generatecaptcha': ensure => $ensure }
    class { 'mediawiki::maintenance::pageassessments': ensure => $ensure }
    class { 'mediawiki::maintenance::uploads': ensure => $ensure }
    class { 'mediawiki::maintenance::readinglists': ensure => $ensure }
    class { 'mediawiki::maintenance::initsitestats': ensure => $ensure }

    # Include the cache warmup script; requires node and conftool
    require ::profile::conftool::client
    class { '::mediawiki::maintenance::cache_warmup':
        ensure => present,
    }

    # backup home directories to bacula, people work on these
    include ::profile::backup::host
    backup::set {'home': }

    # (T17434) Periodical run of currently disabled special pages
    class { 'mediawiki::maintenance::updatequerypages': ensure => $ensure }

    # Readline support for PHP maintenance scripts (T126262)
    if  os_version('debian >= stretch') {
        require_package('php-readline')
    } else {
        require_package('php5-readline')
    }

    # GNU version of 'time' provides extra info like peak resident memory
    # anomie needs it, as opposed to the shell built-in time command
    require_package('time')

    # T112660 - kafka support
    # The eventlogging code is useful for scripting
    # EventLogging consumers.  Install this but don't
    # run any daemons.  To use eventlogging code,
    # add /srv/deployment/eventlogging/eventlogging
    # to your PYTHONPATH or sys.path.
    include ::eventlogging

    rsync::quickdatacopy { 'home-mwmaint':
        ensure      => present,
        auto_sync   => false,
        source_host => 'mwmaint1001.eqiad.wmnet',
        dest_host   => 'mwmaint2001.codfw.wmnet',
        module_path => '/home',
    }
}
