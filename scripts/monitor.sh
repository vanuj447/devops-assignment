#!/bin/bash

# System monitoring script
echo "=== System Resource Usage Report ==="
date

echo -e "\n=== CPU Usage ==="
top -b -n 1 | head -n 12

echo -e "\n=== Memory Usage ==="
free -h

echo -e "\n=== Top 5 CPU Consuming Processes ==="
ps aux --sort=-%cpu | head -n 6

echo -e "\n=== Top 5 Memory Consuming Processes ==="
ps aux --sort=-%mem | head -n 6

echo -e "\n=== Disk Usage ==="
df -h