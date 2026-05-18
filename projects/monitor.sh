#!/bin/bash

while IFS= read -r line; do
    device=$(echo $line | cut -d ',' -f 1)
    ip=$(echo $line | cut -d ',' -f 2)
    ping $ip -c 3
    if [ $? -eq 0 ]; then
        echo "CONFIRMED | $device | $ip"
    else
        echo "UNCONFIRMED | $device | $ip"
    fi
done < client.conf