# == Class: base::kernel
#
# Settings related to the Linux kernel and microcode loading
#
# [*overlayfs*]
#  bool for whether overlay module is needed

class base::kernel(
    $overlayfs,
    ) {
    if ! $overlayfs {
        kmod::blacklist { 'wmf_overlay':
            modules => [
                'overlayfs',
                'overlay',
            ],
        }
    } else {
        kmod::blacklist { 'wmf_overlay':
            ensure => absent,
        }

        # On a fresh node overlay may be unloaded automatically by the OS
        # if no fs needs it. In this case the kern.log should look like:
        # kernel: request_module fs-overlay succeeded, but still no fs?
        # This may lead to unwanted side effects, like Docker not finding
        # the overlay kernel module loaded and falling back to
        # the device-mapper storage driver.
        # Therefore we explicitly load the overlay module when the overlayfs
        # option is true.
        kmod::module { 'overlay':
            ensure => 'present',
        }
    }

    kmod::blacklist { 'wmf':
        modules => [
            'aufs',
            'usbip-core',
            'usbip-host',
            'vhci-hcd',
            'dccp',
            'dccp_ipv6',
            'dccp_ipv4',
            'dccp_probe',
            'dccp_diag',
            'n_hdlc',
            'intel_cstate',
            'intel_rapl_perf',
            'intel_uncore',
            'parport',
            'parport_pc',
            'ppdev',
            'acpi_power_meter',
            'bluetooth',
            'v4l2-common',
            'floppy',
            'cdrom',
        ],
    }

    if (versioncmp($::kernelversion, '4.4') >= 0) {
        kmod::blacklist { 'linux44':
            modules => [ 'asn1_decoder', 'macsec' ],
        }
    }

    # This section is for blacklisting modules per server model.
    # It was originally started for acpi_pad issues on R320 (T162850)
    # but is meant to be extended as needed.
    case $::productname {
      'PowerEdge R320': {
        kmod::blacklist { 'r320':
            modules => [ 'acpi_pad' ],
        }
      }
      default: {}
    }

    # Settings to mitigate fragmentsmack. The low settings need to be applied
    # before the high settings, otherwise the new high settings are lower than
    # the current kernel defaults which results in sysctl rejecting the value
    # The latest kernel update for stretch also pushes these settings by default
    # in the kernel, so at some point this can be removed in puppet
    sysctl::parameters { 'ipfrag_low':
        values   => {
            'net.ipv4.ipfrag_low_thresh'  => '196608',
            'net.ipv6.ip6frag_low_thresh' => '196608',
        },
        priority => 10,
        before   => Sysctl::Parameters['ipfrag_high']
    }

    sysctl::parameters { 'ipfrag_high':
        values   => {
            'net.ipv4.ipfrag_high_thresh'  => '262144',
            'net.ipv6.ip6frag_high_thresh' => '262144',
        },
        priority => 11,
    }
    file { '/usr/lib/nagios/plugins/check_microcode':
        ensure => absent,
    }
    file { '/usr/local/lib/nagios/plugins/check_microcode':
        source => 'puppet:///modules/base/check-microcode.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    nrpe::monitor_service { 'cpu_microcode_status':
        ensure         => 'present',
        description    => 'Check whether microcode mitigations for CPU vulnerabilities are applied',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_microcode',
        require        => File['/usr/local/lib/nagios/plugins/check_microcode'],
        contact_group  => 'admins',
        check_interval => 1440,
        retry_interval => 5,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Microcode',
    }
}
