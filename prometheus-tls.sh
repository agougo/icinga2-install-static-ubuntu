#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

VERSION="3.15.0"

cd ~
NAME="prometheus-${VERSION}.linux-amd64"
URL="https://github.com/prometheus/prometheus/releases/download/v${VERSION}/${NAME}.tar.gz"
CERT=/etc/prometheus/prometheus

wget "$URL"
tar -xvf "${NAME}.tar.gz"
mv "$NAME" prometheus

useradd --no-create-home --shell /bin/false prometheus
mkdir /etc/prometheus
mkdir /var/lib/prometheus
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus

cp prometheus/prometheus /usr/local/bin/
cp prometheus/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

cp ~/icinga2prodinstallation/prometheus/prometheus-tls.yml /etc/prometheus/
chown prometheus:prometheus /etc/prometheus/prometheus-tls.yml

cp ~/icinga2prodinstallation/prometheus/web-tls.yml /etc/prometheus/
chown prometheus:prometheus /etc/prometheus/web-tls.yml

# TLS (skip when using Nginx for TLS offloading)
openssl req -x509 -sha256 -newkey rsa:4096 -nodes -days 1825 -keyout "$CERT.key" -out "$CERT.crt" \
  -subj '/CN=prometheus' \
  -addext "subjectAltName=DNS:prometheus,DNS:localhost,IP:127.0.0.1"
chown prometheus:prometheus "$CERT.key" "$CERT.crt"
chmod 600 "$CERT.key"
chmod 644 "$CERT.crt"

cat > /etc/systemd/system/prometheus.service <<'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file /etc/prometheus/prometheus-tls.yml \
  --storage.tsdb.path /var/lib/prometheus/ \
  --web.config.file=/etc/prometheus/web-tls.yml \
  --web.enable-otlp-receiver \
  --storage.tsdb.retention.time=30d

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now prometheus
systemctl restart prometheus