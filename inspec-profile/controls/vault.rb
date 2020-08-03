# copyright: 2020, David Alexander

control 'hashistack-1.3a' do
  impact 0.7
  title 'Vault'
  desc 'Install Vault and include barebones configuration'

  describe file('/usr/local/bin/vault') do
    it { should exist }
    it { should be_executable }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    it 'should be in the PATH' do
      expect(command('vault')).to exist
    end
    it 'should have ipc_lock capability' do
      expect(command('getcap /usr/local/bin/vault').stdout).to include 'cap_ipc_lock'
    end
  end

  describe user('vault') do
    it { should exist }
    its('groups') { should_not include 'wheel' }
  end

  describe directory('/etc/vault.d') do
    it { should exist }
    its('owner') { should eq 'vault' }
    its('group') { should eq 'vault' }
    its('mode') { should eq 0o700 }
  end

  describe systemd_service('vault-agent') do
    it { should be_installed }
  end

  describe systemd_service('vault-server') do
    it { should be_installed }
  end
end
