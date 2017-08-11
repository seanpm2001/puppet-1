# == Class: wikimetrics::queue
# Sets up the celery queue for wikimetrics
# This is done by launching the wikimetrics init script,
# with the queue mode and passing relevant config files

class wikimetrics::queue {
    require wikimetrics::base

    $config_path      = $::wikimetrics::base::config_path
    $venv_path        = $::wikimetrics::base::venv_path

    systemd::service { 'wikimetrics-queue':
        content => systemd_template('wikimetrics-queue'),
        restart => true,
    }
}
