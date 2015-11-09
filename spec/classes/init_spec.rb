require 'spec_helper'
describe 'tweaks' do

  describe 'with default values for all parameters' do
    it { should compile.with_all_deps }
    it { should contain_class('tweaks')}
    it { should have_resource_count(0) }
  end

  fixes = {
    'RedHat-5' => {
      :os => 'RedHat',  :rel => '5', :access_to_alsa => false,  :haldaemon => false, :localscratch => true,  :messages_permission => true,  :services => true,  :swappiness => true,  :systohc_for_vm => false, :updatedb => false, :xinetd => true,
      :servicelist => [ 'abrtd', 'acpid', 'avahi-daemon', 'bluez-coldplug', 'boot.open-iscsi', 'fbset', 'hotkey-setup', 'libvirtd', 'microcode.ctl', 'namcd', 'network-remotefs', 'novell-iprint-listener', 'owcimomd', 'powersaved', 'smartd', 'smbfs', 'splash', 'splash_early', 'suse-blinux', 'xdm', ],
    },
    'RedHat-6' => {
      :os => 'RedHat',  :rel => '6', :access_to_alsa => false,  :haldaemon => false, :localscratch => true,  :messages_permission => true,  :services => true,  :swappiness => true,  :systohc_for_vm => false, :updatedb => false, :xinetd => true,
      :servicelist => [ 'abrtd', 'acpid', 'avahi-daemon', 'bluez-coldplug', 'boot.open-iscsi', 'fbset', 'hotkey-setup', 'libvirtd', 'microcode.ctl', 'namcd', 'network-remotefs', 'novell-iprint-listener', 'owcimomd', 'powersaved', 'smartd', 'smbfs', 'splash', 'splash_early', 'suse-blinux', 'xdm', ],
    },
    'Suse-10' =>  {
      :os => 'Suse',    :rel => '10', :access_to_alsa => true,  :haldaemon => false, :localscratch => true,  :messages_permission => true,  :services => true,  :swappiness => true,  :systohc_for_vm => true,  :updatedb => true,  :xinetd => true,
      :servicelist => [ 'acpid', 'avahi-daemon', 'fbset', 'hotkey-setup', 'microcode', 'namcd', 'owcimomd', 'powersaved', 'smartd', 'smbfs', 'splash', 'splash_early', 'suse-blinux', 'xdm', ],
    },
    'Suse-11' =>  {
      :os => 'Suse',    :rel => '11', :access_to_alsa => true,  :haldaemon => true,  :localscratch => true,  :messages_permission => true,  :services => true,  :swappiness => true,  :systohc_for_vm => true,  :updatedb => true,  :xinetd => true,
      :servicelist => [ 'acpid', 'avahi-daemon', 'bluez-coldplug', 'boot.open-iscsi', 'fbset', 'libvirtd', 'microcode.ctl', 'namcd', 'network-remotefs', 'smartd', 'smbfs', 'splash', 'splash_early', 'xdm', ],
    },
    # not existing OS
    'WierdOS-12' =>  {
      :os => 'WierdOS', :rel => '12', :access_to_alsa => false, :haldaemon => false, :localscratch => false, :messages_permission => false, :services => false, :swappiness => false, :systohc_for_vm => false, :updatedb => false, :xinetd => false,
      :servicelist => [],
      },
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
          if value.to_s == 'true' and v[:access_to_alsa] == true
            it do
              should contain_exec('fix_access_to_alsa').with({
                'command' => 'sed -i \'s#NAME="snd/%k".*$#NAME="snd/%k",MODE="0666"#\' /etc/udev/rules.d/40-alsa.rules',
                'path'    => '/bin:/usr/bin',
                'unless'  => 'test -f /etc/udev/rules.d/40-alsa.rules && grep "snd.*0666" /etc/udev/rules.d/40-alsa.rules',
              })
            end
          elsif value.to_s == 'false'
            it do
              should_not contain_exec('fix_access_to_alsa')
            end
          else
            it 'should fail' do
              expect {
                should contain_class('tweaks')
              }.to raise_error(Puppet::Error,/fix_access_to_alsa is only supported on Suse 10\&11./)
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
          if value.to_s == 'true' and v[:haldaemon] == true
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
          elsif value.to_s == 'false'
            it do
              should_not contain_service('haldaemon')
            end
            it do
              should_not contain_exec('fix_haldaemon')
            end
          else
            it 'should fail' do
              expect {
                should contain_class('tweaks')
              }.to raise_error(Puppet::Error,/fix_haldaemon is only supported on Suse 11./)
            end
          end
        end
      end
# </fix_haldaemon functionality & stringified bools handling>

# <fix_localscratch functionality & stringified bools handling>
      [true,'true',false,'false'].each do |value|
        context "with fix_localscratch set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_localscratch => value,
            }
          end
          if value.to_s == 'true' and v[:localscratch] == true
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
          elsif value.to_s == 'false'
            it do
              should_not contain_file('fix_localscratch_path')
            end
          else
            it 'should fail' do
              expect {
                should contain_class('tweaks')
              }.to raise_error(Puppet::Error,/fix_localscratch is only supported on RedHat 5\&6, Suse 10\&11./)
            end
          end
        end
      end

      [true,'true',false,'false'].each do |value|
        context "with fix_localscratch set to valid #{value} (as #{value.class}), and fix_localscratch_path set to /local/test" do
          let :params do
            { :fix_localscratch => value,
              :fix_localscratch_path => '/local/test',
            }
          end
          if value.to_s == 'true' and v[:localscratch] == true
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
          elsif value.to_s == 'false'
            it do
              should_not contain_file('fix_localscratch_path')
            end
          else
            it 'should fail' do
              expect {
                should contain_class('tweaks')
              }.to raise_error(Puppet::Error,/fix_localscratch is only supported on RedHat 5\&6, Suse 10\&11./)
            end
          end
        end
      end
