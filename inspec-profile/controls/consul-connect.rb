control 'hashistack-1.2a' do
  impact 0.7
  title 'Consul Connect'
  desc 'Include configuration to allow Nomad to communicate with Consul Connect (VXLAN)'

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

  describe command('envoy') do
    it { should exist }
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
