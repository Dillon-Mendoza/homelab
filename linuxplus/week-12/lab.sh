#!/bin/bash
# Week 12 Lab: Log Rotation and Analysis

# 1. Inspect logrotate configuration
echo "[*] Viewing main logrotate configuration..."
cat /etc/logrotate.conf | grep -v "^#" | grep -v "^$"

echo "[*] Listing individual logrotate configs..."
ls -l /etc/logrotate.d/

# 2. Dry-run logrotate
echo "[*] Performing a logrotate dry-run..."
sudo logrotate -d /etc/logrotate.conf 2>&1 | head -n 20

# 3. Practice log analysis with grep
echo "[*] Searching for 'error' (case-insensitive) in /var/log/messages..."
sudo grep -i "error" /var/log/messages 2>/dev/null | tail -n 5

# 4. Practice field extraction with awk
echo "[*] Extracting timestamps and hostnames from /var/log/messages..."
sudo awk '{print $1, $2, $3, $4}' /var/log/messages 2>/dev/null | tail -n 5

# 5. Complex log analysis (Failed logins)
echo "[*] Analyzing failed login attempts (Top 5 usernames)..."
if [ -f /var/log/auth.log ]; then
    sudo grep "Failed password" /var/log/auth.log | awk '{print $9}' | sort | uniq -c | sort -nr | head -n 5
elif [ -f /var/log/secure ]; then
    sudo grep "Failed password" /var/log/secure | awk '{print $9}' | sort | uniq -c | sort -nr | head -n 5
fi

# 6. Check disk space used by logs
echo "[*] Checking disk space usage in /var/log..."
df -h /var/log
du -sh /var/log/* 2>/dev/null | sort -h | tail -n 5
