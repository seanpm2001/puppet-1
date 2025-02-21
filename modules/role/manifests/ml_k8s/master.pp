class role::ml_k8s::master {
    include ::profile::base::production
    include ::profile::base::firewall

    # Sets up kubernetes on the machine
    include ::profile::kubernetes::master
    # Strictly speaking kubectl isn't needed, but have it here for historical
    # reasons
    include ::profile::kubernetes::client

    # Needed to schedule containers like bird, used by calico.
    # More info: T285927
    # Sets up docker on the machine. We don't add the profile::docker::storage
    # profile on purpose, to use profile::docker::engine's defaults
    # (namely overlay2 if os >= buster).
    include ::profile::docker::engine
    include ::profile::kubernetes::node
    include ::profile::calico::kubernetes

    # LVS configuration (VIP)
    include ::profile::lvs::realserver

    system::role { 'kubernetes::master':
        description => 'ML Kubernetes master server',
    }
}
