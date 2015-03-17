require 'spec_helper'
describe 'ltscore' do

  fixes = {
    'RedHat-5' => { :os => 'RedHat', :rel => '5',  :access_to_alsa => false, :haldaemon => false, :services => true, :systohc_for_vm => false, :updatedb => false, },
    'RedHat-6' => { :os => 'RedHat', :rel => '6',  :access_to_alsa => false, :haldaemon => false, :services => true, :systohc_for_vm => false, :updatedb => false, },
    'Suse-10' =>  { :os => 'Suse',   :rel => '10', :access_to_alsa => true,  :haldaemon => false, :services => true, :systohc_for_vm => true,  :updatedb => true, },
    'Suse-11' =>  { :os => 'Suse',   :rel => '11', :access_to_alsa => true,  :haldaemon => true,  :services => true, :systohc_for_vm => true,  :updatedb => true, },
    }

  fixes.sort.each do |k,v|
    describe "When OS is #{k}" do
      let :facts do
        { :osfamily          => v[:os],
          :lsbmajdistrelease => v[:rel],
        }
      end

# <fix_access_to_alsa functionality & stringified bools handling>
      [true,'true',false,'false'].each do |value|
        context "with fix_access_to_alsa set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_access_to_alsa => value,
            }
          end
          if ( value == true or value == 'true' ) and v[:access_to_alsa] == true
            it do
              should contain_exec('fix_access_to_alsa').with({
                'command' => 'sed -i \'s#NAME="snd/%k".*$#NAME="snd/%k",MODE="0666"#\' /etc/udev/rules.d/40-alsa.rules',
                'path'    => '/bin:/usr/bin',
                'unless'  => 'test -f /etc/udev/rules.d/40-alsa.rules && grep "snd.*0666" /etc/udev/rules.d/40-alsa.rules',
              })
            end
          else
            it do
              should_not contain_exec('fix_access_to_alsa')
            end
          end
        end
      end
# </fix_access_to_alsa functionality & stringified bools handling>

# <fix_haldaemon functionality & stringified bools handling>
      [true,'true',false,'false'].each do |value|
        context "with fix_haldaemon set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_haldaemon => value,
            }
          end
          if ( value == true or value == 'true' ) and v[:haldaemon] == true
            it do
              should contain_service('haldaemon').with({
              'ensure' => 'running',
              'enable' => 'true',
              })
              should contain_exec('fix_haldaemon').with({
              'command' => 'sed -i \'/^HALDAEMON_BIN/a CPUFREQ="no"\' /etc/init.d/haldaemon',
              'path'    => '/bin:/usr/bin',
              'unless'  => 'grep CPUFREQ /etc/init.d/haldaemon',
              'notify'  => 'Service[haldaemon]',
              })
            end
          else
            it do
              should_not contain_service('haldaemon')
            end
            it do
              should_not contain_exec('fix_haldaemon')
            end
          end
        end
      end
# </fix_haldaemon functionality & stringified bools handling>

    end
  end


# <fix_access_to_alsa should fail on invalid types>
  ['invalid',3,2.42,['array'],a = { 'ha' => 'sh' }].each do |value|
    context "When fix_access_to_alsa set to invalid #{value} (as #{value.class}) on supported OS" do
      let (:params) { { :fix_access_to_alsa => value } }
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end

      it 'should fail' do
        expect {
          should
        }.to raise_error(Puppet::Error, /^str2bool\(\):/)
      end
    end
  end
# </fix_access_to_alsa should fail on invalid types>

# <fix_access_to_alsa should fail on invalid types>
  ['invalid',3,2.42,['array'],a = { 'ha' => 'sh' }].each do |value|
    context "When fix_access_to_alsa set to invalid #{value} (as #{value.class}) on supported OS" do
      let (:params) { { :fix_haldaemon => value } }
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end

      it 'should fail' do
        expect {
          should
        }.to raise_error(Puppet::Error, /^str2bool\(\):/)
      end
    end
  end
