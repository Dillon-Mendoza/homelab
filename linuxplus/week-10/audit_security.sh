#!/bin/bash
# Week 10 Security Audit: Firewall Status

echo "[*] Checking iptables default policies..."
sudo iptables -L | grep policy

echo "[*] Checking for any 'ACCEPT ALL' rules (Potential risk)..."
sudo iptables -L INPUT -n | grep "0.0.0.0/0" | grep "ACCEPT"

echo "[*] Checking UFW status..."
if command -v ufw >/dev/null; then
    sudo ufw status verbose
else
    echo "UFW not found."
fi

echo "[*] Checking Firewalld status..."
if command -v firewall-cmd >/dev/null; then
    sudo firewall-cmd --list-all
else
    echo "firewall-cmd not found."
fi

echo "[*] Checking for persistent rules..."
if [ -f /etc/iptables/rules.v4 ]; then
    echo "[OK] Persistent IPv4 rules file found."
else
    echo "[!] Persistent IPv4 rules file NOT found."
fi
