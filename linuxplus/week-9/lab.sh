#!/bin/bash
# Week 9 Lab: Networking Basics & Troubleshooting

# Check network interfaces and IP addresses
echo "[*] Listing network interfaces..."
ip addr show

# Check routing table
echo "[*] Checking routing table..."
ip route show

# Test connectivity to gateway
GATEWAY=$(ip route | grep default | awk '{print $3}')
if [ -n "$GATEWAY" ]; then
    echo "[*] Pinging gateway: $GATEWAY"
    ping -c 4 "$GATEWAY"
fi

# Test DNS and internet connectivity
echo "[*] Pinging Google DNS (8.8.8.8)..."
ping -c 4 8.8.8.8

echo "[*] Pinging google.com (Testing DNS)..."
ping -c 4 google.com

# Trace route to google.com
echo "[*] Running traceroute to google.com..."
traceroute google.com || traceroute -I google.com

# List listening ports
echo "[*] Listing listening TCP/UDP ports..."
ss -tulpn