# </fix_access_to_alsa should fail on invalid types>

  context 'When fix_localscratch set to true' do
    let (:params) { { :fix_localscratch => true } }
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
      { :fix_localscratch => true,
        :fix_localscratch_path => '/local/test',
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

  context 'When fix_messages_permission set to true' do
    let (:params) { { :fix_messages_permission => true } }
    it do
      should contain_file('/var/log/messages').with({
        'mode'    => '0644',
      })
    end
  end

#Services
  platforms = {
    'Suse-10' =>
      { :osfamily => 'Suse',
        :release  => '10',
        :services => [ 'smartd', 'owcimomd', 'powersaved', 'acpid',
      'namcd', 'smbfs', 'splash', 'avahi-daemon', 'fbset', 'xdm',
          'suse-blinux', 'microcode', 'splash_early', 'hotkey-setup' ],
      },
    'Suse-11' =>
      { :osfamily => 'Suse',
        :release  => '11',
        :services => [ 'microcode.ctl', 'smartd', 'boot.open-iscsi',
      'libvirtd', 'acpid', 'namcd', 'smbfs', 'splash', 'avahi-daemon',
      'bluez-coldplug', 'fbset', 'network-remotefs', 'xdm', 'splash_early' ],
      },
    'RedHat-5' =>
      { :osfamily => 'RedHat',
        :release  => '5',
        :services => [ 'owcimomd', 'microcode.ctl', 'smartd',
          'boot.open-iscsi', 'libvirtd', 'powersaved', 'acpid', 'namcd',
          'smbfs', 'splash', 'avahi-daemon', 'bluez-coldplug', 'fbset',
          'network-remotefs', 'xdm', 'splash_early', 'hotkey-setup',
          'suse-blinux', 'novell-iprint-listener', 'abrtd' ],
      },
    'RedHat-6' =>
      { :osfamily => 'RedHat',
        :release  => '6',
        :services => [ 'owcimomd', 'microcode.ctl', 'smartd',
          'boot.open-iscsi', 'libvirtd', 'powersaved', 'acpid', 'namcd',
          'smbfs', 'splash', 'avahi-daemon', 'bluez-coldplug', 'fbset',
          'network-remotefs', 'xdm', 'splash_early', 'hotkey-setup',
          'suse-blinux', 'novell-iprint-listener', 'abrtd' ],
      },
  }

    platforms.sort.each do |k,v|
      context "When fix_services set to true, and OS is #{k}," do
        let (:params) { { :fix_services => true } }
        let :facts do
          { :osfamily          => v[:osfamily],
            :lsbmajdistrelease => v[:release],
          }
        end
        if v[:services].class == Array
          v[:services].each do |srv|
            it {
              should contain_service(srv).with({
                'enable' => false,
              })
            }
          end
        else
          it {
            should contain_service(v[:services]).with({
              'enable' => false,
            })
          }
        end
      end
    end

  context 'When fix_services set to true, but OS is not supported' do
    let (:params) { { :fix_services => true } }
    let :facts do
      { :osfamily          => 'Debian',
        :lsbmajdistrelease => '12',
      }
    end
    it 'should fail' do
      expect {
        should
      }.to raise_error(Puppet::Error, /^Can not handle Debian-12. Only support RedHat 5&6, Suse 10&11./)
    end
  end

  context 'When fix_swappiness set to true' do
    let(:params) { { :fix_swappiness => true } }
    it do
      should contain_exec('swappiness').with({
        'command' => '/bin/echo 30 > /proc/sys/vm/swappiness',
        'path'    => '/bin:/usr/bin',
        'unless'  => '/bin/grep \'^30$\' /proc/sys/vm/swappiness',
      })
    end
  end

  context 'When fix_swappiness set to true, and fix_swappiness_value set to 60' do
    let :params do
      { :fix_swappiness => true,
        :fix_swappiness_value => '60',
      }
    end
    it do
      should contain_exec('swappiness').with({
        'command' => '/bin/echo 60 > /proc/sys/vm/swappiness',
        'path'    => '/bin:/usr/bin',
        'unless'  => '/bin/grep \'^60$\' /proc/sys/vm/swappiness',
      })
    end
  end

  context 'When fix_systohc_for_vm set to true, and osfamily == Suse & is_virtual_real == true' do
    let(:params) { { :fix_systohc_for_vm => 'true' } }
    let :facts do
      { :osfamily => 'Suse',
        :is_virtual => true,
      }
    end
    it do
      should contain_exec('fix_systohc_for_vm').with({
        'command' => 'sed -i \'s/SYSTOHC=.*yes.*/SYSTOHC="no"/\' /etc/sysconfig/clock',
        'path'    => '/bin:/usr/bin',
        'onlyif'  => 'grep SYSTOHC=.*yes.* /etc/sysconfig/clock',
      })
    end
  end

  context 'When fix_updatedb set to true, and osfamily == Suse' do
    let (:params) { { :fix_updatedb => 'true' } }
    let (:facts) { { :osfamily => 'Suse' } }
    it do
      should contain_exec('fix_updatedb').with({
        'command' => 'sed -i \'s/RUN_UPDATEDB=.*yes.*/RUN_UPDATEDB=no/\' /etc/sysconfig/locate',
        'path'    => '/bin:/usr/bin',
        'onlyif'  => 'grep RUN_UPDATEDB=.*yes.* /etc/sysconfig/locate',
      })
    end
  end

  context 'When fix_xinetd set to true' do
    let(:params) { { :fix_xinetd => true } }
    it do
      should contain_package('xinetd').with({
       'ensure' => 'installed',
       'before' => 'File[/etc/xinetd.d/echo]',
      })
    end
    it do
      should contain_file('/etc/xinetd.d/echo').with({
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'notify'  => 'Exec[fix_xinetd]',
      })
      should contain_file('/etc/xinetd.d/echo').with_content(/^# This file is managed by Puppet and any changes may be destroyed.$/)
      should contain_file('/etc/xinetd.d/echo').with_content(/^# description: An echo server. This is the tcp version.$/)
      should contain_file('/etc/xinetd.d/echo').with_content(/^service echo$/)
      should contain_file('/etc/xinetd.d/echo').with_content(/^\{$/)
      should contain_file('/etc/xinetd.d/echo').with_content(/^        type            = INTERNAL$/)
      should contain_file('/etc/xinetd.d/echo').with_content(/^        id              = echo-stream$/)
      should contain_file('/etc/xinetd.d/echo').with_content(/^        socket_type     = stream$/)
      should contain_file('/etc/xinetd.d/echo').with_content(/^        protocol        = tcp$/)
      should contain_file('/etc/xinetd.d/echo').with_content(/^        user            = root$/)
      should contain_file('/etc/xinetd.d/echo').with_content(/^        wait            = no$/)
      should contain_file('/etc/xinetd.d/echo').with_content(/^        FLAGS           = IPv6 IPv4$/)
      should contain_file('/etc/xinetd.d/echo').with_content(/^\}$/)
      should contain_exec('fix_xinetd').with({
        'command'     => '/sbin/service xinetd restart',
        'refreshonly' => true,
      })
    end
  end

end

