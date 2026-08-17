#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/3] Updating system packages ==="
sudo apt-get update -y
sudo apt-get install -y curl wget stress-ng

echo "=== [2/3] Installing Netdata Agent ==="
if ! command -v netdata &> /dev/null; then
    wget -O /tmp/netdata-kickstart.sh [https://get.netdata.cloud/kickstart.sh](https://get.netdata.cloud/kickstart.sh)
    sh /tmp/netdata-kickstart.sh --non-interactive
else
    echo "Netdata is already installed."
fi

echo "=== [3/3] Configuring Custom CPU Alert ==="
NETDATA_CONF_DIR="/etc/netdata/health.d"
sudo mkdir -p "${NETDATA_CONF_DIR}"

cat << 'EOF' | sudo tee "${NETDATA_CONF_DIR}/custom_cpu.conf" > /dev/null
 template: custom_cpu_high
       on: system.cpu
    lookup: average -10s unaligned of user,system
     every: 5s
      warn: $this > 60
     crit: $this > 80
      info: High CPU load detected by automated test
EOF

echo "=== Restarting Netdata Service ==="
sudo systemctl restart netdata

echo "SUCCESS: Netdata setup complete! Access dashboard at http://$(hostname -I | awk '{print $1}'):19999"