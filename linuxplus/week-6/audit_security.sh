#!/bin/bash
# Week 6 Security Audit: SSH Hardening

SSHD_CONFIG="/etc/ssh/sshd_config"

echo "[*] Auditing $SSHD_CONFIG..."

check_setting() {
    setting=$1
    expected=$2
    actual=$(grep "^$setting" $SSHD_CONFIG | awk '{print $2}')
    if [ "$actual" == "$expected" ]; then
        echo "[+] $setting is correctly set to $expected"
    else
        echo "[!] $setting is set to '$actual' (Expected: $expected)"
    fi
}

if [ -f "$SSHD_CONFIG" ]; then
    check_setting "PasswordAuthentication" "no"
    check_setting "PermitRootLogin" "no"
    check_setting "PermitEmptyPasswords" "no"
    
    # Check for Port
    port=$(grep "^Port" $SSHD_CONFIG | awk '{print $2}')
    if [ -z "$port" ] || [ "$port" == "22" ]; then
        echo "[-] Port is set to default (22) or not explicitly set."
    else
        echo "[+] Port is set to $port"
    fi
else
    echo "[!] $SSHD_CONFIG not found."
fi

echo "[*] Audit complete."