# </fix_localscratch functionality & stringified bools handling>

# <fix_messages_permission functionality & stringified bools handling>
      [true,'true',false,'false'].each do |value|
        context "with fix_messages_permission set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_messages_permission => value,
            }
          end
          if value.to_s == 'true' and v[:messages_permission] == true
            it do
              should contain_file('/var/log/messages').with({
                'mode'    => '0644',
              })
            end
          elsif value.to_s == 'false'
            it do
              should_not contain_file('/var/log/messages')
            end
          else
            it 'should fail' do
              expect {
                should contain_class('tweaks')
              }.to raise_error(Puppet::Error,/fix_messages_permission is only supported on RedHat 5\&6, Suse 10\&11./)
            end
          end
        end
      end
# </fix_messages_permission functionality & stringified bools handling>

# <fix_services functionality & stringified bools handling>
      [true,'true',false,'false'].each do |value|
        context "with fix_services set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_services => value,
            }
          end
          if value.to_s == 'true' and v[:services] == true
            v[:servicelist].each do |srv|
              it {
                should contain_service(srv).with({
                  'enable' => false,
                })
              }
            end
          elsif value.to_s == 'false'
            v[:servicelist].each do |srv|
              it {
                should_not contain_service(srv).with({
                  'enable' => false,
                })
              }
            end
          else
            it 'should fail' do
              expect {
                should contain_class('tweaks')
              }.to raise_error(Puppet::Error, /fix_services is only supported on RedHat 5\&6, Suse 10\&11./ )
            end
          end
        end
      end
# </fix_services functionality & stringified bools handling>

# <fix_swappiness functionality & stringified bools handling>
      [true,'true',false,'false'].each do |value|
        context "with fix_swappiness set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_swappiness => value,
            }
          end
          if value.to_s == 'true' and v[:localscratch] == true
            it do
              should contain_exec('swappiness').with({
                'command' => "/bin/echo 30 > /proc/sys/vm/swappiness",
                'path'    => '/bin:/usr/bin',
                'unless'  => "/bin/grep '^30$' /proc/sys/vm/swappiness",
              })
            end
          elsif value.to_s == 'false'
            it do
              should_not contain_exec('swappiness')
            end
          else
            it 'should fail' do
              expect {
                should contain_class('tweaks')
              }.to raise_error(Puppet::Error,/fix_swappiness is only supported on RedHat 5\&6, Suse 10\&11./)
            end
          end
        end
      end

      [true,'true',false,'false'].each do |value|
        context "with fix_swappiness set to valid #{value} (as #{value.class}), and fix_swappiness_value set to 60" do
          let :params do
            { :fix_swappiness => value,
              :fix_swappiness_value => 60,
            }
          end
          if value.to_s == 'true' and v[:localscratch] == true
            it do
              should contain_exec('swappiness').with({
                'command' => "/bin/echo 60 > /proc/sys/vm/swappiness",
                'path'    => '/bin:/usr/bin',
                'unless'  => "/bin/grep '^60$' /proc/sys/vm/swappiness",
              })
            end
          elsif value.to_s == 'false'
            it do
              should_not contain_exec('swappiness')
            end
          else
            it 'should fail' do
              expect {
                should contain_class('tweaks')
              }.to raise_error(Puppet::Error,/fix_swappiness is only supported on RedHat 5\&6, Suse 10\&11./)
            end
          end
        end
      end
