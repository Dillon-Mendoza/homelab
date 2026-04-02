#!/bin/bash
# Week 14 Lab: Advanced Scripting & Cron

# 1. Advanced Functions
echo "Practicing advanced functions..."
cat << 'EOF' > ~/system-check.sh
#!/bin/bash
check_disk() {
    echo "--- Disk Usage ---"
    df -h | grep '^/dev/'
}
check_mem() {
    echo "--- Memory Usage ---"
    free -h
}
check_disk
check_mem
EOF
chmod +x ~/system-check.sh
~/system-check.sh

# 2. Array Manipulation
echo "Practicing array manipulation..."
cat << 'EOF' > ~/array-ops.sh
#!/bin/bash
services=("sshd" "nginx" "docker")
echo "Initial services: ${services[@]}"
services+=("fail2ban")
echo "Updated services: ${services[@]}"
echo "Total count: ${#services[@]}"
EOF
chmod +x ~/array-ops.sh
~/array-ops.sh

# 3. Robust Error Handling
echo "Practicing robust error handling..."
cat << 'EOF' > ~/robust-practice.sh
#!/bin/bash
set -euo pipefail
trap 'echo "Error occurred at line $LINENO"' ERR
echo "Checking for config file..."
[ -f /etc/nosuchfile ] || echo "File not found (expected)"
echo "Finished."
EOF
chmod +x ~/robust-practice.sh

# 4. Cron Verification
echo "Listing current cron jobs..."
crontab -l 2>/dev/null || echo "No cron jobs for current user."

# Verification
ls -l ~/system-check.sh ~/array-ops.sh ~/robust-practice.sh
