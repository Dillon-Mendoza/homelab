#!/bin/bash
# Week 7 Security Audit: Services & Logs

echo "[*] Checking for failed services..."
failed_count=$(systemctl --failed | grep "loaded units listed" | awk '{print $1}')
if [ "$failed_count" != "0" ] && [ ! -z "$failed_count" ]; then
    echo "[!] Warning: $failed_count failed services detected!"
    systemctl --failed --no-pager
else
    echo "[+] No failed services detected."
fi

echo "[*] Checking status of critical services..."
services=("sshd" "ssh" "firewalld" "ufw" "NetworkManager")
for service in "${services[@]}"; do
    if systemctl list-unit-files | grep -q "$service.service"; then
        state=$(systemctl is-active "$service")
        echo "[$service] status: $state"
    fi
done

echo "[*] Checking for suspicious failed login attempts (last 10)..."
sudo journalctl -t sshd -t ssh | grep "Failed password" | tail -n 10

echo "[*] Audit complete."
