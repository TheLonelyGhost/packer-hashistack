# copyright: 2020, David Alexander

ssh_user = ENV.fetch('ENTRY_USER')
# ssh_pubkey = ENV.fetch('ENTRY_USER_PUBKEY')
ssh_port = ENV.fetch('SSH_PORT')

control 'hashistack-1.4a' do
  impact 1.0
  title 'ssh'
  desc 'Configure SSH in a secure way'

  describe systemd_service('sshd') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe sshd_config do
    its('Port') { should eq ssh_port }
    its('PermitRootLogin') { should eq 'no' }
    its('PasswordAuthentication') { should eq 'no' }
  end

  describe systemd_service('fail2ban') do
    it { should be_installed }
    it { should be_enabled }
  end
end

control 'hashistack-1.4b' do
  impact 1.0
  title 'firewall'
  desc 'Configure firewalld for all services'

  describe firewalld do
    it { should be_running }
    its('default_zone') { should eq 'public' }
    it { should have_service_enabled_in_zone('ssh', 'public') }

    # Consul
    it { should have_service_enabled_in_zone('consul-dns', 'trusted') }
    it { should have_service_enabled_in_zone('consul-http', 'trusted') }
    it { should have_service_enabled_in_zone('consul-serf-lan', 'trusted') }
    it { should have_service_enabled_in_zone('consul-serf-wan', 'trusted') }
    it { should have_service_enabled_in_zone('consul-serf-wan', 'public') }
    it { should have_service_enabled_in_zone('consul-sidecar', 'trusted') }
    it { should have_service_enabled_in_zone('consul-expose', 'public') }
    it { should have_service_enabled_in_zone('consul-server', 'public') }
    it { should have_service_enabled_in_zone('consul-grpc', 'public') }
    it { should have_service_enabled_in_zone('dns', 'trusted') }

    # Nomad
    it { should have_service_enabled_in_zone('http', 'public') }
    it { should have_service_enabled_in_zone('https', 'public') }
    it { should have_service_enabled_in_zone('nomad-http', 'public') }
    it { should have_service_enabled_in_zone('nomad-serf', 'internal') }
    it { should have_service_enabled_in_zone('nomad-serf', 'trusted') }
    it { should have_service_enabled_in_zone('nomad-grpc', 'trusted') }
  end

  describe firewalld.where { zone == 'internal' } do
    it 'should include the Linode private IP range' do
      addresses = subject.sources.flatten
      expect(addresses).to include '192.168.128.0/17'
    end
  end

  describe firewalld.where { zone == 'trusted' } do
    it 'should have ipset:consul in its sources' do
      expect(subject.sources.flatten).to include 'ipset:consul'
    end
  end

  describe.one do
    describe file('/usr/etc/firewalld/ipsets/consul.xml') do
      it { should exist }
    end
    describe file('/usr/lib/firewalld/ipsets/consul.xml') do
      it { should exist }
    end
  end
end

control 'hashistack-1.4c' do
  impact 0.7
  title 'automated access'
  desc 'Provide automated provisioner access via a less obvious account than root'

  describe user(ssh_user) do
    it { should exist }
  end

  describe directory("/home/#{ssh_user}/.ssh") do
    it { should exist }
    its('owner') { should eq ssh_user }
    its('group') { should eq ssh_user }
    its('mode') { should eq 0o700 }
  end

  describe file("/home/#{ssh_user}/.ssh/authorized_keys") do
    it { should exist }
    its('owner') { should eq ssh_user }
    its('group') { should eq ssh_user }
    its('mode') { should eq 0o600 }
  end

  describe parse_config_file('/etc/sudoers', { assignment_regex: /^\s*([^\s#]*?)\s+([^#]*?)[\s#]*$/ }) do
    its(ssh_user) { should include 'NOPASSWD' }
  end
end
