#!/bin/bash
# week-01/audit-script.sh — Permissions Audit
# A focused tool to identify permission-based risks on the local system.

echo "--- PERMISSIONS AUDIT: $(hostname) ---"
echo "Date: $(date)"

# 1. World-Writable Directories (Excluding sticky-bit dirs like /tmp)
echo -e "\n[FINDINGS] World-Writable Directories (No Sticky Bit):"
echo "--------------------------------------------------------"
# Finds dirs that are world-writable (o+w) but do not have the sticky bit (+t)
find / -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | sed 's/^/  [!] /'

# 2. SUID/SGID Files
echo -e "\n[FINDINGS] SUID/SGID Files (Potential Elevation Paths):"
echo "--------------------------------------------------------"
# SUID = 4000, SGID = 2000
find /usr/bin /usr/sbin -xdev -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -n 20 | sed 's/^/  [*] /'
echo "  (Limited to first 20 entries in /usr/bin and /usr/sbin)"

# 3. Sensitive Configuration Files
echo -e "\n[FINDINGS] Critical File Check:"
echo "-------------------------------"
check_perm() {
    local file="$1"
    if [ -f "$file" ]; then
        local p=$(stat -c "%a %U:%G" "$file")
        echo "  $file: $p"
    fi
}

check_perm "/etc/shadow"
check_perm "/etc/sudoers"
check_perm "/etc/passwd"

echo -e "\nAudit Complete."
