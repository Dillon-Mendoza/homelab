#!/bin/bash
# Week 13 Lab: Advanced Scripting & Cron

# 1. Functions Practice
echo "Creating functions practice script..."
cat << 'EOF' > ~/functions-practice.sh
#!/bin/bash
check_service() {
    local service=$1
    if systemctl is-active --quiet $service; then
        echo "✓ $service is running"
    else
        echo "✗ $service is NOT running"
    fi
}
check_service sshd
EOF
chmod +x ~/functions-practice.sh
~/functions-practice.sh

# 2. Arrays Practice
echo "Creating arrays practice script..."
cat << 'EOF' > ~/arrays-practice.sh
#!/bin/bash
devices=("laptop" "pi4" "pi-zero" "fedora")
for device in "${devices[@]}"; do
    echo "Processing: $device"
done
EOF
chmod +x ~/arrays-practice.sh
~/arrays-practice.sh

# 3. Error Handling Practice
echo "Creating error handling practice script..."
cat << 'EOF' > ~/error-handling-practice.sh
#!/bin/bash
set -e
trap 'echo "An error occurred or script exited."' EXIT
echo "This script will exit if a command fails."
ls /nonexistent_folder_xyz 2>/dev/null || echo "Caught expected failure (if not using set -e)"
EOF
chmod +x ~/error-handling-practice.sh

# 4. Cron Practice
echo "Adding a test cron job (runs every 5 minutes)..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /bin/date >> /tmp/cron-test.log") | crontab -
echo "Cron job added. Check /tmp/cron-test.log in 5 minutes."

# Verification
echo "Verifying scripts exist..."
ls -l ~/functions-practice.sh ~/arrays-practice.sh ~/error-handling-practice.sh
crontab -l | grep "cron-test.log"
