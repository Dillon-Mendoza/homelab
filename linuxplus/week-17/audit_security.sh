#!/bin/bash
# Week 17 Security Audit: Network & System Hardening

echo "[*] Checking for open network ports (Local Scan)..."
nmap -sT localhost 2>/dev/null | grep "PORT\|open"

echo "[*] Checking SSH Root Login status..."
if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    echo "[+] SSH Root Login is disabled."
else
    echo "[!] Warning: SSH Root Login might be enabled."
fi

echo "[*] Checking Fail2ban status..."
if systemctl is-active --quiet fail2ban; then
    echo "[+] Fail2ban is running."
    sudo fail2ban-client status 2>/dev/null
else
    echo "[!] Warning: Fail2ban is NOT running."
fi

echo "[*] Checking for Lynis hardening index (if available)..."
if [ -f /var/log/lynis-report.dat ]; then
    grep "hardening_index" /var/log/lynis-report.dat
else
    echo "[-] Lynis report not found. Run 'sudo lynis audit system' first."
fi

echo "[*] Checking for world-writable files in /etc..."
find /etc -type f -perm -o+w 2>/dev/null
