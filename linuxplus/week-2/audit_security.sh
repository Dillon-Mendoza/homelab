#!/bin/bash
# Week 2 Security Audit: Special Permissions

echo "[*] Auditing SUID binaries in /usr/bin and /usr/sbin..."
find /usr/bin /usr/sbin -perm -4000 -exec ls -l {} \; 2>/dev/null

echo "[*] Auditing SGID binaries..."
find /usr/bin /usr/sbin -perm -2000 -exec ls -l {} \; 2>/dev/null

echo "[*] Checking for world-writable directories without sticky bit..."
find / -type d -perm -0002 -a ! -perm -1000 -ls 2>/dev/null

echo "[*] Checking for files with SUID/SGID in home directory (potential risk)..."
find ~ -type f \( -perm -4000 -o -perm -2000 \) -ls 2>/dev/null

echo "[*] Verifying current umask..."
umask_val=$(umask)
echo "Current umask is $umask_val"
if [ "$umask_val" != "022" ] && [ "$umask_val" != "0022" ] && [ "$umask_val" != "0027" ]; then
    echo "[!] Warning: Non-standard umask detected."
fi
