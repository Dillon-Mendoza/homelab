#!/bin/bash
# week-02 Audit Script — Special Permissions Security
# Author: Gemini CLI
# Goal: Audit for potentially insecure special bits and world-writable locations.

echo "===================================================="
echo "          LINUX+ WEEK 02 SECURITY AUDIT            "
echo "===================================================="
date
echo "Host: $(hostname)"
echo "----------------------------------------------------"

# 1. Audit SUID Files
echo "[1] TOP 20 SUID FILES (Root Owned)"
find / -perm /4000 -user root -type f 2>/dev/null | head -n 20
echo ""

# 2. Audit SGID Files
echo "[2] SGID FILES (Potential privilege escalation)"
find / -perm /2000 -type f 2>/dev/null | head -n 10
echo ""

# 3. Audit World-Writable Directories (Missing Sticky Bit)
echo "[3] WORLD-WRITABLE DIRECTORIES (MISSING STICKY BIT)"
echo "Finding directories that anyone can write to but don't restrict deletion..."
find / -perm -0002 -type d ! -perm -1000 2>/dev/null
echo ""

# 4. Current Umask
echo "[4] CURRENT SESSION UMASK"
UMASK_VAL=$(umask)
echo "Current Umask: $UMASK_VAL"
if [ "$UMASK_VAL" == "0002" ] || [ "$UMASK_VAL" == "0022" ]; then
    echo "Status: Standard (Safe for general use)"
elif [ "$UMASK_VAL" == "0077" ]; then
    echo "Status: Restrictive (Highly Secure)"
else
    echo "Status: Non-standard ($UMASK_VAL) - Review ~/.bashrc"
fi
echo ""

echo "----------------------------------------------------"
echo "FINDINGS SUMMARY"
echo "Check [3] for any unexpected directories. World-writable dirs"
echo "without the sticky bit allow any user to delete any file"
echo "inside, which is a major security risk (e.g., /tmp must have it)."
echo "===================================================="
