#!/bin/bash

HOSTS_FILE="$HOME/homelab/hosts.txt"
SCRIPT="$HOME/homelab/ufw_check.sh"

while IFS= read -r host; do
    [[ -z "$host" || "$host" =~ ^# ]] && continue

    echo "===== $host ====="

    scp "$SCRIPT" "$host:~/ufw_check.sh" && \
    ssh "$host" << 'EOF'
        chmod 700 ~/ufw_check.sh
        ~/ufw_check.sh
EOF

done < "$HOSTS_FILE"
