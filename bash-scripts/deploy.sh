#!/bin/bash

cat ~/homelab/hosts.txt | grep -v "^#" | while read host; do
    scp ~/homelab/ufw_check.sh "$host":~/ufw_check.sh
    ssh "$host" "chmod 700 ~/ufw_check.sh"
    ssh "$host" "~/ufw_check.sh"
done