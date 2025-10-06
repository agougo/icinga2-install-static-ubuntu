#!/bin/bash

# Load OS info
. /etc/os-release

if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
    echo "Running on Ubuntu 24.04. Proceeding..."

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

# Initialize
cd ~
apt update

# Log in Insecure
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Install some pre-requisites
apt install nano wget htop apt-transport-https -y

# Add Icinga2 Repo
wget -O icinga-archive-keyring.deb "https://packages.icinga.com/icinga-archive-keyring_latest+ubuntu$(. /etc/os-release; echo "$VERSION_ID").deb"
apt install ./icinga-archive-keyring.deb
. /etc/os-release; if [ ! -z ${UBUNTU_CODENAME+x} ]; then DIST="${UBUNTU_CODENAME}"; else DIST="$(lsb_release -c| awk '{print $2}')"; fi; echo "deb [signed-by=/usr/share/keyrings/icinga-archive-keyring.gpg] https://packages.icinga.com/ubuntu icinga-${DIST} main" > /etc/apt/sources.list.d/${DIST}-icinga.list
echo "deb-src [signed-by=/usr/share/keyrings/icinga-archive-keyring.gpg] https://packages.icinga.com/ubuntu icinga-${DIST} main" >> /etc/apt/sources.list.d/${DIST}-icinga.list
apt update

# Install Icinga2
apt install dialog -y
apt install icinga2 -y
apt install monitoring-plugins -y
icinga2 api setup
systemctl restart icinga2

# Install PostgreSQL Repository
apt install curl ca-certificates
install -d /usr/share/postgresql-common/pgdg
curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
. /etc/os-release
sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
apt update

# Install PostgreSQL version 16
apt install postgresql-contrib postgresql-17 postgresql-client-17 -y
systemctl enable postgresql
systemctl restart postgresql

# Apparently in Ubuntu this is not needed
#sudo -u postgres /usr/lib/postgresql/17/bin/initdb -D /var/lib/postgresql/17/main --locale-provider=icu --icu-locale=en-US

# Modify DB Settings
cp ~/icinga2prodinstallation/postgresql/ubuntu_pg_hba.conf /etc/postgresql/17/main/pg_hba.conf
systemctl restart postgresql

# Install icingadb
apt install icingadb -y
systemctl enable icingadb

# Create PostgreSQL stuff and import schema
su - postgres -c "psql -U postgres -d postgres -c \"CREATE USER icingadb WITH PASSWORD 'icingadb';\""
sudo -u postgres createdb -E UTF8 --locale-provider=icu --icu-locale=en-US -T template0 -O icingadb icingadb
sudo -u postgres psql icingadb -c "CREATE EXTENSION IF NOT EXISTS citext;"

export PGPASSWORD=icingadb
psql -U icingadb -d icingadb < /usr/share/icingadb/schema/pgsql/schema.sql

# Configure icingadb
sed -i 's|#  type: mysql|  type: pgsql|g' /etc/icingadb/config.yml
sed -i 's|password: CHANGEME|password: icingadb|g' /etc/icingadb/config.yml

# To prepare the IcingaWeb2 installation, install and enable the Apache webserver
apt install apache2 -y
systemctl enable apache2
systemctl restart apache2

# Setup Firewall
# Check if ufw is installed
if ! dpkg -l | grep -qw ufw; then
    echo "Firewall not installed. Proceeding with the script..."

    # Your actual script goes here
    apt install ufw -y
    echo "y" | ufw enable
    ufw status

else
    echo "Firewall is installed. Exiting."
fi

# Set firewall rules
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw allow 5665/tcp

# Setup a bunch of API Users
echo -e "\n" >> /etc/icinga2/conf.d/api-users.conf
echo "object ApiUser \"icingaweb2\" {" >> /etc/icinga2/conf.d/api-users.conf
echo "  password = \"icingaweb2\" " >> /etc/icinga2/conf.d/api-users.conf
echo "  permissions = [ \"status/query\", \"actions/*\", \"objects/modify/*\", \"objects/query/*\" ]" >> /etc/icinga2/conf.d/api-users.conf
echo "}" >> /etc/icinga2/conf.d/api-users.conf

echo -e "\n" >> /etc/icinga2/conf.d/api-users.conf
echo "object ApiUser \"admin\" {" >> /etc/icinga2/conf.d/api-users.conf
echo "  password = \"admin\" " >> /etc/icinga2/conf.d/api-users.conf
echo "  permissions = [ \"*\" ]" >> /etc/icinga2/conf.d/api-users.conf
echo "}" >> /etc/icinga2/conf.d/api-users.conf

# Icingaweb2
apt install php php-curl php-intl php-mbstring php-xml php-json php-fpm -y
apt install icingaweb2 icingacli -y
systemctl restart apache2

# Install icingadb-web
apt install icingadb-web -y

# Install Redis
apt install icingadb-redis -y
systemctl enable icingadb-redis

# Restart
systemctl restart icingadb-redis
systemctl restart icingadb

# Enable IcingaDB
icinga2 feature enable icingadb
systemctl restart icinga2

icingacli module enable icingadb

# Create Token
icingacli setup token create

# Add your webserver's user to the "icingaweb2" system group
usermod -a -G icingaweb2 www-data

# Set a PostgreSQL password for the "postgres" user to be used by the setup
su - postgres -c "psql -U postgres -d postgres -c \"alter user postgres with password 'postgres';\""

# Enable SSL
a2enmod ssl
systemctl restart apache2

# Self signed certificate
openssl genrsa -out /etc/ssl/private/httpd.key 4096
openssl rsa -in /etc/ssl/private/httpd.key -out /etc/ssl/private/httpd.key
openssl req -sha256 -new -key /etc/ssl/private/httpd.key -out /etc/ssl/private/httpd.csr -nodes -subj '/CN=Icinga2Server'
openssl x509 -req -sha256 -days 1825 -in /etc/ssl/private/httpd.csr -signkey /etc/ssl/private/httpd.key -out /etc/ssl/certs/httpd.crt

sed -i 's|SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem|SSLCertificateFile      /etc/ssl/certs/httpd.crt|g' /etc/apache2/sites-available/default-ssl.conf
sed -i 's|SSLCertificateKeyFile   /etc/ssl/private/ssl-cert-snakeoil.key|SSLCertificateKeyFile   /etc/ssl/private/httpd.key|g' /etc/apache2/sites-available/default-ssl.conf

systemctl restart apache2

# Enable https
a2ensite default-ssl
systemctl reload apache2

# Add DNS entry
IP=$(hostname -I)
echo $IP $HOSTNAME >> /etc/hosts

# Finish Message
read -r -s -p $'\nIMPORTANT: NEXT STEPS -> Configure your Icinga2 Installation through IcingaWeb2 \n\nNow press Enter to run your Icinga2 Node Wizard'

# Configure as master
icinga2 node wizard
systemctl restart icinga2

# Show Token
icingacli setup token show

else
    echo "This script only runs on Ubuntu 24.04. Exiting."
    exit 1
fi
