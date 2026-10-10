#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~

# Enable otlpmetrics feature
icinga2 feature enable otlpmetrics
systemctl restart icinga2

# Configure otlpmetrics
sed -i 's|// host = "127.0.0.1"|host = "localhost"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|// port = 4318|port = 9090|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|// metrics_endpoint = "/v1/metrics"|metrics_endpoint = "/api/v1/otlp/v1/metrics"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|// enable_tls = false|enable_tls = true|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|// tls_ca_file = "/path/to/otel/ca.crt"|tls_ca_file = "/etc/prometheus/prometheus.crt"|g' /etc/icinga2/features-available/influxdb.conf

systemctl restart icinga2

# Perfdatagraphs Module
git clone https://github.com/NETWAYS/icingaweb2-module-perfdatagraphs.git
mv icingaweb2-module-perfdatagraphs/ perfdatagraphs
mv perfdatagraphs/ /usr/share/icingaweb2/modules/

# Perfdatagraphs Module for Prometheus
git clone https://github.com/NETWAYS/icingaweb2-module-perfdatagraphs-prometheus.git
mv icingaweb2-module-perfdatagraphs-prometheus/ perfdatagraphsprometheus
mv perfdatagraphsprometheus /usr/share/icingaweb2/modules/

mkdir /etc/icingaweb2/modules/perfdatagraphs
touch /etc/icingaweb2/modules/perfdatagraphs/config.ini
chown www-data:icingaweb2 /etc/icingaweb2/modules/perfdatagraphs/config.ini
echo "[perfdatagraphs]" >> /etc/icingaweb2/modules/perfdatagraphs/config.ini
echo "default_backend = \"Prometheus\"" >> /etc/icingaweb2/modules/perfdatagraphs/config.ini

mkdir /etc/icingaweb2/modules/perfdatagraphsprometheus
touch /etc/icingaweb2/modules/perfdatagraphsprometheus/config.ini
chown www-data:icingaweb2 /etc/icingaweb2/modules/perfdatagraphsprometheus/config.ini
echo "[prometheus]" >> /etc/icingaweb2/modules/perfdatagraphsprometheus/config.ini
echo "api_url = \"https://localhost:9090\"" >> /etc/icingaweb2/modules/perfdatagraphsprometheus/config.ini
echo "api_tls_insecure = \"1\"" >> /etc/icingaweb2/modules/perfdatagraphsprometheus/config.ini
echo "api_auth_method = \"none\"" >> /etc/icingaweb2/modules/perfdatagraphsprometheus/config.ini
echo "api_auth_mtls = \"0\"" >> /etc/icingaweb2/modules/perfdatagraphsprometheus/config.ini
echo "api_use_otel_names = \"0\"" >> /etc/icingaweb2/modules/perfdatagraphsprometheus/config.ini

icingacli module enable perfdatagraphs
icingacli module enable perfdatagraphsprometheus

cd ~
cd icinga2prodinstallation