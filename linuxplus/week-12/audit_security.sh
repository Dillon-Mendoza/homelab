#!/bin/bash
# Week 12 Security Audit: Log Integrity & Retention

echo "[*] Checking for world-readable sensitive logs..."
ls -l /var/log/auth.log /var/log/secure /var/log/messages 2>/dev/null

echo "[*] Verifying logrotate is scheduled (cron or systemd timer)..."
ls -l /etc/cron.daily/logrotate || systemctl status logrotate.timer

echo "[*] Checking for evidence of log tampering (Hidden or deleted logs)..."
sudo find /var/log -type f -name ".*" -ls

echo "[*] Checking top 10 IPs for failed SSH logins..."
if [ -f /var/log/auth.log ]; then
    sudo grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | head -n 10
elif [ -f /var/log/secure ]; then
    sudo grep "Failed password" /var/log/secure | awk '{print $11}' | sort | uniq -c | sort -nr | head -n 10
fi

echo "[*] Checking disk usage for /var/log (Alert if > 80%)..."
usage=$(df /var/log | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$usage" -gt 80 ]; then
    echo "[!] Warning: /var/log usage is at ${usage}%"
else
    echo "[OK] /var/log usage is at ${usage}%"
fi

echo "[*] Checking if 'compress' is enabled in logrotate.conf..."
grep "^compress" /etc/logrotate.conf || echo "[!] Compression not enabled globally in logrotate.conf"
