require_relative '../../../../rake_modules/spec_helper'
require 'rspec-puppet/cache'

describe 'openstack::puppet::master::encapi' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:pre_condition) { "class {'base::puppet': ca_source => 'puppet:///modules/profile/puppet/ca.production.pem'}" }
      before(:each) do
        Puppet::Parser::Functions.newfunction(:ipresolve, :type => :rvalue) { |_| '127.0.0.10' }
      end
      let(:facts) { facts }
      let(:params) {
        {
          'mysql_host'            => '127.0.0.1',
          'mysql_db'              => 'testdb',
          'mysql_username'        => 'dummyuser',
          'mysql_password'        => 'dummypass',
          'labweb_hosts'          => ['labweb.sample.localhost'],
          'openstack_controllers' => ['controller.sample.localhost'],
          'designate_hosts'       => ['designate.sample.localhost'],
          # this ends up being the flattened ips from
          # modules/network/data/data.yaml#network::subnets::labs
          'labs_instance_ranges'  => ['185.15.56.0/25', '172.16.0.0/21'],
        }
      }
      it { should compile }
    end
  end
end
