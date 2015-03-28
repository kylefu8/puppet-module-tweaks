# ltscore module #

===

# Compatibility #

Puppet v3 with Ruby 1.8.7 and 1.9.3

## OS Distributions ##

This module has been tested to work on the following systems.

* EL 5
* EL 6
* Suse 10
* Suse 11

## Function support matrix ##
#FunctionMatrix           EL-5  EL-6  Suse-10  Suse-11  Others
#fix_access_to_alsa       -     -     *        *        -
#fix_haldaemon            -     -     -        *        -
#fix_localscratch         *     *     *        *        -
#fix_messages_permission  *     *     *        *        -
#fix_services             *     *     *        *        -
#fix_swappiness           *     *     *        *        -
#fix_systohc_for_vm       -     -     *        *        -
#fix_updatedb             -     -     *        *        -
#fix_xinetd               *     *     *        *        -

===

# Parameters #

fix_access_to_alsa
------------------
Access MODE of ALSA device will be set to 0666 to make sure they are accessible for all users if it's true.
It only affects to Suse.
Nothing will happen with /etc/udev/rules.d/40-alsa.rules if it's false.

- *Default*: true

fix_haldaemon
------------------
Add the "CPUFREQ=no" line in /etc/sysconfig/haldaemon and make sure service haldaemon is running if it's true. 
It only affects to Suse 11.
Nothing will happen with /etc/sysconfig/haldaemon if it's false.

- *Default*: true

fix_localscratch
------------------
Create local scratch folder if it's true.
Nothing will happen with local scratch folder if it's false.

- *Default*: true

fix_localscratch_path
-----------------
Puppet has a 'bug' on directory creation. When the parent directory is not existed, Puppet will report error.
If you changed the path, please read following pages first.
http://www.puppetcookbook.com/posts/creating-a-directory.html
http://www.puppetcookbook.com/posts/creating-a-directory-tree.html
https://projects.puppetlabs.com/issues/86
Update 2014.12.01: Fixed by common::mkdir_p from Garrett Honeycutt

- *Default*: /local/scratch

fix_messages_permission
------------------
Make sure the mode of /var/log/messages is 0644 if it's true.
Nothing will happen with /var/log/messages if it's false.

- *Default*: true

fix_services
------------------
Disable useless services based on the osfamily. (nfs service is removed from this disable list.)
It only affects to Suse 10&11, EL 5&6.
Nothing will happen with those services if it's false.

- *Default*: true

fix_swappiness
------------------
Set parameter that controls the relative weight given to swapping out runtime memory if it's true.

- *Default*: true

fix_swappiness_value
------------------
Set parameter that controls the relative weight given to swapping out runtime memory.
The value will be set into /proc/sys/vm/swappiness directly.

- *Default*: 30

fix_systohc_for_vm
------------------
Disable hardware clock to the current system time if it's true. 
It only affects to Suse virtual machine.
Nothing will happen with /etc/sysconfig/clock if it's false.

- *Default*: true

fix_updatedb
------------------
Set "RUN_UPDATEDB=no" in /etc/sysconfig/locate if it's true. 
Updatedb cronjob in cron.daily will be disabled when "RUN_UPDATEDB=no".
It only affects to Suse.
Nothing will happen with /etc/sysconfig/locate if it's false.

- *Default*: true

fix_xinetd
-----------------
Xinetd will be fixed(install package, configure /etc/xinetd.d/echo) if it's true.
Nothing will happen with xinetd if it's false.

- *Default*: true


