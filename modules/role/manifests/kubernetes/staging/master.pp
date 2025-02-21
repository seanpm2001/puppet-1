# A profile for setting up the kubernetes control-plane
class role::kubernetes::staging::master {
    include ::profile::base::production
    include ::profile::base::firewall

    # Sets up kubernetes on the machine
    include ::profile::kubernetes::master
    # Strictly speaking kubectl isn't needed, but have it here for historical
    # reasons
    include ::profile::kubernetes::client

    # ::profile::docker::storage is not included which means the docker
    # default (overlayfs for >=buster) will be used. While this differs
    # from the setup of the worker nodes, but we will migrate them in
    # the future and may gain some experience already.
    include ::profile::docker::engine
    include ::profile::kubernetes::node
    include ::profile::calico::kubernetes

    system::role { 'kubernetes::staging::master':
        description => 'Kubernetes master server (staging setup)',
    }
}
