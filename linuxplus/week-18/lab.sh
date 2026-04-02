#!/bin/bash
# Week 18 Lab: SELinux Basics & Troubleshooting

echo "Running SELinux Lab..."

# Check status
echo "Checking SELinux status..."
sestatus
getenforce

# View contexts
echo "Viewing file contexts in /var/www/html (if exists)..."
ls -Z /var/www/html/ 2>/dev/null || ls -Z /var/www/ 2>/dev/null

echo "Viewing process contexts for sshd..."
ps -eZ | grep sshd

# Change mode temporarily
echo "Setting SELinux to Permissive mode..."
sudo setenforce 0
getenforce
echo "Setting SELinux back to Enforcing mode..."
sudo setenforce 1
getenforce

# Booleans practice
echo "Listing HTTP-related booleans..."
getsebool -a | grep httpd

# Troubleshooting practice
echo "Searching for recent SELinux denials..."
sudo ausearch -m avc -ts recent 2>/dev/null || echo "No recent denials found or audit log inaccessible."
