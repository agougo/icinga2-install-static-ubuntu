#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~

# Add InfluxDB
wget https://dl.influxdata.com/influxdb/releases/v1.13.1/influxdb_1.13.1-1_amd64.deb
sudo dpkg -i influxdb_1.13.1-1_amd64.deb
systemctl restart influxdb

# Perfdatagraphs Module
git clone https://github.com/NETWAYS/icingaweb2-module-perfdatagraphs.git
mv icingaweb2-module-perfdatagraphs/ perfdatagraphs
mv perfdatagraphs/ /usr/share/icingaweb2/modules/
git clone https://github.com/NETWAYS/icingaweb2-module-perfdatagraphs-influxdbv1.git
mv icingaweb2-module-perfdatagraphs-influxdbv1/ perfdatagraphsinfluxdbv1
mv perfdatagraphsinfluxdbv1 /usr/share/icingaweb2/modules/

mkdir /etc/icingaweb2/modules/perfdatagraphs
touch /etc/icingaweb2/modules/perfdatagraphs/config.ini
chown www-data:icingaweb2 /etc/icingaweb2/modules/perfdatagraphs/config.ini
echo "[perfdatagraphs]" >> /etc/icingaweb2/modules/perfdatagraphs/config.ini
echo "default_backend = \"InfluxDBv1\"" >> /etc/icingaweb2/modules/perfdatagraphs/config.ini

mkdir /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1
touch /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini
chown www-data:icingaweb2 /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini
echo "[influx]" >> /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini
echo "api_url = \"http://localhost:8086\"" >> /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini
echo "api_database = \"icinga\"" >> /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini
echo "api_tls_insecure = \"0\"" >> /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini

icingacli module enable perfdatagraphs
icingacli module enable perfdatagraphsinfluxdbv1

# TODO
# Install Promethus as a back end for perfdata

cd ~
cd icinga2prodinstallation

# Finish Message
read -r -s -p $'\nIMPORTANT: NEXT STEPS: \n1) Configure the Graphs Module if required. \n\nPress now enter to exit...\n\n'
