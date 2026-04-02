#!/bin/bash
# Week 9 Security Audit: Networking

echo "[*] Checking for unexpected listening services..."
ss -tulpn | grep LISTEN

echo "[*] Checking for open ports on all interfaces..."
netstat -tulpn

echo "[*] Checking firewall status (UFW)..."
if command -v ufw >/dev/null; then
    ufw status
else
    echo "[!] UFW not installed."
fi

echo "[*] Checking firewall status (Firewalld)..."
if command -v firewall-cmd >/dev/null; then
    firewall-cmd --state
else
    echo "[!] Firewalld not installed."
fi

echo "[*] Checking for IP forwarding (potential security risk if not a router)..."
sysctl net.ipv4.ip_forward
