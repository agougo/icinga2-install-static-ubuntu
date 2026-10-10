#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~

VERSION="13.2.3"
BUILD="36482603486"
DEB="grafana_${VERSION}_${BUILD}_linux_amd64.deb"
URL="https://dl.grafana.com/grafana/release/${VERSION}/${DEB}"

apt-get install -y adduser libfontconfig1 musl
wget "$URL"
dpkg -i "$DEB"

systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server.service

cd icinga2prodinstallation

rm -f /etc/grafana/grafana.ini
cp grafana/grafana.ini /etc/grafana/grafana.ini
cp /etc/ssl/certs/httpd.crt /etc/grafana/httpd.crt
cp /etc/ssl/private/httpd.key /etc/grafana/httpd.key

cd /etc/grafana
chown grafana:grafana grafana.ini httpd.crt httpd.key
systemctl restart grafana-server.service

sleep 5

GRAFANA_URL="https://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"
PROM_URL="https://localhost:9090"

curl -k --user "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/datasources" \
  -X POST -H 'Content-Type: application/json;charset=UTF-8' \
  --data-binary '{
    "name": "prometheus",
    "type": "prometheus",
    "url": "'"$PROM_URL"'",
    "access": "proxy",
    "isDefault": true,
    "jsonData": {
      "httpMethod": "POST",
      "tlsSkipVerify": true
    }
  }'

cd ~
cd icinga2prodinstallation

# Finish Message
read -r -s -p $'\nIMPORTANT: NEXT STEPS: \n1) Verify the Prometheus datasource in grafana \n2) Add a Graph. \n3) Add Grafana as a Menu item in IcingaWeb2. \n\nPress now enter to exit...\n\n'