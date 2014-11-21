class ltscore (
  $_xinetd_type                = 'INTERNAL',
  $_xinetd_id                  = 'echo-stream',
  $_xinetd_socket_type         = 'stream',
  $_xinetd_protocol            = 'tcp',
  $_xinetd_user                = 'root',
  $_xinetd_wait                = 'no',
  $_xinetd_flags               = 'IPv6 IPv4',
  $fix_xinetd                  = true,
  $localscratch                = true,
  $localscratch_path           = '/local/scratch',
  $fix_messages_permission     = true,
#  $fix_interval_ssh            = true,
  $disable_systohc_for_vm      = true,
  $set_swappiness              = '30',
  $fix_haldaemon               = true,
  $fix_updatedb                = true,
  $disable_services            = true,
  $fix_access_to_alsa          = true,
) {


#Fix xinetd service
  if $fix_xinetd == true {
    package { 'xinetd':
      ensure => 'installed',
      before => 'File[/etc/xinetd.d/echo]',
    }
    file { '/etc/xinetd.d/echo':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("ltscore/xinetd_d_echo.erb"),
      notify  => 'Exec[fix_xinetd]',
    }
    exec { 'fix_xinetd':
      command     => '/sbin/service xinetd restart',
      refreshonly => true,
    }
  }

# Puppet has a 'bug' on directory creation. When the parent directory is not existed, Puppet will report error. 
# If you changed $localscratchpath, please read following pages first.
# http://www.puppetcookbook.com/posts/creating-a-directory.html
# http://www.puppetcookbook.com/posts/creating-a-directory-tree.html
# https://projects.puppetlabs.com/issues/86
  if $localscratch == true {
    if ($localscratch_path == '/local/scratch') {
      file { '/local':
        ensure => directory,
        mode   => '0755',
      }
      file { '/local/scratch':
        ensure => directory,
        mode   => '1777',
      }
    }
    else {
      file { $localscratch_path :
        ensure => directory,
        mode => 1777,
      }
    }
  }

  if $fix_messages_permission == true {
    file { '/var/log/messages' :
      mode => '0644',
    }
  }

# Handled by ssh module
#  if ($fix_interval_ssh == true ) and ("${::operatingsystem}${::lsbmajdistrelease}" =~ /SLES11|SLED11/ ) {
#    exec { 'echo "ServerAliveInterval 240" >> /etc/ssh/ssh_config' :
#      path => '/bin:/usr/bin:',
#      unless => "grep ServerAliveInterval /etc/ssh/ssh_config",
#    }
#  }

# $::is_virtual == 'true' works.  $::is_virtual == true not work. Because it's a 'fact'.
  if ( $disable_systohc_for_vm == true ) and ( $::osfamily == 'Suse' ) and ( $::is_virtual == 'true' ) {
    exec { 'disable_systohc_for_vm' :
      command => 'sed -i \'s/SYSTOHC=.*yes.*/SYSTOHC="no"/\' /etc/sysconfig/clock',
      path => '/bin:/usr/bin',
      onlyif => "grep SYSTOHC=.*yes.* /etc/sysconfig/clock",
    }
  }

# Default value for set_swappiness is 30
  if $set_swappiness != false {
    exec { 'swappiness':
      command => "/bin/echo ${set_swappiness} > /proc/sys/vm/swappiness",
      path    => '/bin:/usr/bin',
      unless  => "/bin/grep '^${set_swappiness}$' /proc/sys/vm/swappiness",
    }
  }

# Added ensure => running, for haldaemon
  if ( $fix_haldaemon == true ) and ( $::osfamily == 'Suse' ) and ( $::lsbmajdistrelease == '11' ) {
    service { 'haldaemon':
      enable => true,
      ensure => running,
    }
    exec { 'fix_haldaemon':
      command => 'sed -i \'/^HALDAEMON_BIN/a CPUFREQ="no"\' /etc/init.d/haldaemon',
      path    => '/bin:/usr/bin',
      unless  => 'grep CPUFREQ /etc/init.d/haldaemon',
      notify  => Service['haldaemon'],
    }
  }

# Disable updatedb in /etc/sysconfig/locate
  if ( $fix_updatedb == true ) and ( $::osfamily == 'Suse' ) {
    exec { 'fix_updatedb':
      command => 'sed -i \'s/RUN_UPDATEDB=.*yes.*/RUN_UPDATEDB=no/\' /etc/sysconfig/locate',
      path    => '/bin:/usr/bin',
      onlyif  => 'grep RUN_UPDATEDB=.*yes.* /etc/sysconfig/locate',
    }
  }

# Disable services on Suse and Redhat
  if $disable_services == true {
    if ( $::osfamily == 'Suse' ) and ( $::lsbmajdistrelease == '11' ) {
      $disableservices = [ 'microcode.ctl', 'smartd',
        'boot.open-iscsi', 'libvirtd',
        'acpid', 'namcd', 'smbfs',
        'splash', 'avahi-daemon', 'bluez-coldplug',
        'fbset', 'network-remotefs', 'xdm',
        'splash_early' ]
    } elsif ( $::osfamily == 'Suse' ) and ( $::lsbmajdistrelease == '10' ) {
      $disableservices = [ 'smartd', 'owcimomd',
        'powersaved',
        'acpid', 'namcd', 'smbfs',
        'splash', 'avahi-daemon',
        'fbset', 'xdm',
        'suse-blinux', 'microcode',
        'splash_early', 'hotkey-setup' ]
    } elsif ( $::osfamily == 'RedHat' ) and ( $::lsbmajdistrelease == '5' )  {
      $disableservices = [ 'owcimomd', 'microcode.ctl', 'smartd',
        'boot.open-iscsi', 'libvirtd', 'powersaved',
        'acpid', 'namcd', 'smbfs',
        'splash', 'avahi-daemon', 'bluez-coldplug',
        'fbset', 'network-remotefs', 'xdm',
        'splash_early', 
        'hotkey-setup', 'suse-blinux',
        'novell-iprint-listener', 'abrtd' ]
    } elsif ( $::osfamily == 'RedHat' ) and ( $::lsbmajdistrelease == '6' ) {
      $disableservices = [ 'owcimomd', 'microcode.ctl', 'smartd',
        'boot.open-iscsi', 'libvirtd', 'powersaved',
        'acpid', 'namcd', 'smbfs',
        'splash', 'avahi-daemon', 'bluez-coldplug',
        'fbset', 'network-remotefs', 'xdm',
        'splash_early', 
        'hotkey-setup', 'suse-blinux',
        'novell-iprint-listener', 'abrtd' ]
    } else {
      fail( "Can not handle ${::osfamily}${::lsbmajdistrelease}" )
    }
  
    service { $disableservices :
      enable => false,
    }
  }

# Make sure ALSA device is accessible for all users
  if ( $fix_access_to_alsa == true ) and ( $::osfamily == 'Suse' ) {
    exec { 'fix_access_to_alsa':
      command => 'sed -i \'s#NAME="snd/%k".*$#NAME="snd/%k",MODE="0666"#\' /etc/udev/rules.d/40-alsa.rules',
      path    => '/bin:/usr/bin',
      unless  => 'test -f /etc/udev/rules.d/40-alsa.rules && grep "snd.*0666" /etc/udev/rules.d/40-alsa.rules',
    }
  }

}
