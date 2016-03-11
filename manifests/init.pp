# == Class: tweaks
#
# Linux Server related tweaks.
#
class tweaks (
  $fix_access_to_alsa          = false,
  $fix_haldaemon               = false,
  $fix_localscratch            = false,
  $fix_localscratch_path       = '/local/scratch',
  $fix_messages_permission     = false,
  $fix_services                = false,
  $fix_services_services       = 'USE_DEFAULTS',
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

# convert stringified booleans for fix_localscratch
  if is_bool($fix_localscratch) {
    $fix_localscratch_real = $fix_localscratch
  } else {
    $fix_localscratch_real = str2bool($fix_localscratch)
  }

# create localscratch path and permissions
  if ( $fix_localscratch_real == true ) {
    case "${::osfamily}-${::lsbmajdistrelease}" {
      'Suse-10', 'Suse-11', 'Suse-12', 'RedHat-5', 'RedHat-6', 'RedHat-7': {
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
      'Suse-10', 'Suse-11', 'Suse-12', 'RedHat-5', 'RedHat-6', 'RedHat-7': {
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
        $fix_services_services_default = [
          'acpid',
          'avahi-daemon',
          'bluez-coldplug',
          'boot.open-iscsi',
          'fbset',
          'libvirtd',
          'microcode.ctl',
          'namcd',
          'network-remotefs',
          'smartd',
          'smbfs',
          'splash',
          'splash_early',
          'xdm',
        ]
      }
      'Suse-10': {
        $fix_services_services_default = [
          'acpid',
          'avahi-daemon',
          'fbset',
          'hotkey-setup',
          'microcode',
          'namcd',
          'owcimomd',
          'powersaved',
          'smartd',
          'smbfs',
          'splash',
          'splash_early',
          'suse-blinux',
          'xdm',
        ]
      }
      'RedHat-5': {
        $fix_services_services_default = [
          'abrtd',
          'acpid',
          'avahi-daemon',
          'bluez-coldplug',
          'boot.open-iscsi',
          'fbset',
          'hotkey-setup',
          'libvirtd',
          'microcode.ctl',
          'namcd',
          'network-remotefs',
          'novell-iprint-listener',
          'owcimomd',
          'powersaved',
          'smartd',
          'smbfs',
          'splash',
          'splash_early',
          'suse-blinux',
          'xdm',
        ]
      }
      'RedHat-6': {
        $fix_services_services_default = [
          'abrtd',
          'acpid',
          'avahi-daemon',
          'bluez-coldplug',
          'boot.open-iscsi',
          'fbset',
          'hotkey-setup',
          'libvirtd',
          'microcode.ctl',
          'namcd',
          'network-remotefs',
          'novell-iprint-listener',
          'owcimomd',
          'powersaved',
          'smartd',
          'smbfs',
          'splash',
          'splash_early',
          'suse-blinux',
          'xdm',
        ]
      }
      default: {
        fail('fix_services is only supported on RedHat 5&6, Suse 10&11.')
      }
    }

    $fix_services_services_real = $fix_services_services ? {
      'USE_DEFAULTS' => $fix_services_services_default,
      default        => $fix_services_services
    }
    validate_array($fix_services_services_real)

    ensure_resource('service', $fix_services_services_real, {'enable' => false})
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
      'Suse-10', 'Suse-11', 'Suse-12', 'RedHat-5', 'RedHat-6', 'RedHat-7': {
        file_line { 'swappiness':
          ensure => present,
          path   => '/proc/sys/vm/swappiness',
          line   => $fix_swappiness_value,
          match  => "^${fix_swappiness_value}$",
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
          file_line { 'fix_systohc_for_vm':
            ensure => present,
            path   => '/etc/sysconfig/clock',
            line   => 'SYSTOHC="no"',
            match  => '^SYSTOHC\=',
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
      'Suse-10', 'Suse-11', 'Suse-12': {
        file_line { 'fix_updatedb':
          ensure => present,
          path   => '/etc/sysconfig/locate',
          line   => 'RUN_UPDATEDB=no',
          match  => '^RUN_UPDATEDB\=',
        }
      }
      default: {
        fail('fix_updatedb is only supported on Suse.')
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
          content => template('tweaks/xinetd_d_echo.erb'),
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
