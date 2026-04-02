#!/bin/bash
# Week 5 Lab: SSH Key Generation & Deployment

# 1. Generate a new SSH key (Ed25519)
echo "[*] Generating Ed25519 SSH key..."
ssh-keygen -t ed25519 -C "lab-week-5" -f ~/.ssh/id_ed25519_lab -N ""

# 2. Verify key generation
echo "[*] Verifying key files..."
ls -l ~/.ssh/id_ed25519_lab*

# 3. Simulate adding public key to authorized_keys
echo "[*] Adding public key to authorized_keys..."
mkdir -p ~/.ssh
cat ~/.ssh/id_ed25519_lab.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

# 4. Check permissions
echo "[*] Verifying permissions..."
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys

# 5. SSH Agent practice
echo "[*] Starting ssh-agent and adding key..."
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_lab

echo "[*] Lab complete. You can now use this key for SSH connections."
