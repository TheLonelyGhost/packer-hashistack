# copyright: 2020, David Alexander

control 'hashistack-1.1a' do
  impact 0.7
  title 'Nomad'
  desc 'Install Nomad with barebones configuration'

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
