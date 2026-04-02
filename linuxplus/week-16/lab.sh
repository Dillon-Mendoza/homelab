#!/bin/bash
# Week 16 Lab: DNF and RPM Package Management

# Note: This lab is designed for Fedora-based systems
echo "Running Package Management Lab..."

# Update package list and upgrade system
sudo dnf check-update
sudo dnf upgrade -y

# Search for packages
dnf search nginx
dnf info nginx

# Install common utilities
sudo dnf install -y htop ncdu curl wget tree

# Verify installation
which tree
tree --version

# DNF History practice
echo "Checking DNF history..."
dnf history | head -n 10

# Package provides practice
echo "Checking which package provides /usr/bin/wget..."
dnf provides /usr/bin/wget

# RPM low-level practice
echo "Listing installed packages with rpm..."
rpm -qa | grep -E 'htop|ncdu|tree'

# Check package info with rpm
rpm -qi tree
rpm -ql tree

# Clean cache
sudo dnf clean all
