#!/bin/bash
# week-02 Lab Script — File Permissions & Ownership Pt 2
# Author: Gemini CLI (Mentor Mode)
# Focus: SUID, SGID, Sticky Bit, and Umask

DRY_RUN=true

# Helper function for execution
run_cmd() {
    local cmd="$1"
    local desc="$2"
    echo -e "\n[TASK] $desc"
    if [ "$DRY_RUN" = true ]; then
        echo "   (DRY RUN) $cmd"
    else
        echo "   Executing: $cmd"
        eval "$cmd"
    fi
}

echo "Starting Week 02 Lab: Special Permissions & Umask"
echo "Target Device: ThinkPad (t0)"

# Setup practice directory
run_cmd "mkdir -p ~/special-perm-practice" "Creating practice directory"
cd ~/special-perm-practice || exit

# Task 1: Sticky Bit
run_cmd "mkdir shared_tmp && chmod 1777 shared_tmp" "Creating a mock /tmp directory with Sticky Bit"
run_cmd "ls -ld shared_tmp" "Verify Sticky Bit (look for 't' at the end)"

# Task 2: SGID on Directories
run_cmd "mkdir project_delta && sudo chown :sudo project_delta && chmod 2775 project_delta" "Creating SGID directory for group 'sudo'"
run_cmd "ls -ld project_delta" "Verify SGID (look for 's' in the group execute field)"
run_cmd "touch project_delta/test_file && ls -l project_delta/test_file" "Verify new files inherit the 'sudo' group"

# Task 3: SUID (Demonstration only - DO NOT leave random SUID files)
run_cmd "cp /usr/bin/whoami ./whoami_test && chmod u+s ./whoami_test" "Creating a local copy of whoami with SUID"
run_cmd "ls -l whoami_test" "Verify SUID (look for 's' in the owner execute field)"

# Task 4: Umask Experimentation
run_cmd "umask" "Check current umask"
run_cmd "umask 0077 && touch private_file && ls -l private_file" "Testing restrictive umask (0077)"
run_cmd "umask 0002 && touch shared_file && ls -l shared_file" "Testing permissive umask (0002)"

# Task 5: Finding Special Permissions
run_cmd "find /usr/bin -perm /4000 -type f 2>/dev/null | head -n 5" "Searching for SUID files in /usr/bin"
run_cmd "find / -perm /2000 -type f 2>/dev/null | head -n 5" "Searching for SGID files on the system"

echo -e "\n--- Lab Summary ---"
echo "Practiced:"
echo "1. Setting Sticky Bit on shared directories."
echo "2. Implementing SGID for group inheritance."
echo "3. Understanding SUID bits on executables."
echo "4. Manipulating umask for default file permissions."
echo "5. Using 'find' with octal permission masks."
echo "-------------------"
