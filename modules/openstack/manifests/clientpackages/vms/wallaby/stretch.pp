# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::wallaby::stretch(
) {
    requires_realm('labs')
}
