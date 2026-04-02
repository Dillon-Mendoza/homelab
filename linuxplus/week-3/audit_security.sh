#!/bin/bash
# Week 3 Security Audit: Users & Groups

echo "[*] Checking for users with UID 0 (other than root)..."
awk -F: '($3 == 0) { print $1 }' /etc/passwd | grep -v '^root$'

echo "[*] Checking for empty passwords in /etc/shadow..."
sudo awk -F: '($2 == "" ) { print $1 }' /etc/shadow

echo "[*] Checking for password aging information for regular users..."
for user in $(awk -F: '($3 >= 1000) {print $1}' /etc/passwd); do
    echo "--- User: $user ---"
    sudo chage -l "$user" | grep "Password expires"
done

echo "[*] Identifying system accounts with login shells..."
grep -vE 'nologin|false' /etc/passwd | awk -F: '($3 < 1000 && $3 != 0) {print $1 ":" $7}'

echo "[*] Checking for world-writable home directories..."
ls -ld /home/* 2>/dev/null | grep '^d....w'
