# icinga2-install-static-ubuntu
The purpose of this repo is to automate the creation of a full blown Icinga2 Master server for *testing* purposes.

### Pre-requisites  

/ Install Git
/ The scripts have only been tested on an Ubuntu v24.04 standard installation  
/ The locale of your server needs to be set to locale=en-US - if not change it, or modify the psql commands accordingly

### How to Install  

/ Login as root  
/ Clone the repo in the root home folder  
```
# apt install git -y
# git clone https://github.com/agougo/icinga2-install-static-ubuntu.git
# mv icinga2-install-static-ubuntu icinga2prodinstallation
```
/ run the following scripts in that order
```
# configure-ubuntu.sh
# configure-ubuntu-director.sh
# configure-ubuntu-modules.sh
```

> **<ins>Note</ins>:** Pause between the execution of the scripts and perform the configuration needed as shown below.  

### After the configure-ubuntu.sh script  

/ Open your Icingaweb2 interface at https://IP_ADDRESS/icingaweb2  
/ Initialize by following the instructions here -> [Click](install/configure-ubuntu.adoc)  

### After the configure-ubuntu-director.sh script  

/ Navigate to the director menu and configure it like this -> [Click](install/configure-ubuntu-director.adoc)