#!/bin/bash
# Week 2 Lab: Special Permissions & umask

# Create test directory for special permissions
mkdir -p ~/special-perms-test
cd ~/special-perms-test

# SUID Practice
echo "Setting SUID bit..."
touch test_suid
chmod 755 test_suid
chmod u+s test_suid # OR chmod 4755 test_suid
ls -l test_suid # Verify 's' in user position

# SGID Practice
echo "Setting SGID bit..."
mkdir -p shared_project
chmod 2775 shared_project # OR chmod g+s shared_project
ls -ld shared_project # Verify 's' in group position

# Verify SGID inheritance
touch shared_project/test_file
ls -l shared_project/test_file # Should inherit group

# Sticky Bit Practice
echo "Setting Sticky Bit..."
mkdir -p shared_temp
chmod 1777 shared_temp # OR chmod +t shared_temp
ls -ld shared_temp # Verify 't' in others position

# umask Practice
echo "Checking and setting umask..."
umask
# Example: Set umask to 022 for 644/755 defaults
umask 022
touch test_umask_file
ls -l test_umask_file # Should be 644

# Verification
echo "Summary of special permissions in test directory:"
find ~/special-perms-test -type f -perm /6000 -ls 2>/dev/null
ls -l ~/special-perms-test
