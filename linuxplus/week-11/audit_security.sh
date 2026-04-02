#!/bin/bash
# Week 11 Security Audit: Logging & Auditing

echo "[*] Checking if rsyslog is active..."
systemctl is-active rsyslog

echo "[*] Checking /var/log permissions (Should not be world-writable)..."
ls -ld /var/log

echo "[*] Checking for large log files that might cause DOS..."
find /var/log -type f -size +100M -ls

echo "[*] Checking for recent failed login attempts..."
if [ -f /var/log/auth.log ]; then
    grep "Failed password" /var/log/auth.log | tail -n 5
elif [ -f /var/log/secure ]; then
    grep "Failed password" /var/log/secure | tail -n 5
else
    journalctl _SYSTEMD_UNIT=sshd.service | grep "Failed password" | tail -n 5
fi

echo "[*] Checking if remote logging is configured in /etc/rsyslog.conf..."
grep "@" /etc/rsyslog.conf | grep -v "^#"

echo "[*] Checking for auditd service status..."
systemctl is-active auditd || echo "[!] auditd is not running."
