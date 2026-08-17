#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/2] Stopping and Uninstalling Netdata ==="
if [ -f /usr/libexec/netdata/netdata-uninstaller.sh ]; then
    sudo /usr/libexec/netdata/netdata-uninstaller.sh --yes --force
elif [ -f /usr/sbin/netdata-uninstaller.sh ]; then
    sudo /usr/sbin/netdata-uninstaller.sh --yes --force
else
    echo "Netdata uninstaller script not found. Purging via package manager..."
    sudo apt-get purge -y netdata || true
fi

echo "=== [2/2] Removing leftover configurations and tools ==="
sudo rm -rf /etc/netdata /var/lib/netdata /var/log/netdata /var/cache/netdata
sudo apt-get remove -y stress-ng || true
sudo apt-get autoremove -y

echo "SUCCESS: Cleanup complete. System restored to initial state."