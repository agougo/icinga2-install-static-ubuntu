# icinga2-install-static-ubuntu
The purpose of this repo is to automate the creation of a full blown Icinga2 Master server for *testing* purposes.

### Pre-requisites  

/ Install Git  
/ The scripts have only been tested on an Ubuntu v24.04 standard installation  
/ The Database backend is PostgreSQL  
/ The locale of your server needs to be set to locale=en-US - if not change it, or modify the psql commands accordingly  
/ You need to bring your own TLS certificates. In this installation a self signed is generated.

### How to Install  

/ Login as root  
/ Clone the repo in the root home folder  
```
# apt install git -y
# git clone https://github.com/agougo/icinga2-install-static-ubuntu.git
# mv icinga2-install-static-ubuntu icinga2prodinstallation
```

/ Probably a good idea to make scripts executable  
```
# cd icinga2prodinstallation
# chmod +x *.sh
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

### After the configure-ubuntu-modules.sh script  

You should have the following modules installed:  

/ Icinga Business Process Modeling -> https://icinga.com/docs/icinga-business-process-modeling/latest/doc/01-About/  
/ Map module for Icinga Web 2 -> https://github.com/nbuchwitz/icingaweb2-module-map  
/ Location datatype module for Icinga Director -> https://github.com/nbuchwitz/icingaweb2-module-mapDatatype  
/ Icinga Web 2 Fileshipper module -> https://icinga.com/docs/icinga-director/latest/fileshipper/doc/04-FileShipping/  
/ Icinga PDF Export -> https://github.com/Icinga/icingaweb2-module-pdfexport  
/ Icinga Reporting -> https://icinga.com/docs/icinga-reporting/latest/doc/02-Installation/  
/ Icinga Cube -> https://icinga.com/docs/icinga-cube/latest/  
/ Audit module for Icinga Web 2 -> https://icinga.com/docs/icinga-web/latest/doc/15-Auditing/  
/ Icinga Certificate Monitoring -> https://icinga.com/docs/icinga-certificate-monitoring/latest/doc/01-About/  
/ Icinga Web 2 - Enforced Dashboard -> https://github.com/Thomas-Gelf/icingaweb2-module-enforceddashboard  
/ icingaweb2-module-perfdatagraphs -> https://github.com/NETWAYS/icingaweb2-module-perfdatagraphs  

If everything was executed you can change into my theme ... or not ... and you should have a running installation.

### Grafana  

Grafana is also installed on the same server. You can access it on https://IP_ADDRESS:3000  

In the Grafana folder you will find a dashboard to import. If you wish you can also add it as a Menu item on the left menu by clicking on your username at the bottom left -> Navigation -> Create a New Navigation Item  

### [TO DO]

/ Move from InfluxDB v1 to InfluxDB v2  
/ Structure Grafana a bit better  
/ Test the Grafana module by Netways

### Support

Questions are welcome but other than that there is no support for this. Take it or leave it.

