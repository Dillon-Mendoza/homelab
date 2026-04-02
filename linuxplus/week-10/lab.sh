#!/bin/bash
# Week 10 Lab: Firewall Configuration with iptables

# 1. View current rules
echo "[*] Listing current iptables rules..."
sudo iptables -L -v -n --line-numbers

# 2. Allow SSH (Port 22)
echo "[*] Allowing SSH (port 22)..."
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 3. Allow Loopback (Localhost)
echo "[*] Allowing loopback interface traffic..."
sudo iptables -A INPUT -i lo -j ACCEPT

# 4. Allow Established/Related Connections
echo "[*] Allowing established and related connections..."
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 5. Practice blocking a specific IP (Example: 100.64.0.30)
echo "[*] Blocking traffic from 100.64.0.30 (Tier 4)..."
sudo iptables -A INPUT -s 100.64.0.30 -j DROP

# 6. Set Default Policy to DROP (CAUTION: Ensure SSH is allowed first!)
# echo "[*] Setting default INPUT policy to DROP..."
# sudo iptables -P INPUT DROP

# 7. Verification
echo "[*] Final iptables ruleset:"
sudo iptables -L -n
