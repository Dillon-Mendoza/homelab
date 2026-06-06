#!/bin/bash
# week-04 Audit Script — Privilege Escalation & Sudo Security
# Author: Gemini CLI
# Goal: Audit sudoers and related configs for security risks.

echo "===================================================="
echo "          LINUX+ WEEK 04 SECURITY AUDIT            "
echo "===================================================="
date
echo "Host: $(hostname)"
echo "----------------------------------------------------"

# 1. Check for anyone who can run ANY command without a password
echo "[1] USERS WITH NOPASSWD: ALL (High Risk)"
sudo grep -ri "NOPASSWD: ALL" /etc/sudoers /etc/sudoers.d/
echo ""

# 2. Check for broad sudo access (The wheel/sudo groups)
echo "[2] MEMBERS OF PRIVILEGED GROUPS (wheel/sudo)"
echo -n "Wheel: "
getent group wheel | cut -d: -f4
echo -n "Sudo: "
getent group sudo | cut -d: -f4
echo ""

# 3. Check for specific dangerous commands in sudoers
# Look for editors (vi, nano), shells (bash, sh), or find (can execute commands)
echo "[3] DANGEROUS COMMANDS GRANTED IN SUDOERS (Potential Escapes)"
sudo grep -riE "vi|nano|sh|bash|find|python|perl" /etc/sudoers /etc/sudoers.d/ | grep -v "#"
echo ""

# 4. Sudoers Syntax Integrity
echo "[4] SUDOERS SYNTAX CHECK"
sudo visudo -c
echo ""

# 5. Check for sudo binary permissions (Should be 4111 or 4755)
echo "[5] SUDO BINARY PERMISSIONS"
ls -l /usr/bin/sudo
echo ""

echo "----------------------------------------------------"
echo "FINDINGS SUMMARY"
echo "Check [1]: NOPASSWD: ALL should be extremely rare."
echo "Check [3]: If a user can run 'sudo vi', they can escape to a"
echo "           root shell by typing ':!/bin/bash' inside vi."
echo "===================================================="
