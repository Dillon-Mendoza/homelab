#!/bin/bash
# week-03 Lab Script — User & Group Management Pt 1
# Author: Gemini CLI (Mentor Mode)
# Focus: Creating, modifying, and auditing users and groups.

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

echo "Starting Week 03 Lab: User & Group Management"
echo "Target Device: ThinkPad (t0)"

# Task 1: Create a Job-Specific Group
run_cmd "sudo groupadd developers" "Creating a 'developers' group for the team"

# Task 2: Create a New User with specific requirements
# -m: home dir, -s: shell, -c: comment (GECOS), -G: secondary group
run_cmd "sudo useradd -m -s /bin/bash -c 'New Developer' -G developers dev-user" "Creating a new developer account"

# Task 3: Verify user creation in /etc/passwd and /etc/group
run_cmd "grep dev-user /etc/passwd" "Verifying /etc/passwd entry"
run_cmd "grep developers /etc/group" "Verifying /etc/group entry"

# Task 4: Set Password Aging (Professional Standard)
# -M: max days, -m: min days, -W: warn days
run_cmd "sudo chage -M 90 -m 7 -W 14 dev-user" "Enforcing 90-day password rotation"
run_cmd "sudo chage -l dev-user" "Listing password aging status"

# Task 5: Modify User (Add to another group)
run_cmd "sudo usermod -aG developers $(whoami)" "Adding current user to the developers group"
run_cmd "groups $(whoami)" "Verifying current user's group memberships"

# Task 6: Identity switching (Testing environment)
echo -e "\n[MANUAL TASK] Try switching to the new user:"
echo "   Command: sudo su - dev-user"
echo "   Note: Run 'whoami' and 'id' once logged in."

# Cleanup (Optional)
# run_cmd "sudo userdel -r dev-user && sudo groupdel developers" "Cleaning up practice accounts"

echo -e "\n--- Lab Summary ---"
echo "Practiced:"
echo "1. Creating groups for role-based access control."
echo "2. Provisioning users with specific shells and comments."
echo "3. Implementing security via password aging policies."
echo "4. Modifying existing accounts with 'usermod'."
echo "5. Verifying system identity files."
echo "-------------------"
