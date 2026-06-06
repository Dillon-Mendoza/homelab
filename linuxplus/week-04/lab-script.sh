#!/bin/bash
# week-04 Lab Script — User & Group Management Pt 2
# Author: Gemini CLI (Mentor Mode)
# Focus: visudo, command restrictions, and sudo auditing.

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

echo "Starting Week 04 Lab: Privilege Escalation & Sudo"
echo "Target Device: ThinkPad (t0)"

# Task 1: Check Current Privileges
run_cmd "sudo -l" "Listing current user's sudo privileges"

# Task 2: Create a restricted sudo rule (Simulation)
# Note: We will create a drop-in file in /etc/sudoers.d/ instead of editing main sudoers.
# This is the modern, professional way to manage sudo rules.
run_cmd "echo 'dev-user ALL=(root) /usr/bin/apt update' | sudo tee /etc/sudoers.d/dev-user-apt" "Creating a restricted rule for dev-user (update only)"

# Task 3: Verify syntax of the new rule
run_cmd "sudo visudo -c" "Checking sudoers syntax for errors"

# Task 4: Simulate a failed privilege attempt
echo -e "\n[TASK] Testing restricted sudo (requires manual intervention)"
echo "   1. Switch to dev-user: 'sudo su - dev-user'"
echo "   2. Try: 'sudo apt update' (Should work)"
echo "   3. Try: 'sudo apt install vim' (Should be denied)"

# Task 5: Enable Sudo Logging (Job Ready: Auditing is key)
# We add a line to a new sudoers.d file to log all sudo output.
run_cmd "echo 'Defaults iolog_file=\"/var/log/sudo-io/%{user}/%02{seq}\"' | sudo tee /etc/sudoers.d/sudo-audit" "Configuring sudo I/O logging"
run_cmd "echo 'Defaults log_output' | sudo tee -a /etc/sudoers.d/sudo-audit" "Enabling output logging"

# Task 6: Cleanup
run_cmd "sudo rm /etc/sudoers.d/dev-user-apt /etc/sudoers.d/sudo-audit" "Cleaning up practice sudo rules"

echo -e "\n--- Lab Summary ---"
echo "Practiced:"
echo "1. Auditing personal sudo rights with 'sudo -l'."
echo "2. Using /etc/sudoers.d/ for modular, manageable rules."
echo "3. Implementing specific command restrictions (Least Privilege)."
echo "4. Validating sudoers syntax with 'visudo -c'."
echo "5. Thinking about the audit trail with I/O logging."
echo "-------------------"
