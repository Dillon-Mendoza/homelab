#!/bin/bash
# Week 6 Lab: SSH Hardening & Client Configuration

# 1. Backup SSHD configuration
echo "[*] Backing up /etc/ssh/sshd_config..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# 2. Test SSH configuration syntax
echo "[*] Testing SSH configuration syntax..."
sudo sshd -t
if [ $? -eq 0 ]; then
    echo "Configuration is valid."
else
    echo "Configuration error detected!"
fi

# 3. Create sample client config
echo "[*] Creating sample ~/.ssh/config..."
cat <<EOF > ~/.ssh/config_sample
Host lab-server
    HostName 127.0.0.1
    User $(whoami)
    Port 22
    IdentityFile ~/.ssh/id_ed25519_lab
EOF
chmod 600 ~/.ssh/config_sample
echo "Sample config created at ~/.ssh/config_sample"

# 4. Check firewall rules (UFW or Firewalld)
if command -v ufw >/dev/null; then
    echo "[*] Checking UFW status..."
    sudo ufw status
elif command -v firewall-cmd >/dev/null; then
    echo "[*] Checking Firewalld status..."
    sudo firewall-cmd --list-all
fi

echo "[*] Lab complete."
