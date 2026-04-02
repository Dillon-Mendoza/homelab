#!/bin/bash
# Week 18 Security Audit: SELinux Configuration

echo "[*] Checking SELinux Status..."
sestatus

echo "[*] Checking if SELinux is in Enforcing mode..."
mode=$(getenforce)
echo "Current Mode: $mode"
if [ "$mode" != "Enforcing" ]; then
    echo "[!] Warning: SELinux is NOT in Enforcing mode."
fi

echo "[*] Checking for recent AVC denials (last 24 hours)..."
if command -v ausearch &>/dev/null; then
    sudo ausearch -m avc -ts recent 2>/dev/null | grep "denied" | tail -n 5
else
    echo "[-] ausearch command not found."
fi

echo "[*] Checking critical booleans..."
for bool in httpd_can_network_connect ssh_sysadm_login; do
    if getsebool $bool 2>/dev/null; then
        getsebool $bool
    fi
done

echo "[*] Checking for custom file contexts..."
if command -v semanage &>/dev/null; then
    sudo semanage fcontext -l | grep -v "system_u:object_r:default_t" | head -n 10
else
    echo "[-] semanage command not found."
fi
