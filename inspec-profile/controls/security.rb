# copyright: 2020, David Alexander

ssh_port = ENV.fetch('SSH_PORT')

control 'hashistack-1.2' do
  impact 1.0
  title 'Configure SSH'
  desc ''

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

control 'hashistack-1.3' do
  impact 1.0
  title 'Configure Firewall'
  desc ''

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
    it { should have_service_enabled_in_zone('dns', 'internal') }

    # Nomad
    it { should have_service_enabled_in_zone('http', 'public') }
    it { should have_service_enabled_in_zone('https', 'public') }
    it { should have_service_enabled_in_zone('nomad', 'internal') }
    it { should have_service_enabled_in_zone('nomad', 'trusted') }
  end

  describe firewalld.where { zone == 'trusted' } do
    it 'should include the Linode private IP range' do
      addresses = subject.sources.flatten
      expect(addresses).to include '192.168.128.0/17'
    end
  end
end
