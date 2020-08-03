
control 'hashistack-1.5a' do
  impact 1.0
  title 'Consul Templating'
  desc 'Ensuring we can update files based on KV and service information stored in Consul and Vault'

  describe file('/usr/local/bin/consul-template') do
    it { should exist }
    it { should be_executable }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    it 'should be in the PATH' do
      expect(command('consul-template')).to exist
    end
  end

  describe directory('/etc/consul-template/conf.d') do
    it { should exist }
  end

  describe directory('/etc/consul-template/templates.d') do
    it { should exist }
  end

  # We don't want consul-template to start before we've had a chance to provision the machine
  describe file('/etc/consul-template/conf.d/base.hcl') do
    it { should_not exist }
  end
end

control 'hashistack-1.5b' do
  impact 1.0
  title 'Consul IPSet'
  desc 'Ensuring Consul can keep firewall rules updated to allow only current consul nodes in a trusted network'

  describe file('/etc/consul-template/conf.d/ipset-consul.hcl') do
    it { should exist }
  end

  describe file('/etc/consul-template/templates.d/ipset-consul.xml.ctmpl') do
    it { should exist }
  end
end


