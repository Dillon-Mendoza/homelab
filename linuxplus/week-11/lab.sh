#!/bin/bash
# Week 11 Lab: Logging and rsyslog Configuration

# 1. Basic journalctl usage
echo "[*] Viewing last 20 journal entries..."
journalctl -n 20

echo "[*] Viewing logs for the rsyslog service..."
journalctl -u rsyslog -n 20

# 2. Local log file inspection
echo "[*] Checking common log locations..."
ls -lh /var/log/messages /var/log/syslog /var/log/auth.log /var/log/secure 2>/dev/null

# 3. Generating test logs with logger
echo "[*] Generating test log messages..."
logger "TEST MESSAGE: Week 11 Lab - Simple test"
logger -p user.info "TEST MESSAGE: Info level test"
logger -p user.err -t MYAPP "TEST MESSAGE: Error level test with tag"

# 4. rsyslog configuration (Check listening ports)
echo "[*] Checking if rsyslog is listening on port 514..."
ss -tulpn | grep 514

# 5. Check firewall for syslog port (UDP/TCP 514)
if command -v firewall-cmd >/dev/null; then
    echo "[*] Checking Firewalld rules..."
    sudo firewall-cmd --list-all | grep 514
fi

# 6. kernel logs
echo "[*] Viewing recent kernel messages (dmesg)..."
dmesg | tail -n 10
