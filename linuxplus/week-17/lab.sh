#!/bin/bash
# Week 17 Lab: Security Scanning & Auditing

echo "Running Security Scanning Lab..."

# Install tools
echo "Installing nmap and lynis..."
sudo apt update && sudo apt install -y nmap lynis || sudo dnf install -y nmap lynis

# Basic Nmap scans
echo "Scanning localhost for open ports..."
nmap localhost

# Service version detection
echo "Detecting service versions on localhost..."
nmap -sV localhost

# Lynis System Audit
echo "Running Lynis system audit (this may take a few minutes)..."
sudo lynis audit system --quick

# Review Lynis report
echo "Lynis audit complete. Report saved to /var/log/lynis.log"

# SSH Hardening (Check only)
echo "Checking SSH configuration..."
grep -E "PermitRootLogin|PasswordAuthentication" /etc/ssh/sshd_config

# Fail2ban installation
echo "Installing fail2ban..."
sudo apt install -y fail2ban || sudo dnf install -y fail2ban
sudo systemctl enable --now fail2ban