# </fix_swappiness functionality & stringified bools handling>

# <fix_systohc_for_vm functionality & stringified bools handling>
      [true,'true',false,'false'].each do |value|
        context "with fix_systohc_for_vm set to valid #{value} (as #{value.class})" do
          [true,'true',false,'false'].each do |value_virtual|
            context "with is_virtual set to valid #{value_virtual} (as #{value_virtual.class})" do
              let :facts do
                { :osfamily          => v[:os],
                  :lsbmajdistrelease => v[:rel],
                  :is_virtual => value_virtual,
                }
              end
              let :params do
                { :fix_systohc_for_vm => value,
                }
              end
              if value.to_s == 'true' and v[:systohc_for_vm] == true
                if value_virtual.to_s == 'true'
                  it do
                    should contain_exec('fix_systohc_for_vm').with({
                      'command' => 'sed -i \'s/SYSTOHC=.*yes.*/SYSTOHC="no"/\' /etc/sysconfig/clock',
                      'path'    => '/bin:/usr/bin',
                      'onlyif'  => 'grep SYSTOHC=.*yes.* /etc/sysconfig/clock',
                    })
                  end
                else
                  it 'should fail' do
                    expect {
                      should contain_class('tweaks')
                    }.to raise_error(Puppet::Error,/fix_systohc_for_vm is only supported on Suse 10\&11 Virtual Machine./)
                  end
                end
              elsif value.to_s == 'false'
                it do
                  should_not contain_exec('fix_systohc_for_vm')
                end
              else
                it 'should fail' do
                  expect {
                    should contain_class('tweaks')
                  }.to raise_error(Puppet::Error,/fix_systohc_for_vm is only supported on Suse 10\&11 Virtual Machine./)
                end
              end
            end
          end
        end
      end
# </fix_systohc_for_vm functionality & stringified bools handling>

# <fix_updatedb functionality & stringified bools handling>
      [true,'true',false,'false'].each do |value|
        context "with fix_updatedb set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_updatedb => value,
            }
          end
          if value.to_s == 'true' and v[:updatedb] == true
            it do
              should contain_exec('fix_updatedb').with({
                'command' => 'sed -i \'s/RUN_UPDATEDB=.*yes.*/RUN_UPDATEDB=no/\' /etc/sysconfig/locate',
                'path'    => '/bin:/usr/bin',
                'onlyif'  => 'grep RUN_UPDATEDB=.*yes.* /etc/sysconfig/locate',
              })
            end
          elsif value.to_s == 'false'
            it do
              should_not contain_exec('fix_updatedb')
            end
          else
            it 'should fail' do
              expect {
                should contain_class('tweaks')
              }.to raise_error(Puppet::Error,/fix_updatedb is only supported on Suse 10\&11./)
            end
          end
        end
      end
# </fix_updatedb functionality & stringified bools handling>

# <fix_xinetd functionality & stringified bools handling>
      [true,'true',false,'false'].each do |value|
        context "with fix_xinetd set to valid #{value} (as #{value.class})" do
          echo_fixture = File.read(fixtures("xinetd_d_echo"))
          let :params do
            { :fix_xinetd => value,
            }
          end
          if value.to_s == 'true' and v[:xinetd] == true
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
              should contain_file('/etc/xinetd.d/echo').with_content(echo_fixture)
              should contain_exec('fix_xinetd').with({
                'command'     => '/sbin/service xinetd restart',
                'refreshonly' => true,
              })
            end
          elsif value.to_s == 'false'
            it do
              should_not contain_package('xinetd')
            end
            it do
              should_not contain_file('/etc/xinetd.d/echo')
            end
            it do
              should_not contain_exec('fix_xinetd')
            end
          else
            it 'should fail' do
              expect {
                should contain_class('tweaks')
              }.to raise_error(Puppet::Error,/fix_xinetd is only supported on RedHat 5&6, Suse 10\&11./)
            end
          end
        end
      end
# </fix_xinetd functionality & stringified bools handling>

    end
  end

