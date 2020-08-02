# copyright: 2020, David Alexander

control 'hashistack-1.0' do
  impact 0.7
  title 'Install HashiCorp Consul'
  desc ''

  describe file('/usr/local/bin/consul') do
    it { should exist }
    it { should be_executable }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    it 'should be in the PATH' do
      expect(command('consul')).to exist
    end
  end

  describe user('consul') do
    it { should exist }
    its('groups') { should_not include 'wheel' }
  end

  describe directory('/etc/consul.d') do
    it { should exist }
    its('owner') { should eq 'consul' }
    its('group') { should eq 'consul' }
    its('mode') { should eq 0o700 }
  end

  describe systemd_service('consul') do
    it { should be_installed }
    it { should be_enabled }
  end

  describe command('envoy') do
    it { should exist }
  end

  describe firewalld do
    it { should have_service_enabled_in_zone('consul-dns', 'internal') }
    it { should have_service_enabled_in_zone('consul-http', 'internal') }
    it { should have_service_enabled_in_zone('consul-serf-lan', 'trusted') }
    it { should have_service_enabled_in_zone('consul-serf-wan', 'trusted') }
    it { should have_service_enabled_in_zone('consul-serf-wan', 'public') }
    it { should have_service_enabled_in_zone('consul-sidecar', 'public') }
    it { should have_service_enabled_in_zone('consul-expose', 'public') }
    it { should have_service_enabled_in_zone('consul-server', 'public') }
    it { should have_service_enabled_in_zone('consul-grpc', 'public') }
    it { should have_service_enabled_in_zone('dns', 'internal') }
  end

  describe systemd_service('dnsmasq') do
    it { should be_installed }
    it { should be_running }
  end

  describe file('/etc/dnsmasq.d/10-consul') do
    it { should exist }
    its('content') { should match %r{^server=/consul/127\.0\.0\.1#8600$}i }
    its('content') { should match /^server=\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/i }
    its('content') { should match /^no-resolv$/i }
    its('content') { should match /^local-service$/i }
  end

  describe.one do
    describe file('/etc/systemd/resolved.conf') do
      it { should_not exist }
    end

    describe file('/etc/systemd/resolved.conf') do
      its('content') { should match /^DNSStubListener=no$/i }
    end
  end
end
