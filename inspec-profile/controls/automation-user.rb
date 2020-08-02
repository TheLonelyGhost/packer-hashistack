ssh_user = ENV.fetch('ENTRY_USER')
# ssh_pubkey = ENV.fetch('ENTRY_USER_PUBKEY')

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