# <fix_services_services functionality & invalid type handling>
      describe 'with fix_services_services set to valid array on supported OS' do
        let(:facts) { {
          :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        } }
        let(:params) { {
          :fix_services          => true,
          :fix_services_services => ['stop','service'],
        } }
        ['stop','service'].each do |service|
          it { should contain_service(service).with_enable('false') }
        end
      end

      ['invalid',true,nil,3,2.42,a={'ha'=>'sh'}].each do |service|
        context "with fix_services_services set to invalid #{service} (as #{service.class}) on supported OS" do
          let(:params) { {
            :fix_services          => true,
            :fix_services_services => service,
          } }

          it 'should fail' do
            expect {
              should contain_class(subject)
            }.to raise_error(Puppet::Error,/is not an Array/)
          end
        end
      end
# </fix_services_services functionality & invalid type handling>

# should fail on invalid types tests
  ['invalid',3,2.42,['array'],a = { 'ha' => 'sh' }].each do |value|
# <fix_access_to_alsa should fail on invalid types>
    context "When fix_access_to_alsa set to invalid #{value} (as #{value.class}) on supported OS" do
      let (:params) { { :fix_access_to_alsa => value } }
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end

      it 'should fail' do
        expect {
          should contain_class('tweaks')
        }.to raise_error(Puppet::Error, /str2bool/)
      end
    end
# </fix_access_to_alsa should fail on invalid types>

# <fix_haldaemon should fail on invalid types>
    context "When fix_haldaemon set to invalid #{value} (as #{value.class}) on supported OS" do
      let (:params) { { :fix_haldaemon => value } }
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end

      it 'should fail' do
        expect {
          should contain_class('tweaks')
        }.to raise_error(Puppet::Error, /str2bool/)
      end
    end
# </fix_haldaemon should fail on invalid types>

# <fix_localscratch should fail on invalid types>
    context "When fix_localscratch set to invalid #{value} (as #{value.class}) on supported OS" do
      let (:params) { { :fix_localscratch => value } }
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end

      it 'should fail' do
        expect {
          should contain_class('tweaks')
        }.to raise_error(Puppet::Error, /str2bool/)
      end
    end
# </fix_localscratch should fail on invalid types>

# <fix_messages_permission should fail on invalid types>
    context "When fix_messages_permission set to invalid #{value} (as #{value.class}) on supported OS" do
      let (:params) { { :fix_messages_permission => value } }
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end

      it 'should fail' do
        expect {
          should contain_class('tweaks')
        }.to raise_error(Puppet::Error, /str2bool/)
      end
    end
# </fix_messages_permission should fail on invalid types>

# <fix_services should fail on invalid types>
    context "When fix_services set to invalid #{value} (as #{value.class}) on supported OS" do
      let (:params) { { :fix_services => value } }
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end

      it 'should fail' do
        expect {
          should contain_class('tweaks')
        }.to raise_error(Puppet::Error, /str2bool/)
      end
    end
# </fix_services should fail on invalid types>

# <fix_swappiness should fail on invalid types>
    context "When fix_swappiness set to invalid #{value} (as #{value.class}) on supported OS" do
      let (:params) { { :fix_swappiness => value } }
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end

      it 'should fail' do
        expect {
          should contain_class('tweaks')
        }.to raise_error(Puppet::Error, /str2bool/)
      end
    end
# </fix_swappiness should fail on invalid types>

# <fix_systohc_for_vm should fail on invalid types>
    context "When fix_systohc_for_vm set to invalid #{value} (as #{value.class}) on supported OS" do
      let (:params) { { :fix_systohc_for_vm => value } }
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end

      it 'should fail' do
        expect {
          should contain_class('tweaks')
        }.to raise_error(Puppet::Error, /str2bool/)
      end
    end
# </fix_systohc_for_vm should fail on invalid types>

# <fix_updatedb should fail on invalid types>
    context "When fix_updatedb set to invalid #{value} (as #{value.class}) on supported OS" do
      let (:params) { { :fix_updatedb => value } }
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end

      it 'should fail' do
        expect {
          should contain_class('tweaks')
        }.to raise_error(Puppet::Error, /str2bool/)
      end
    end
# </fix_updatedb should fail on invalid types>

# <fix_xinetd should fail on invalid types>
    context "When fix_xinetd set to invalid #{value} (as #{value.class}) on supported OS" do
      let (:params) { { :fix_xinetd => value } }
      let :facts do
        { :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
        }
      end

      it 'should fail' do
        expect {
          should contain_class('tweaks')
        }.to raise_error(Puppet::Error, /str2bool/)
      end
    end
# </fix_xinetd should fail on invalid types>
  end

end
