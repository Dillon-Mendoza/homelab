#!/bin/bash

# Install dependencies for health check project

echo "Checking operating system..."

OS_ID=$(cat /etc/os-release | grep "^ID=" | cut -d= -f2)

echo "Detected Operating System: $OS_ID"
echo "Installing dependencies for health check project..."


if [[ $OS_ID == "fedora" ]]; then
    echo "Installing dependencies for Fedora!"
    sudo dnf install sysstat bc -y
elif [[ $OS_ID == "ubuntu" ]]; then
    echo "Installing dependencies for Ubuntu!"
    sudo apt install sysstat bc -y
else
    echo "Unsupported operating system: $OS_ID"
    echo "Please install sysstat and bc manually for your OS."
fi