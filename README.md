# tweaks module #
===

Collocation of Linux system tweaks. 
Former name is ltscore.

===

# Compatibility #

Puppet v3 with Ruby 1.8.7 and 1.9.3

## OS Distributions ##

This module is supported on the following systems with Puppet v3 and Ruby 1.8.7, 1.9.3, 2.0.0 and 2.1.0.

* EL 5
* EL 6
* EL 7
* Suse 10
* Suse 11
* Suse 12

===

# Parameters #

fix_access_to_alsa (boolean)
----------------------------
Access MODE of ALSA device will be set to 0666 to make sure they are accessible for all users if it's true.
It only affects to Suse.
Nothing will happen with /etc/udev/rules.d/40-alsa.rules if it's false.

- *Default*: false

fix_haldaemon (boolean)
-----------------------
Add the "CPUFREQ=no" line in /etc/sysconfig/haldaemon and make sure service haldaemon is running if it's true.
It only affects to Suse 11.
Nothing will happen with /etc/sysconfig/haldaemon if it's false.

- *Default*: false

fix_localscratch (boolean)
--------------------------
Create local scratch folder if it's true.
Nothing will happen with local scratch folder if it's false.

- *Default*: false

fix_localscratch_path (string)
------------------------------
Path to local scratch.

- *Default*: '/local/scratch'

fix_messages_permission (boolean)
---------------------------------
Make sure the mode of /var/log/messages is 0644 if it's true.
Nothing will happen with /var/log/messages if it's false.

- *Default*: false

fix_services (boolean)
----------------------
Disable useless services based on the osfamily. (nfs service is removed from this disable list.)
It only affects to Suse 10&11, EL 5&6.
Nothing will happen with those services if it's false.

- *Default*: false

fix_services_services (array)
-----------------------------
Array of service names to disable when fix_services is activated. 'USE_DEFAULTS' will choose the appropriate default for the used OS.

- *Default*: 'USE_DEFAULTS'

fix_swappiness (boolean)
------------------------
Set parameter that controls the relative weight given to swapping out runtime memory if it's true.

- *Default*: false

fix_swappiness_value (string)
-----------------------------
Set parameter that controls the relative weight given to swapping out runtime memory.
The value will be set into /proc/sys/vm/swappiness directly.

- *Default*: '30'

fix_systohc_for_vm (boolean)
----------------------------
Disable hardware clock to the current system time if it's true.
It only affects to Suse virtual machine.
Nothing will happen with /etc/sysconfig/clock if it's false.

- *Default*: false

fix_updatedb (boolean)
----------------------
Set "RUN_UPDATEDB=no" in /etc/sysconfig/locate if it's true.
Updatedb cronjob in cron.daily will be disabled when "RUN_UPDATEDB=no".
It only affects to Suse.
Nothing will happen with /etc/sysconfig/locate if it's false.

- *Default*: false

fix_xinetd (boolean)
--------------------
Xinetd will be fixed (install package, configure /etc/xinetd.d/echo) if it's true.
Nothing will happen with xinetd if it's false.

- *Default*: false
