#!/bin/bash
# Week 3 Lab: User & Group Management

# Practice viewing account files
echo "[*] Viewing /etc/passwd entry for current user..."
grep "$USER" /etc/passwd

echo "[*] Viewing /etc/group..."
tail -n 5 /etc/group

# User Creation Practice
echo "[*] Creating new users..."
sudo useradd -m -s /bin/bash tier1admin
sudo useradd -m -s /bin/bash fedora_admin
# Create a system account for a service
sudo useradd -r -s /sbin/nologin gitea_service

# Set passwords (interactive)
echo "[!] Please set passwords for the new users manually using 'sudo passwd <user>'."

# Group Management Practice
echo "[*] Creating groups..."
sudo groupadd admin
sudo groupadd developers
sudo groupadd monitoring

# Group Membership Practice
echo "[*] Adding users to groups..."
sudo usermod -aG admin tier1admin
sudo usermod -aG admin,developers,monitoring fedora_admin

# Verification
echo "[*] Verifying tier1admin groups:"
groups tier1admin
id tier1admin

echo "[*] Verifying fedora_admin groups:"
id fedora_admin

# Password Aging Practice
echo "[*] Configuring password policies for tier1admin..."
sudo chage -M 90 tier1admin   # Max days: 90
sudo chage -W 14 tier1admin   # Warning: 14 days
sudo chage -l tier1admin      # List aging info

# Testing identity
echo "[*] Current identity: $(whoami)"
echo "[*] You can test switching users with: su - tier1admin"
