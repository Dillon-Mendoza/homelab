#!/bin/bash
# Week 8 Lab: Creating a Custom Systemd Service

# 1. Create a simple monitoring script
echo "[*] Creating monitoring script..."
cat <<EOF > ~/lab-monitor.sh
#!/bin/bash
while true; do
    echo "\$(date): Lab check - System is UP" >> /tmp/lab-monitor.log
    sleep 60
done
EOF
chmod +x ~/lab-monitor.sh

# 2. Create a systemd service unit file
echo "[*] Creating systemd service unit file..."
cat <<EOF | sudo tee /etc/systemd/system/lab-monitor.service > /dev/null
[Unit]
Description=Lab Monitoring Service
After=network.target

[Service]
Type=simple
User=$(whoami)
ExecStart=$(readlink -f ~/lab-monitor.sh)
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 3. Reload systemd and start service
echo "[*] Reloading systemd and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable --now lab-monitor.service

# 4. Verify service status
echo "[*] Checking service status..."
systemctl status lab-monitor.service --no-pager

# 5. Check logs
echo "[*] Checking service logs..."
sudo journalctl -u lab-monitor.service -n 5 --no-pager

echo "[*] Lab complete. Use 'sudo systemctl stop lab-monitor.service' to stop."
