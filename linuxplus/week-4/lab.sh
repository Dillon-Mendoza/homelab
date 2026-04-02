#!/bin/bash
# Week 4 Lab: sudo Configuration

# Check current sudo privileges
echo "[*] Checking your current sudo privileges..."
sudo -l

# IMPORTANT: Always use visudo for editing /etc/sudoers
echo "[!] Exercise: Use 'sudo visudo' to perform the following steps manually."

# 1. Grant full sudo to a specific user
# Add line: tier1admin ALL=(ALL:ALL) ALL

# 2. Grant sudo to a group
# Add line: %admin ALL=(ALL:ALL) ALL

# 3. Restricted sudo for monitoring
# Add line: monitoring ALL=(ALL) /usr/bin/systemctl

# 4. Restricted sudo for developers
# Add line: developer ALL=(ALL) /usr/bin/systemctl, /usr/bin/journalctl

# 5. NOPASSWD example (for automation/backups)
# Add line: backup_user ALL=(ALL) NOPASSWD: /usr/bin/rsync

# Check sudoers syntax without opening the editor
echo "[*] Verifying sudoers syntax..."
sudo visudo -c

# Audit sudo logs
echo "[*] Viewing recent sudo logs from journalctl..."
sudo journalctl -u sudo --no-pager | tail -n 20

# Optional: Configure custom log file (requires visudo)
# Defaults logfile="/var/log/sudo.log"
# sudo touch /var/log/sudo.log
# sudo chmod 640 /var/log/sudo.log

echo "[*] Lab complete. Verify changes by switching users (su - <user>) and testing sudo commands."
