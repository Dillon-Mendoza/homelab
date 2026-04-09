#!/bin/bash
# Week 1 Lab: File Permissions & Ownership

# Create practice directory
mkdir -p ~/permission-practice
cd ~/permission-practice

# Create initial files and directories
touch file1.txt file2.txt file3.txt
mkdir -p dir1 dir2

# Numeric chmod practice
echo "Setting numeric permissions..."
chmod 755 file1.txt # rwxr-xr-x
chmod 644 file2.txt # rw-r--r--
chmod 600 file3.txt # rw-------

# Verify permissions
ls -l

# Symbolic chmod practice
echo "Applying symbolic permissions..."
chmod u+x file1.txt # Add execute for user
chmod g-w file2.txt # Remove write for group
chmod o-r file3.txt # Remove read for others

# Shared folder practice
mkdir -p shared_folder
touch shared_folder/team_file.txt
chmod 775 shared_folder # Owner and group can write

# Verification
echo "Verifying results..."
ls -ld shared_folder
ls -l ~/permission-practice
stat file1.txt
