#!/bin/bash

# Load OS info
. /etc/os-release

# Check if Ubuntu 24.04
if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
    echo "Running on Ubuntu 24.04. Proceeding..."

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~
cd icinga2prodinstallation

chmod +x businessprocess.sh map.sh fileshipper.sh pdfexport.sh reporting.sh cube.sh theme.sh elastic.sh audit.sh x509.sh enforceddashboard.sh grafana.sh

apt install -y git wget htop

./businessprocess.sh
./map.sh
./fileshipper.sh
./pdfexport.sh
./reporting.sh
./cube.sh
./theme.sh
./audit.sh
./x509.sh
./enforceddashboard.sh
./grafana.sh

cd ~
cd icinga2prodinstallation

else
    echo "This script only runs on Ubuntu 24.04. Exiting."
    exit 1
fi
