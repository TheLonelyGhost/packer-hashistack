# copyright: 2020, David Alexander

ssh_user = ENV.fetch('ENTRY_USER')
ssh_pubkey = ENV.fetch('ENTRY_USER_PUBKEY')
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

  describe firewalld do
    it { should be_running }
    it { should have_service_enabled_in_zone('ssh', 'public') }
  end
end

control 'hashistack-1.3' do
  impact 1.0
  title 'Configure Firewall'
  desc ''

  describe firewalld do
    it { should be_running }
    its('default_zone') { should eq 'public' }
  end

  describe firewalld.where { zone == 'trusted' } do
    # Include Linode private IP space
    its('sources') { should include '192.168.128.0/17' }
  end
end

control 'hashistack-1.4' do
  impact 0.7
  title 'Create an automation user'
  desc 'Once remote access to the root account is shut off, another door should be opened'

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
