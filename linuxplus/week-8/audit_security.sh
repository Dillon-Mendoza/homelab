#!/bin/bash
# Week 8 Security Audit: Custom Services

echo "[*] Listing custom services in /etc/systemd/system/..."
find /etc/systemd/system/ -maxdepth 1 -name "*.service" -type f -exec ls -l {} +

echo "[*] Auditing custom service permissions..."
# Unit files should be owned by root and NOT world-writable
find /etc/systemd/system/ -maxdepth 1 -name "*.service" -type f -perm /002 -exec echo "[!] World-writable unit file detected: {}" \;

echo "[*] Checking for services running as root unnecessarily..."
grep -r "User=root" /etc/systemd/system/*.service 2>/dev/null

echo "[*] Checking status of custom lab service..."
if systemctl list-unit-files | grep -q "lab-monitor.service"; then
    state=$(systemctl is-active lab-monitor.service)
    echo "[lab-monitor.service] status: $state"
    if [ "$state" != "active" ]; then
        echo "[!] Lab service is not running."
    fi
fi

echo "[*] Audit complete."
