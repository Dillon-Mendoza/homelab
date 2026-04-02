#!/bin/bash
# Week 7 Lab: Systemd Service Management

# 1. List all running services
echo "[*] Listing all active services..."
systemctl list-units --type=service --state=running | head -n 20

# 2. Check status of SSH service
echo "[*] Checking SSH service status..."
if systemctl is-active sshd >/dev/null 2>&1; then
    systemctl status sshd --no-pager
elif systemctl is-active ssh >/dev/null 2>&1; then
    systemctl status ssh --no-pager
fi

# 3. List failed services
echo "[*] Listing any failed services..."
systemctl --failed

# 4. Journalctl practice
echo "[*] Viewing last 10 lines of system logs..."
sudo journalctl -n 10 --no-pager

echo "[*] Viewing last 5 SSH-related logs..."
if systemctl is-active sshd >/dev/null 2>&1; then
    sudo journalctl -u sshd -n 5 --no-pager
elif systemctl is-active ssh >/dev/null 2>&1; then
    sudo journalctl -u ssh -n 5 --no-pager
fi

echo "[*] Lab complete."
