# == Class: ltscore
#
# Linux Terminal Server related tweaks.
#
class ltscore (
  $fix_access_to_alsa          = false,
  $fix_haldaemon               = false,
#  $fix_interval_ssh            = true,
  $fix_localscratch            = false,
  $fix_localscratch_path       = '/local/scratch',
  $fix_messages_permission     = false,
  $fix_services                = false,
  $fix_swappiness              = false,
  $fix_swappiness_value        = '30',
  $fix_systohc_for_vm          = false,
  $fix_updatedb                = false,
  $fix_xinetd                  = false,
) {

  validate_absolute_path($fix_localscratch_path)

# convert stringified booleans for fix_access_to_alsa
  if is_bool($fix_access_to_alsa) {
    $fix_access_to_alsa_real = $fix_access_to_alsa
  }
  else {
    $fix_access_to_alsa_real = str2bool($fix_access_to_alsa)
  }

# Make sure ALSA device is accessible for all users
  if ( $fix_access_to_alsa_real == true ) {
    case "${::osfamily}-${::lsbmajdistrelease}" {
      'Suse-10', 'Suse-11': {
        exec { 'fix_access_to_alsa':
          command => 'sed -i \'s#NAME="snd/%k".*$#NAME="snd/%k",MODE="0666"#\' /etc/udev/rules.d/40-alsa.rules',
          path    => '/bin:/usr/bin',
          unless  => 'test -f /etc/udev/rules.d/40-alsa.rules && grep "snd.*0666" /etc/udev/rules.d/40-alsa.rules',
        }
      }
      default: {
        fail('fix_access_to_alsa is only supported on Suse 10&11.')
      }
    }
  }

# convert stringified booleans for fix_haldaemon
  if is_bool($fix_haldaemon) {
    $fix_haldaemon_real = $fix_haldaemon
  }
  else {
    $fix_haldaemon_real = str2bool($fix_haldaemon)
  }

# Added ensure => running, for haldaemon
  if $fix_haldaemon_real == true {
    case "${::osfamily}-${::lsbmajdistrelease}" {
      'Suse-11': {
        service { 'haldaemon':
          ensure => running,
          enable => true,
        }
        exec { 'fix_haldaemon':
          command => 'sed -i \'/^HALDAEMON_BIN/a CPUFREQ="no"\' /etc/init.d/haldaemon',
          path    => '/bin:/usr/bin',
          unless  => 'grep CPUFREQ /etc/init.d/haldaemon',
          notify  => Service['haldaemon'],
        }
      }
      default: {
        fail('fix_haldaemon is only supported on Suse 11.')
      }
    }
  }

# Handled by ssh module
#  if ($fix_interval_ssh == true ) and ("${::operatingsystem}${::lsbmajdistrelease}" =~ /SLES11|SLED11/ ) {
#    exec { 'echo "ServerAliveInterval 240" >> /etc/ssh/ssh_config' :
#      path => '/bin:/usr/bin:',
#      unless => "grep ServerAliveInterval /etc/ssh/ssh_config",
#    }
#  }

# convert stringified booleans for fix_localscratch
  if is_bool($fix_localscratch) {
    $fix_localscratch_real = $fix_localscratch
  } else {
    $fix_localscratch_real = str2bool($fix_localscratch)
  }

# Puppet has a 'bug' on directory creation. When the parent directory is not existed, Puppet will report error.
# If you changed $fix_localscratchpath, please read following pages first.
# http://www.puppetcookbook.com/posts/creating-a-directory.html
# http://www.puppetcookbook.com/posts/creating-a-directory-tree.html
# https://projects.puppetlabs.com/issues/86
# Update 2014.12.01: Fixed by common::mkdir_p from Garrett Honeycutt
  if ( $fix_localscratch_real == true ) {
    case "${::osfamily}-${::lsbmajdistrelease}" {
      'Suse-10', 'Suse-11', 'RedHat-5', 'RedHat-6': {
        common::mkdir_p { $fix_localscratch_path: }

        file { 'fix_localscratch_path':
          ensure  => directory,
          path    => $fix_localscratch_path,
          owner   => 'root',
          group   => 'root',
          mode    => '1777',
          require => Common::Mkdir_p[$fix_localscratch_path],
        }
      }
      default: {
        fail('fix_localscratch is only supported on RedHat 5&6, Suse 10&11.')
      }
    }
  }

# convert stringified booleans for fix_messages_permission
  if is_bool($fix_messages_permission) {
    $fix_messages_permission_real = $fix_messages_permission
  } else {
    $fix_messages_permission_real = str2bool($fix_messages_permission)
  }

# Set /var/log/messages to 0644
  if $fix_messages_permission_real == true {
    case "${::osfamily}-${::lsbmajdistrelease}" {
      'Suse-10', 'Suse-11', 'RedHat-5', 'RedHat-6': {
        file { '/var/log/messages' :
          mode => '0644',
        }
      }
      default: {
        fail('fix_messages_permission is only supported on RedHat 5&6, Suse 10&11.')
      }
    }
  }

# convert stringified booleans for fix_services
  if is_bool($fix_services) {
    $fix_services_real = $fix_services
  } else {
    $fix_services_real = str2bool($fix_services)
  }

# Disable services on Suse and RedHat
  if $fix_services_real == true {
    case "${::osfamily}-${::lsbmajdistrelease}" {
      'Suse-11': {
        $disableservices = [ 'microcode.ctl', 'smartd',
          'boot.open-iscsi', 'libvirtd',
          'acpid', 'namcd', 'smbfs',
          'splash', 'avahi-daemon', 'bluez-coldplug',
          'fbset', 'network-remotefs', 'xdm',
          'splash_early' ]
      }
      'Suse-10': {
        $disableservices = [ 'smartd', 'owcimomd',
          'powersaved',
          'acpid', 'namcd', 'smbfs',
          'splash', 'avahi-daemon',
          'fbset', 'xdm',
          'suse-blinux', 'microcode',
          'splash_early', 'hotkey-setup' ]
      }
      'RedHat-5': {
        $disableservices = [ 'owcimomd', 'microcode.ctl', 'smartd',
          'boot.open-iscsi', 'libvirtd', 'powersaved',
          'acpid', 'namcd', 'smbfs',
          'splash', 'avahi-daemon', 'bluez-coldplug',
          'fbset', 'network-remotefs', 'xdm',
          'splash_early',
          'hotkey-setup', 'suse-blinux',
          'novell-iprint-listener', 'abrtd' ]
      }
      'RedHat-6': {
        $disableservices = [ 'owcimomd', 'microcode.ctl', 'smartd',
          'boot.open-iscsi', 'libvirtd', 'powersaved',
          'acpid', 'namcd', 'smbfs',
          'splash', 'avahi-daemon', 'bluez-coldplug',
          'fbset', 'network-remotefs', 'xdm',
          'splash_early',
          'hotkey-setup', 'suse-blinux',
          'novell-iprint-listener', 'abrtd' ]
      }
      default: {
        $disableservices = []
      }
    }

    case "${::osfamily}-${::lsbmajdistrelease}" {
      'Suse-10', 'Suse-11', 'RedHat-5', 'RedHat-6': {
        service { $disableservices :
          enable => false,
        }
      }
      default: {
        fail('fix_services is only supported on RedHat 5&6, Suse 10&11.')
      }
    }
  }

# convert stringified booleans for fix_swappiness
  if is_bool($fix_swappiness) {
    $fix_swappiness_real = $fix_swappiness
  } else {
    $fix_swappiness_real = str2bool($fix_swappiness)
  }

# Default value for fix_swappiness is 30
  if $fix_swappiness_real == true {
    case "${::osfamily}-${::lsbmajdistrelease}" {
      'Suse-10', 'Suse-11', 'RedHat-5', 'RedHat-6': {
        exec { 'swappiness':
          command => "/bin/echo ${fix_swappiness_value} > /proc/sys/vm/swappiness",
          path    => '/bin:/usr/bin',
          unless  => "/bin/grep '^${fix_swappiness_value}$' /proc/sys/vm/swappiness",
        }
      }
      default: {
        fail('fix_swappiness is only supported on RedHat 5&6, Suse 10&11.')
      }
    }
  }

# $::is_virtual == 'true' works.  $::is_virtual == true not work. Because it's a 'fact'.
# So convert stringified $::is_virtual to booleans $is_virtual_real
# convert stringified booleans for is_virtual
  if is_bool($::is_virtual) {
    $is_virtual_real = $::is_virtual
  } else {
    $is_virtual_real = str2bool( $::is_virtual )
  }

# convert stringified booleans for fix_systohc_for_vm
  if is_bool($fix_systohc_for_vm) {
    $fix_systohc_for_vm_real = $fix_systohc_for_vm
  } else {
    $fix_systohc_for_vm_real = str2bool($fix_systohc_for_vm)
  }

  if ( $fix_systohc_for_vm_real == true ) {
    if ( $is_virtual_real == true ) {
      case "${::osfamily}-${::lsbmajdistrelease}" {
        'Suse-10', 'Suse-11': {
          exec { 'fix_systohc_for_vm' :
            command => 'sed -i \'s/SYSTOHC=.*yes.*/SYSTOHC="no"/\' /etc/sysconfig/clock',
            path    => '/bin:/usr/bin',
            onlyif  => 'grep SYSTOHC=.*yes.* /etc/sysconfig/clock',
          }
        }
        default: {
          fail('fix_systohc_for_vm is only supported on Suse 10&11 Virtual Machine.')
        }
      }
    }
    else {
      fail('fix_systohc_for_vm is only supported on Suse 10&11 Virtual Machine.')
    }
  }

# convert stringified booleans for fix_updatedb
  if is_bool($fix_updatedb) {
    $fix_updatedb_real = $fix_updatedb
  } else {
    $fix_updatedb_real = str2bool($fix_updatedb)
  }

# Disable updatedb in /etc/sysconfig/locate
  if ( $fix_updatedb_real == true ) {
    case "${::osfamily}-${::lsbmajdistrelease}" {
      'Suse-10', 'Suse-11': {
        exec { 'fix_updatedb':
          command => 'sed -i \'s/RUN_UPDATEDB=.*yes.*/RUN_UPDATEDB=no/\' /etc/sysconfig/locate',
          path    => '/bin:/usr/bin',
          onlyif  => 'grep RUN_UPDATEDB=.*yes.* /etc/sysconfig/locate',
        }
      }
      default: {
        fail('fix_updatedb is only supported on Suse 10&11.')
      }
    }
  }

# convert stringified booleans for fix_xinetd
  if is_bool($fix_xinetd) {
    $fix_xinetd_real = $fix_xinetd
  } else {
    $fix_xinetd_real = str2bool($fix_xinetd)
  }

#Fix xinetd service
  if $fix_xinetd_real == true {
    case "${::osfamily}-${::lsbmajdistrelease}" {
      'Suse-10', 'Suse-11', 'RedHat-5', 'RedHat-6': {
        package { 'xinetd':
          ensure => 'installed',
          before => 'File[/etc/xinetd.d/echo]',
        }
        file { '/etc/xinetd.d/echo':
          ensure  => 'file',
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          content => template('ltscore/xinetd_d_echo.erb'),
          notify  => 'Exec[fix_xinetd]',
        }
        exec { 'fix_xinetd':
          command     => '/sbin/service xinetd restart',
          refreshonly => true,
        }
      }
      default: {
        fail('fix_xinetd is only supported on RedHat 5&6, Suse 10&11.')
      }
    }
  }
}
