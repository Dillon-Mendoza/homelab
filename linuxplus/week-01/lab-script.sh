#!/bin/bash
# week-01/lab-script.sh — File Permissions & Ownership
# Author: Gemini CLI (Mentor Mode)
# Objective: Practical application of octal/symbolic modes and directory access logic.

DRY_RUN=false

# Helper function to handle execution/dry-run
exec_cmd() {
    local cmd="$1"
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] $cmd"
    else
        echo "Executing: $cmd"
        eval "$cmd"
    fi
}

echo "--- Week 1 Session B: Permissions Lab ---"

# Task 1: Create Practice Environment
echo "Task 1: Creating practice directory tree..."
exec_cmd "mkdir -p ~/permission-practice/dir1/subdir"
exec_cmd "touch ~/permission-practice/file1.txt ~/permission-practice/dir1/file2.txt"

# Task 2: Apply Octal Permissions
echo -e "\nTask 2: Applying octal permissions..."
# Standard file: rw-r--r--
exec_cmd "chmod 644 ~/permission-practice/file1.txt"
# Private file: rw-------
exec_cmd "chmod 600 ~/permission-practice/dir1/file2.txt"
# Standard dir: rwxr-xr-x
exec_cmd "chmod 755 ~/permission-practice/dir1"

# Task 3: Test Directory 'x' bit logic
echo -e "\nTask 3: Testing the 'Execute' bit on directories..."
echo "Removing execute bit from ~/permission-practice/dir1..."
exec_cmd "chmod 644 ~/permission-practice/dir1"
echo "Testing: Attempting to cd into dir1 (This should fail if DRY_RUN=false)..."
if [ "$DRY_RUN" = false ]; then
    cd ~/permission-practice/dir1 2>/dev/null || echo "PASS: Access denied as expected."
fi
# Restore
exec_cmd "chmod 755 ~/permission-practice/dir1"

# Task 4: Symbolic Updates
echo -e "\nTask 4: Using symbolic mode for targeted changes..."
exec_cmd "chmod g+w ~/permission-practice/file1.txt" # Add write to group
exec_cmd "chmod o-r ~/permission-practice/file1.txt" # Remove read from others

# Task 5: Verification
echo -e "\nTask 5: Final Verification..."
exec_cmd "ls -laR ~/permission-practice"

echo -e "\n--- Lab Complete ---"
echo "Practiced: mkdir -p, chmod octal (644, 600, 755), chmod symbolic (g+w, o-r), and directory 'x' bit logic."
