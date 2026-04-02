#!/bin/bash
# Week 4 Security Audit: sudo Policies

echo "[*] Checking for users/groups with ALL privileges..."
sudo grep -E "ALL\s*=\s*\(ALL(:ALL)?\)\s*ALL" /etc/sudoers /etc/sudoers.d/* 2>/dev/null

echo "[*] Checking for NOPASSWD entries (potential risk)..."
sudo grep "NOPASSWD" /etc/sudoers /etc/sudoers.d/* 2>/dev/null

echo "[*] Verifying sudoers syntax..."
sudo visudo -c

echo "[*] Auditing sudo log configuration..."
if sudo grep -q "logfile" /etc/sudoers /etc/sudoers.d/*; then
    echo "[+] Custom sudo logfile is configured."
else
    echo "[-] Custom sudo logfile NOT configured (using system journal)."
fi

echo "[*] Searching for failed sudo attempts in journal..."
sudo journalctl _COMM=sudo | grep "COMMAND=" | grep -v "status=0" | tail -n 10

echo "[*] Checking permissions of /etc/sudoers (should be 440)..."
stat -c "%a" /etc/sudoers 2>/dev/null
