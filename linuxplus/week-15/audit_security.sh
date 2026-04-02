#!/bin/bash
# Week 15 Security Audit: Package Management

echo "[*] Checking for world-writable sources.list..."
ls -l /etc/apt/sources.list | grep "^.w.w.w"

echo "[*] Checking for unsigned or third-party repositories..."
grep -rE "^deb http" /etc/apt/sources.list /etc/apt/sources.list.d/ | grep -v "ubuntu.com"

echo "[*] Checking for held packages (potential security updates skipped)..."
dpkg --get-selections | grep hold

echo "[*] Checking for recently installed packages..."
grep " install " /var/log/dpkg.log | tail -n 10

echo "[*] Checking for broken dependencies..."
sudo apt-get check

echo "[*] Checking for old kernel versions taking up space..."
dpkg --list | grep linux-image | grep -v "$(uname -r)" | head -n 5
