#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~

# This does not work
#wget https://download.influxdata.com/influxdb/releases/influxdb-1.11.8-amd64.deb
#sudo dpkg -i influxdb-1.11.8-amd64.deb

# Addf InfluxDB Repo
wget -q https://repos.influxdata.com/influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list

# Install InfluxDB
apt-get update && sudo apt-get install influxdb
systemctl restart influxdb

#apt install -y adduser libfontconfig1 musl
#wget https://dl.grafana.com/oss/release/grafana_12.0.1_amd64.deb
#dpkg -i grafana_12.0.1_amd64.deb

# Install a specific Grafana version (12.1.0)
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/oss/release/grafana_12.1.0_amd64.deb
sudo dpkg -i grafana_12.1.0_amd64.deb

systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server.service

# Enable InfluxDB feature
icinga2 feature enable influxdb
systemctl restart icinga2

sed -i 's|//host = "127.0.0.1"|host = "127.0.0.1"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//port = 8086|port = 8086|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//database = "icinga2"|database = "icinga"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//flush_threshold = 1024|flush_threshold = 1024|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//flush_interval = 10s|flush_interval = 10s|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//host_template = {|host_template = {|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  measurement = "$host.check_command$"|  measurement = "$host.check_command$"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  tags = {|  tags = {|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//    hostname = "$host.name$"|    hostname = "$host.name$"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  }|  }|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//}|}|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//service_template = {|service_template = {|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  measurement = "$service.check_command$"|  measurement = "$service.check_command$"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  tags = {|  tags = {|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//    hostname = "$host.name$"|    hostname = "$host.name$"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//    service = "$service.name$"|    service = "$service.name$"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  }|  }|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//}|}|g' /etc/icinga2/features-available/influxdb.conf

systemctl restart icinga2

influx -execute 'CREATE DATABASE icinga'
influx -execute 'SHOW DATABASES'
influx -database 'icinga' -execute 'CREATE USER icinga WITH PASSWORD '\'icinga\'' WITH ALL PRIVILEGES'
influx -execute 'show retention policies on "icinga"'
influx -execute 'create retention policy "icinga_2_weeks" on "icinga" duration 2w replication 1 default'
influx -execute 'alter retention policy "icinga_2_weeks" on "icinga" default'
influx -execute 'drop retention policy "autogen" on "icinga"'

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
#ICINGAWEB_MODULEPATH="/usr/share/icingaweb2/modules"
#REPO_URL="https://github.com/NETWAYS/icingaweb2-module-grafana"
#TARGET_DIR="${ICINGAWEB_MODULEPATH}/grafana"
#git clone "${REPO_URL}" "${TARGET_DIR}"

#icingacli module enable grafana

cd icinga2prodinstallation

rm -f /etc/grafana/grafana.ini
cp grafana/grafana.ini /etc/grafana/grafana.ini
cp /etc/ssl/certs/httpd.crt /etc/grafana/httpd.crt
cp /etc/ssl/private/httpd.key /etc/grafana/httpd.key

cd /etc/grafana
chown grafana:grafana grafana.ini httpd.crt httpd.key
systemctl restart grafana-server.service

# Install a custom image renderer version
#grafana-cli --pluginUrl /var/lib/grafana/plugins/grafana-image-renderer-3.11.0.linux-amd64.zip plugins install grafana-image-renderer

grafana-cli plugins install grafana-image-renderer
apt install libnspr4 libnss3 libatk1.0-0 libatk-bridge2.0-0 libxcomposite1 libxdamage1 libx11-dev libxfixes3 libxrandr2 libgbm1 liboss4-salsa-asound2 -y
systemctl restart grafana-server.service

sleep 5

curl -k --user admin:admin 'https://localhost:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"InfluxDB","type":"influxdb","url":"http://localhost:8086","access":"proxy","isDefault":true,"database":"icinga","user":"icinga","password":"icinga"}'

cd ~
cd icinga2prodinstallation

read -r -s -p $'\nIMPORTANT: NEXT STEPS: \n1) Verify the InfluxDB datasource in grafana \n2) Configure the Graphs Module if required. \n\nPress now enter to exit...\n\n'
