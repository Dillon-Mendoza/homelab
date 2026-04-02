#!/bin/bash
# Week 14 Security Audit: Advanced Scripting & Cron

echo "[*] Checking for world-writable scripts..."
find /usr/local/bin /usr/local/sbin ~ -type f -name "*.sh" -perm -o+w 2>/dev/null

echo "[*] Checking for scripts with SUID/SGID bits..."
find ~ -type f -name "*.sh" \( -perm -4000 -o -perm -2000 \) 2>/dev/null

echo "[*] Checking for cron jobs running as root (system-wide)..."
grep -v "^#" /etc/crontab /etc/cron.d/* 2>/dev/null

echo "[*] Checking for environment variables in scripts that might be sensitive..."
grep -riE "API_KEY|TOKEN|SECRET|PASSWORD" ~/*.sh 2>/dev/null | grep -v "Binary file"

echo "[*] Checking for scripts without set -e (potential ignored errors)..."
grep -L "set -e" ~/*.sh 2>/dev/null | head -n 5
