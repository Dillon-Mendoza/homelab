#!/bin/bash
# Week 13 Security Audit: Scripting & Cron

echo "[*] Checking for world-writable scripts in home directory..."
find ~ -type f -name "*.sh" -perm -o+w 2>/dev/null

echo "[*] Checking for suspicious crontab entries..."
crontab -l 2>/dev/null | grep -E "wget|curl|http|/tmp"

echo "[*] Checking system-wide cron jobs (/etc/cron*)..."
ls -la /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.hourly 2>/dev/null

echo "[*] Checking for scripts with hardcoded passwords (basic check)..."
grep -riE "password|pass|secret" ~/*.sh 2>/dev/null | grep -v "Binary file"

echo "[*] Checking for set -e usage in local scripts (best practice)..."
grep -l "set -e" ~/*.sh 2>/dev/null | head -n 5
echo "... (showing top 5 results)"
