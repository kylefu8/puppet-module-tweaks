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
  case $fix_access_to_alsa {
    'true', 'false': {
      $fix_access_to_alsa_real = str2bool($fix_access_to_alsa)
    }
    true, false: {
      $fix_access_to_alsa_real = $fix_access_to_alsa
    }
    default:{
      fail("str2bool():")
    }
  }

# Make sure ALSA device is accessible for all users
  if ( $fix_access_to_alsa_real == true ) and ( $::osfamily == 'Suse' ) {
    exec { 'fix_access_to_alsa':
      command => 'sed -i \'s#NAME="snd/%k".*$#NAME="snd/%k",MODE="0666"#\' /etc/udev/rules.d/40-alsa.rules',
      path    => '/bin:/usr/bin',
      unless  => 'test -f /etc/udev/rules.d/40-alsa.rules && grep "snd.*0666" /etc/udev/rules.d/40-alsa.rules',
    }
  }

# convert stringified booleans for fix_haldaemon
  case $fix_haldaemon {
    'true', 'false': {
      $fix_haldaemon_real = str2bool($fix_haldaemon)
    }
    true, false: {
      $fix_haldaemon_real = $fix_haldaemon
    }
    default:{
      fail("str2bool():")
    }
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
        fail("fix_haldaemon is only supported on Suse 11")
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
  if is_string($fix_localscratch) == false {
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
  if $fix_localscratch_real == true {
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

# convert stringified booleans for fix_messages_permission
  if is_string($fix_messages_permission) == false {
    $fix_messages_permission_real = $fix_messages_permission
  } else {
    $fix_messages_permission_real = str2bool($fix_messages_permission)
  }

# Set /var/log/messages to 0644
  if $fix_messages_permission_real == true {
    file { '/var/log/messages' :
      mode => '0644',
    }
  }

# convert stringified booleans for fix_services
  if is_string($fix_services) == false {
    $fix_services_real = $fix_services
  } else {
    $fix_services_real = str2bool($fix_services)
  }

# Disable services on Suse and Redhat
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
        fail( "Can not handle ${::osfamily}-${::lsbmajdistrelease}. Only support RedHat 5&6, Suse 10&11." )
      }
    }

    service { $disableservices :
      enable => false,
    }
  }

# convert stringified booleans for fix_swappiness
  if is_string($fix_swappiness) == false {
    $fix_swappiness_real = $fix_swappiness
  } else {
    $fix_swappiness_real = str2bool($fix_swappiness)
  }

# Default value for fix_swappiness is 30
  if $fix_swappiness_real == true {
    exec { 'swappiness':
      command => "/bin/echo ${fix_swappiness_value} > /proc/sys/vm/swappiness",
      path    => '/bin:/usr/bin',
      unless  => "/bin/grep '^${fix_swappiness_value}$' /proc/sys/vm/swappiness",
    }
  }

# $::is_virtual == 'true' works.  $::is_virtual == true not work. Because it's a 'fact'.
# So convert stringified $::is_virtual to booleans $is_virtual_real
  if is_string($::is_virtual) == false {
    $is_virtual_real = $::is_virtual
  } else {
    $is_virtual_real = str2bool( $::is_virtual )
  }

# convert stringified booleans for fix_systohc_for_vm
  if is_string($fix_systohc_for_vm) == false {
    $fix_systohc_for_vm_real = $fix_systohc_for_vm
  } else {
    $fix_systohc_for_vm_real = str2bool($fix_systohc_for_vm)
  }

  if ( $fix_systohc_for_vm_real == true ) and ( $::osfamily == 'Suse' ) and ( $is_virtual_real == true ) {
    exec { 'fix_systohc_for_vm' :
      command => 'sed -i \'s/SYSTOHC=.*yes.*/SYSTOHC="no"/\' /etc/sysconfig/clock',
      path    => '/bin:/usr/bin',
      onlyif  => 'grep SYSTOHC=.*yes.* /etc/sysconfig/clock',
    }
  }

# convert stringified booleans for fix_updatedb
  if is_string($fix_updatedb) == false {
    $fix_updatedb_real = $fix_updatedb
  } else {
    $fix_updatedb_real = str2bool($fix_updatedb)
  }

# Disable updatedb in /etc/sysconfig/locate
  if ( $fix_updatedb_real == true ) and ( $::osfamily == 'Suse' ) {
    exec { 'fix_updatedb':
      command => 'sed -i \'s/RUN_UPDATEDB=.*yes.*/RUN_UPDATEDB=no/\' /etc/sysconfig/locate',
      path    => '/bin:/usr/bin',
      onlyif  => 'grep RUN_UPDATEDB=.*yes.* /etc/sysconfig/locate',
    }
  }

# convert stringified booleans for fix_xinetd
  if is_string($fix_xinetd) == false {
    $fix_xinetd_real = $fix_xinetd
  } else {
    $fix_xinetd_real = str2bool($fix_xinetd)
  }

#Fix xinetd service
  if $fix_xinetd_real == true {
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

}

