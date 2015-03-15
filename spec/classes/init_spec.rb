require 'spec_helper'
describe 'ltscore' do
  context 'When fix_access_to_alsa set to true' do
    let(:params) { { :fix_access_to_alsa => 'true' } }
    let(:facts) { { :osfamily => 'Suse' } }
    it do
      should contain_exec('fix_access_to_alsa').with({
        'command' => 'sed -i \'s#NAME="snd/%k".*$#NAME="snd/%k",MODE="0666"#\' /etc/udev/rules.d/40-alsa.rules',
        'path'    => '/bin:/usr/bin',
        'unless'  => 'test -f /etc/udev/rules.d/40-alsa.rules && grep "snd.*0666" /etc/udev/rules.d/40-alsa.rules',
      })
    end
  end

  context 'When fix_haldaemon set to true, and osfamily == Suse, lsbmajdistrelease == 11' do
    let(:params) { { :fix_haldaemon => 'true' } }
    let :facts do
      { :osfamily => 'Suse',
        :lsbmajdistrelease => '11',
      }
    end
    it do
      should contain_service('haldaemon').with({
      'ensure' => 'running',
      'enable' => 'true',
      })
    end
    it do
      should contain_exec('fix_haldaemon').with({
      'command' => 'sed -i \'/^HALDAEMON_BIN/a CPUFREQ="no"\' /etc/init.d/haldaemon',
      'path'    => '/bin:/usr/bin',
      'unless'  => 'grep CPUFREQ /etc/init.d/haldaemon',
      'notify'  => 'Service[haldaemon]',
      })
    end
  end

  context 'When fix_localscratch set to true' do
    let :params do
      { :fix_localscratch => 'true',
      }
  end
    it do
      should contain_file('fix_localscratch_path').with({
        'ensure'  => 'directory',
        'path'    => '/local/scratch',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '1777',
        'require' => 'Common::Mkdir_p[/local/scratch]',
      })
    end
  end

  context 'When fix_localscratch set to true, fix_localscratch_path set to /local/test' do
    let :params do
      { :fix_localscratch => 'true',
        :fix_localscratch_path => '/local/test'
      }
  end
    it do
      should contain_file('fix_localscratch_path').with({
        'ensure'  => 'directory',
        'path'    => '/local/test',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '1777',
        'require' => 'Common::Mkdir_p[/local/test]',
      })
    end
  end

  context 'When fix_xinetd set to true' do
    let(:params) { { :fix_xinetd => 'true' } }
    it do
      should contain_package('xinetd').with_ensure('installed')
    end
    it do
      should contain_file('/etc/xinetd.d/echo')
    end
    it do
      should contain_file('/etc/xinetd.d/echo').with({
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
      })
    end
  end
end

