#!/usr/bin/env bash
set -euo pipefail

if ! command -v stress-ng &> /dev/null; then
    echo "Installing stress-ng..."
    sudo apt-get install -y stress-ng
fi

echo "=== Starting Load Test for Netdata Dashboard ==="
echo "Generating High CPU & RAM load for 60 seconds..."
echo "Watch your Netdata dashboard (http://<SERVER_IP>:19999) to observe spike and triggered alerts!"

# Нагрузка: 4 ядра CPU, 256M RAM, 2 потока Disk I/O на 60 секунд
stress-ng --cpu 4 --vm 2 --vm-bytes 256M --io 2 --timeout 60s --metrics-brief

echo "=== Load Test Completed ==="
echo "Check the Health Notifications tab in Netdata to verify if the CPU alert was triggered."