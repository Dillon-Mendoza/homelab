#!/bin/bash
# Week 15 Lab: APT Package Management

# 1. Update and List
echo "Updating package lists..."
sudo apt update

echo "Listing upgradable packages..."
apt list --upgradable

# 2. Search and Show
echo "Searching for 'nginx'..."
apt search nginx | head -n 5

echo "Showing details for 'tree'..."
apt show tree

# 3. Install and Remove
echo "Installing 'tree' and 'htop'..."
sudo apt install -y tree htop

echo "Verifying installation..."
which tree
tree --version

echo "Removing 'tree' (keeping config)..."
sudo apt remove -y tree

echo "Purging 'htop' (removing config)..."
sudo apt purge -y htop

# 4. dpkg Practice
echo "Listing files in 'nginx' (if installed)..."
dpkg -L nginx 2>/dev/null || echo "nginx is not installed."

echo "Finding which package owns /usr/bin/curl..."
dpkg -S /usr/bin/curl

# 5. Clean up
echo "Cleaning up package cache..."
sudo apt autoremove -y
sudo apt clean

# Verification
echo "Lab completed."
