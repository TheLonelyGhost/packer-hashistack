# copyright: 2020, David Alexander

control 'hashistack-1.1' do
  impact 0.7
  title 'Install HashiCorp Nomad'
  desc ''

  describe file('/usr/local/bin/nomad') do
    it { should exist }
    it { should be_executable }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    it 'should be in the PATH' do
      expect(command('nomad')).to exist
    end
  end

  describe 'Nomad data directory' do
    subject { directory('/opt/nomad') }
    it { should exist }
    its('owner') { should eq 'nomad' }
    its('group') { should eq 'nomad' }
  end

  describe 'Nomad config directory' do
    subject { directory('/etc/nomad.d') }
    it { should exist }
    its('owner') { should eq 'nomad' }
    its('group') { should eq 'nomad' }
  end

  describe systemd_service('nomad') do
    it { should be_installed }
    it { should be_enabled }
  end

  describe command('systemd-analyze verify /etc/systemd/system/nomad.service') do
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end
end

control 'hashistack-1.1a' do
  impact 0.7
  title 'Configure HashiCorp Nomad with Consul Connect'
  desc ''

  describe kernel_parameter('net.bridge.bridge-nf-call-arptables') do
    its('value') { should cmp '1' }
  end

  describe kernel_parameter('net.bridge.bridge-nf-call-iptables') do
    its('value') { should cmp '1' }
  end

  describe kernel_parameter('net.bridge.bridge-nf-call-ip6tables') do
    its('value') { should cmp '1' }
  end

  describe kernel_parameter('net.ipv4.ip_local_port_range') do
    it "should not overlap with Nomad's dynamic port range" do
      ephem_ports = subject.value.chomp.split(/\s+/).map {|v| v.to_i }
      expect(ephem_ports[0]).to be > 32000
    end
  end

  describe directory('/opt/cni/bin') do
    it { should exist }
  end

  # An example plugin: flannel
  describe file('/opt/cni/bin/flannel') do
    it { should exist }
    it { should be_executable }
  end
end
