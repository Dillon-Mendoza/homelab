#!/bin/bash
# Week 1 Security Audit: Permissions

echo "[*] Checking for insecure (777) permissions in home directory..."
find ~ -type f -perm 777 2>/dev/null

echo "[*] Checking for SUID files (potential privilege escalation)..."
find /usr/bin /usr/sbin -perm -4000 2>/dev/null

echo "[*] Checking for SGID files..."
find /usr/bin /usr/sbin -perm -2000 2>/dev/null

echo "[*] Checking for world-writable directories with sticky bit..."
find / -type d -perm -0002 -a ! -perm -1000 2>/dev/null

echo "[*] Checking current umask..."
umask_val=$(umask)
echo "Current umask: $umask_val"
if [ "$umask_val" == "0000" ] || [ "$umask_val" == "0002" ]; then
    echo "[!] Warning: Relaxed umask detected."
fi
