#!/bin/bash

echo "=================================================="
echo "           SERVER PERFORMANCE STATS               "
echo "=================================================="

# OS Version & System Info
echo -e "\n[ SYSTEM INFO ]"
if [ -f /etc/os-release ]; then
    echo "OS Version:     $(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"')"
fi
echo "Uptime:         $(uptime -p)"
echo "Load Average:   $(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ //')"
echo "Logged Users:   $(who | wc -l)"

# CPU Usage
echo -e "\n[ CPU USAGE ]"
cpu_idle=$(top -bn1 | grep "%Cpu(s)" | awk '{print $8}')
cpu_usage=$(awk "BEGIN {print 100 - $cpu_idle}")
echo "Total CPU Usage: ${cpu_usage}%"
ы
# Memory Usage
echo -e "\n[ MEMORY USAGE ]"
free -m | awk 'NR==2{
    total=$2;
    used=$3;
    free=$4;
    pct_used=(used/total)*100;
    pct_free=(free/total)*100;
    printf "Total: %d MB | Used: %d MB (%.2f%%) | Free: %d MB (%.2f%%)\n", total, used, pct_used, free, pct_free
}'

# Disk Usage
echo -e "\n[ DISK USAGE ]"
df -h --total | grep 'total' | awk '{
    total=$2;
    used=$3;
    free=$4;
    pct=$5;
    printf "Total: %s | Used: %s | Free: %s | Usage: %s\n", total, used, free, pct
}'

# Top 5 Processes by CPU Usage
echo -e "\n[ TOP 5 PROCESSES BY CPU USAGE ]"
ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -n 6 | awk 'NR==1{printf "%-8s %-8s %-6s %s\n", $1,$2,$4,$3} NR>1{printf "%-8s %-8s %-6s %s\n", $1,$2,$4,$3}'

# Top 5 Processes by Memory Usage
echo -e "\n[ TOP 5 PROCESSES BY MEMORY USAGE ]"
ps -eo pid,ppid,cmd,%mem --sort=-%mem | head -n 6 | awk 'NR==1{printf "%-8s %-8s %-6s %s\n", $1,$2,$4,$3} NR>1{printf "%-8s %-8s %-6s %s\n", $1,$2,$4,$3}'

echo -e "\n=================================================="