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
      :os => 'Suse',    :rel => '11', :access_to_alsa => true,  :haldaemon => true,  :localscratch => true,  :messages_permission => true,  :services => true,  :swappiness => true,  :systohc_for_vm => true,  :updatedb => false, :xinetd => true,
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

      # <fix_access_to_alsa functionality>
      [true,false].each do |value|
        context "with fix_access_to_alsa set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_access_to_alsa => value,
            }
          end
          if value == true and v[:access_to_alsa] == true
            it do
              should contain_exec('fix_access_to_alsa').with({
                'command' => 'sed -i \'s#NAME="snd/%k".*$#NAME="snd/%k",MODE="0666"#\' /etc/udev/rules.d/40-alsa.rules',
                'path'    => '/bin:/usr/bin',
                'unless'  => 'test -f /etc/udev/rules.d/40-alsa.rules && grep "snd.*0666" /etc/udev/rules.d/40-alsa.rules',
              })
            end
          elsif value == false
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
      # </fix_access_to_alsa functionality>

      # <fix_haldaemon functionality>
      [true,false].each do |value|
        context "with fix_haldaemon set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_haldaemon => value,
            }
          end
          if value == true and v[:haldaemon] == true
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
          elsif value == false
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
      # </fix_haldaemon functionality>

      # <fix_localscratch functionality>
      [true,false].each do |value|
        context "with fix_localscratch set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_localscratch => value,
            }
          end
          if value == true and v[:localscratch] == true
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
          elsif value == false
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

      [true,false].each do |value|
        context "with fix_localscratch set to valid #{value} (as #{value.class}), and fix_localscratch_path set to /local/test" do
          let :params do
            { :fix_localscratch => value,
              :fix_localscratch_path => '/local/test',
            }
          end
          if value == true and v[:localscratch] == true
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
          elsif value == false
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
      # </fix_localscratch functionality>

      # <fix_messages_permission functionality>
      [true,false].each do |value|
        context "with fix_messages_permission set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_messages_permission => value,
            }
          end
          if value == true and v[:messages_permission] == true
            it do
              should contain_file('/var/log/messages').with({
                'mode'    => '0644',
              })
            end
          elsif value == false
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
      # </fix_messages_permission functionality>

      # <fix_services functionality>
      [true,false].each do |value|
        context "with fix_services set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_services => value,
            }
          end
          if value == true and v[:services] == true
            v[:servicelist].each do |srv|
              it {
                should contain_service(srv).with({
                  'enable' => false,
                })
              }
            end
          elsif value == false
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
      # </fix_services functionality>

      # <fix_swappiness functionality>
      [true,false].each do |value|
        context "with fix_swappiness set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_swappiness => value,
            }
          end
          if value == true and v[:localscratch] == true
            it do
              should contain_file_line('swappiness').with({
                'ensure' => 'present',
                'path'   => '/proc/sys/vm/swappiness',
                'line'   => '30',
                'match'  => '^30$',
              })
            end
          elsif value == false
            it do
              should_not contain_file_line('swappiness')
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

      [true,false].each do |value|
        context "with fix_swappiness set to valid #{value} (as #{value.class}), and fix_swappiness_value set to 60" do
          let :params do
            { :fix_swappiness => value,
              :fix_swappiness_value => 60,
            }
          end
          if value == true and v[:localscratch] == true
            it do
              should contain_file_line('swappiness').with({
                'ensure' => 'present',
                'path'   => '/proc/sys/vm/swappiness',
                'line'   => '60',
                'match'  => '^60$',
              })
            end
          elsif value == false
            it do
              should_not contain_file_line('swappiness')
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
      # </fix_swappiness functionality>

      # <fix_systohc_for_vm functionality>
      [true,false].each do |value|
        context "with fix_systohc_for_vm set to valid #{value} (as #{value.class})" do
          [true,'true',false,'false'].each do |value_virtual|
            context "with is_virtual set to valid #{value_virtual} (as #{value_virtual.class})" do
              let :facts do
                { :osfamily          => v[:os],
                  :lsbmajdistrelease => v[:rel],
                  :is_virtual        => value_virtual,
                }
              end
              let :params do
                { :fix_systohc_for_vm => value,
                }
              end
              if value == true and v[:systohc_for_vm] == true
                if value_virtual.to_s == 'true'
                  it do
                    should contain_file_line('fix_systohc_for_vm').with({
                      'ensure' => 'present',
                      'path'   => '/etc/sysconfig/clock',
                      'line'   => 'SYSTOHC="no"',
                      'match'  => '^SYSTOHC\=',
                    })
                  end
                else
                  it 'should fail' do
                    expect {
                      should contain_class('tweaks')
                    }.to raise_error(Puppet::Error,/fix_systohc_for_vm is only supported on Suse 10\&11 Virtual Machine./)
                  end
                end
              elsif value == false
                it do
                  should_not contain_file_line('fix_systohc_for_vm')
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
      # </fix_systohc_for_vm functionality>

      # <fix_updatedb functionality>
      [true,false].each do |value|
        context "with fix_updatedb set to valid #{value} (as #{value.class})" do
          let :params do
            { :fix_updatedb => value,
            }
          end
          if value == true and v[:updatedb] == true
            it do
              should contain_file_line('fix_updatedb').with({
                'ensure' => 'present',
                'path'   => '/etc/sysconfig/locate',
                'line'   => 'RUN_UPDATEDB=no',
                'match'  => '^RUN_UPDATEDB\=',
              })
            end
          elsif value == false
            it do
              should_not contain_file_line('fix_updatedb')
            end
          else
            it 'should fail' do
              expect {
                should contain_class('tweaks')
              }.to raise_error(Puppet::Error,/fix_updatedb is only supported on Suse 10/)
            end
          end
        end
      end
      # </fix_updatedb functionality>

      # <fix_xinetd functionality>
      [true,false].each do |value|
        context "with fix_xinetd set to valid #{value} (as #{value.class})" do
          echo_fixture = File.read(fixtures("xinetd_d_echo"))
          let :params do
            { :fix_xinetd => value,
            }
          end
          if value == true and v[:xinetd] == true
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
          elsif value == false
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
      # </fix_xinetd functionality>
    end
  end

  # <fix_services_services functionality>
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
  # </fix_services_services functionality>

  describe 'variable type and content validations' do
    # set needed custom facts and variables
    let(:facts) do
      {
        :osfamily          => 'Suse',
        :lsbmajdistrelease => '11',
        # needed to test fix_systohc_for_vm
        :is_virtual        => true,
      }
    end
    let(:validation_params) do
      {
        # needed to test fix_services_services
        :fix_services => true,
      }
    end

    validations = {
      'absolute_path' => {
        :name    => %w(fix_localscratch_path),
        :valid   => %w(/absolute/filepath /absolute/directory/),
        :invalid => ['../invalid', 3, 2.42, %w(array), { 'ha' => 'sh' }, true, false, nil],
        :message => 'is not an absolute path',
      },
      'array' => {
        :name    => %w(fix_services_services),
        :valid   => [%w(ar ray)],
        :invalid => ['invalid', { 'ha' => 'sh' }, 3, 2.42, true, false, nil],
        :message => 'is not an Array',
      },
      'bool_stringified' => {
        :name    => %w(fix_access_to_alsa fix_haldaemon fix_localscratch fix_messages_permission fix_services fix_swappiness fix_systohc_for_vm fix_xinetd),
        :valid   => [true, false, 'true', 'false'],
        :invalid => ['invalid', %w(array), { 'ha' => 'sh' }, 3, 2.42],
        :message => '(Unknown type of boolean|str2bool\(\): Requires either string to work with)',
      },
    }

    validations.sort.each do |type, var|
      var[:name].each do |var_name|
        var[:valid].each do |valid|
          context "with #{var_name} (#{type}) set to valid #{valid} (as #{valid.class})" do
            let(:params) { validation_params.merge({ :"#{var_name}" => valid, }) }
            it { should compile }
          end
        end

        var[:invalid].each do |invalid|
          context "with #{var_name} (#{type}) set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { validation_params.merge({ :"#{var_name}" => invalid, }) }
            it 'should fail' do
              expect do
                should contain_class(subject)
              end.to raise_error(Puppet::Error, /#{var[:message]}/)
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'

  describe 'variable type and content validations for Suse-10 specific functionality' do
    # fix_updatedb is only valid on Suse-10, so we need a Suse-10 specific section :(
    let(:facts) do
      {
        :osfamily          => 'Suse',
        :lsbmajdistrelease => '10',
      }
    end
    let(:validation_params) do
      {
        # not needed
      }
    end

    validations_suse10 = {
      'bool_stringified' => {
        :name    => %w(fix_updatedb),
        :valid   => [true, false, 'true', 'false'],
        :invalid => ['invalid', %w(array), { 'ha' => 'sh' }, 3, 2.42],
        :message => '(Unknown type of boolean|str2bool\(\): Requires either string to work with)',
      },
    }

    validations_suse10.sort.each do |type, var|
      var[:name].each do |var_name|
        var[:valid].each do |valid|
          context "with #{var_name} (#{type}) set to valid #{valid} (as #{valid.class})" do
            let(:params) { validation_params.merge({ :"#{var_name}" => valid, }) }
            it { should compile }
          end
        end

        var[:invalid].each do |invalid|
          context "with #{var_name} (#{type}) set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { validation_params.merge({ :"#{var_name}" => invalid, }) }
            it 'should fail' do
              expect do
                should contain_class(subject)
              end.to raise_error(Puppet::Error, /#{var[:message]}/)
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
