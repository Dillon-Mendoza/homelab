#!/bin/bash
STATUS=$(sudo ufw status)

if echo "$STATUS" | grep -q "inactive"; then
    echo "UFW is inactive! Re-enabling..."
    sudo ufw enable
    RECHECK=$(ufw status)

    if echo "$RECHECK" | grep -q "inactive"; then
        echo "Failed to enable UFW. Please check configuration and enable manually."
        else
            echo "UFW successfully enabled."
        fi

    
else
    echo "UFW is active. All good!"
fi