#!/bin/bash
# week-03 Audit Script — User Identity & Security
# Author: Gemini CLI
# Goal: Audit user accounts for common misconfigurations and security risks.

echo "===================================================="
echo "          LINUX+ WEEK 03 SECURITY AUDIT            "
echo "===================================================="
date
echo "Host: $(hostname)"
echo "----------------------------------------------------"

# 1. Audit for UID 0 (Root duplicates)
echo "[1] CHECKING FOR DUPLICATE ROOT ACCOUNTS (UID 0)"
awk -F: '$3 == 0 { print $1 }' /etc/passwd
echo ""

# 2. Audit for accounts without passwords (Security Risk)
echo "[2] CHECKING FOR ACCOUNTS WITH NO PASSWORD"
sudo awk -F: '($2 == "") { print $1 }' /etc/shadow
echo "Note: If output is empty, all accounts have some form of password/lock."
echo ""

# 3. Audit for User Shells (Job Ready: Service accounts should usually be /sbin/nologin)
echo "[3] CHECKING FOR HUMAN-LIKE SHELLS ON SYSTEM USERS (UID < 1000)"
awk -F: '$3 < 1000 && $7 !~ /nologin|false/ { print $1 ":" $3 ":" $7 }' /etc/passwd
echo ""

# 4. Check for Password Aging
echo "[4] PASSWORD AGING FINDINGS (Top 10 users)"
for user in $(cut -d: -f1 /etc/passwd | head -n 10); do
    echo -n "$user: "
    sudo chage -l "$user" | grep "Password expires" | awk -F: '{print $2}'
done
echo ""

# 5. Integrity Check
echo "[5] RUNNING PWCK (Password File Consistency Check)"
sudo pwck -r
echo ""

echo "----------------------------------------------------"
echo "FINDINGS SUMMARY"
echo "Check [1]: Only 'root' should ever have UID 0."
echo "Check [3]: System accounts should not have interactive shells."
echo "Check [5]: Fix any 'inconsistent' errors reported by pwck."
echo "===================================================="
