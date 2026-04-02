#!/bin/bash
# Week 5 Security Audit: SSH Keys

echo "[*] Checking ~/.ssh directory permissions..."
if [ -d ~/.ssh ]; then
    ls -ld ~/.ssh
    perms=$(stat -c "%a" ~/.ssh)
    if [ "$perms" != "700" ]; then
        echo "[!] Warning: ~/.ssh permissions are $perms, should be 700"
    fi
else
    echo "[!] Warning: ~/.ssh directory not found."
fi

echo "[*] Checking authorized_keys permissions..."
if [ -f ~/.ssh/authorized_keys ]; then
    ls -l ~/.ssh/authorized_keys
    perms=$(stat -c "%a" ~/.ssh/authorized_keys)
    if [ "$perms" != "600" ]; then
        echo "[!] Warning: authorized_keys permissions are $perms, should be 600"
    fi
fi

echo "[*] Checking for private keys without proper protection..."
find ~/.ssh -type f -name "id_*" ! -name "*.pub" -exec ls -l {} +

echo "[*] Audit complete."
