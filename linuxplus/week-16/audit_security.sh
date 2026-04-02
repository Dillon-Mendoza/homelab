#!/bin/bash
# Week 16 Security Audit: Package Updates & Repositories

echo "[*] Checking for available security updates..."
dnf updateinfo list security 2>/dev/null

echo "[*] Checking enabled repositories..."
dnf repolist

echo "[*] Checking for dnf-automatic status..."
if systemctl is-active --quiet dnf-automatic.timer; then
    echo "[+] dnf-automatic timer is active."
else
    echo "[!] Warning: dnf-automatic timer is NOT active."
fi

echo "[*] Verifying RPM database integrity..."
rpm -V $(rpm -qa) | head -n 20 # Show first 20 integrity issues if any

echo "[*] Checking for EPEL repository..."
if dnf repolist | grep -q "epel"; then
    echo "[+] EPEL repository is enabled."
else
    echo "[-] EPEL repository is not enabled."
fi
