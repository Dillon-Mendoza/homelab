#!/bin/bash
# Week 04 Audit — Account Hygiene + File Ownership Sanity
# Re-run anytime. Checks account database integrity, password aging posture,
# shells, home directory permissions, and orphaned files.
# Run on: tp-mudd (Fedora 44) only.

PASS=0
WARN=0
INFO=0

pass() { echo "[PASS] $*"; ((PASS++)); }
warn() { echo "[WARN] $*"; ((WARN++)); }
info() { echo "[INFO] $*"; ((INFO++)); }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  AUDIT: Account Hygiene + File Ownership"
echo "  Host: $(hostname) | $(date)"
echo "══════════════════════════════════════════════════════"
echo ""

# ── Account Database Integrity ────────────────────────────────────────────────
echo "── Account Database Integrity ──"

UID0=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
if [[ "$UID0" == "root" ]]; then
    pass "Exactly one UID-0 account, and it is root"
else
    warn "UID-0 accounts found: $UID0 — any non-root UID-0 account IS root by another name"
fi

DUP_UID=$(awk -F: '{print $3}' /etc/passwd | sort | uniq -d)
if [[ -z "$DUP_UID" ]]; then
    pass "No duplicate UIDs in /etc/passwd"
else
    warn "Duplicate UID(s): $DUP_UID — two names, one kernel identity"
fi

DUP_USER=$(awk -F: '{print $1}' /etc/passwd | sort | uniq -d)
if [[ -z "$DUP_USER" ]]; then
    pass "No duplicate usernames in /etc/passwd"
else
    warn "Duplicate username(s): $DUP_USER"
fi

if command -v pwck &>/dev/null; then
    if sudo pwck -r &>/dev/null; then
        pass "pwck -r reports passwd/shadow structurally consistent"
    else
        warn "pwck -r flagged inconsistencies — run 'sudo pwck -r' to see them"
    fi
fi

echo ""

# ── Critical File Permissions ─────────────────────────────────────────────────
echo "── passwd / shadow / group Permissions ──"

check_perms() {
    local f=$1 expected=$2
    local actual owner
    actual=$(stat -c '%a' "$f")
    owner=$(stat -c '%U' "$f")
    if [[ "$actual" == "$expected" && "$owner" == "root" ]]; then
        pass "$f is $actual, owned by root"
    else
        warn "$f is $actual owned by $owner — expected $expected owned by root"
    fi
}
check_perms /etc/passwd 644
check_perms /etc/group 644
check_perms /etc/shadow 0

echo ""

# ── Password State ────────────────────────────────────────────────────────────
echo "── Password State (shadow) ──"

EMPTY_PW=$(sudo awk -F: '$2 == "" {print $1}' /etc/shadow)
if [[ -z "$EMPTY_PW" ]]; then
    pass "No accounts with EMPTY password fields (empty = login with no password at all)"
else
    warn "Accounts with empty password field: $EMPTY_PW"
fi

LOCKED=$(sudo awk -F: '$2 ~ /^!/ {print $1}' /etc/shadow | wc -l)
NOPASS=$(sudo awk -F: '$2 == "*" {print $1}' /etc/shadow | wc -l)
info "$LOCKED account(s) locked (! prefix) | $NOPASS with no password ever set (*)"

echo ""

# ── Password Aging Posture ────────────────────────────────────────────────────
echo "── Password Aging (regular users, UID >= 1000) ──"

while IFS=: read -r user _ uid _; do
    if [[ "$uid" -ge 1000 && "$uid" -lt 65000 ]]; then
        MAXDAYS=$(sudo awk -F: -v u="$user" '$1 == u {print $5}' /etc/shadow)
        if [[ -z "$MAXDAYS" || "$MAXDAYS" == "99999" || "$MAXDAYS" == "" ]]; then
            info "$user has no password expiry (max age ${MAXDAYS:-unset}) — deliberate on a key-auth laptop, but know that chage -M would set it"
        else
            pass "$user password max age: $MAXDAYS days"
        fi
    fi
done < /etc/passwd

DEFMAX=$(grep -E '^PASS_MAX_DAYS' /etc/login.defs | awk '{print $2}')
info "login.defs default PASS_MAX_DAYS for NEW accounts: ${DEFMAX:-unset}"

echo ""

# ── Shells ────────────────────────────────────────────────────────────────────
echo "── Shell Assignments ──"

SYS_WITH_SHELL=$(awk -F: '$3 < 1000 && $3 > 0 && $7 !~ /(nologin|false|sync|shutdown|halt)/ {print $1 " (" $7 ")"}' /etc/passwd)
if [[ -z "$SYS_WITH_SHELL" ]]; then
    pass "No system accounts (UID 1-999) hold a real login shell"
else
    warn "System account(s) with a usable shell — service accounts should be nologin:"
    echo "$SYS_WITH_SHELL" | while read -r line; do echo "    $line"; done
fi

INVALID_SHELLS=$(awk -F: '$7 != "" {print $7}' /etc/passwd | sort -u | while read -r sh; do
    [[ "$sh" =~ nologin|false ]] && continue
    [[ -x "$sh" ]] || echo "$sh"
done)
if [[ -z "$INVALID_SHELLS" ]]; then
    pass "Every assigned login shell exists and is executable"
else
    warn "Shell(s) assigned in passwd that do not exist: $INVALID_SHELLS"
fi

echo ""

# ── Home Directories ──────────────────────────────────────────────────────────
echo "── Home Directories ──"

while IFS=: read -r user _ uid _ _ home shell; do
    [[ "$uid" -lt 1000 || "$uid" -ge 65000 ]] && continue
    if [[ ! -d "$home" ]]; then
        warn "$user's home $home does not exist"
        continue
    fi
    OWNER=$(stat -c '%U' "$home")
    PERMS=$(stat -c '%a' "$home")
    if [[ "$OWNER" != "$user" ]]; then
        warn "$home is owned by $OWNER, not $user"
    elif [[ "${PERMS: -1}" =~ [2367] ]]; then
        warn "$home is world-writable ($PERMS) — anyone can plant files there"
    else
        pass "$home exists, owned by $user, mode $PERMS"
    fi
done < /etc/passwd

echo ""

# ── Orphaned Files ────────────────────────────────────────────────────────────
echo "── Orphaned Files (no valid owner — leftovers of deleted accounts) ──"

ORPHANS=$(sudo find /home /tmp /var/tmp -xdev \( -nouser -o -nogroup \) 2>/dev/null | head -10)
if [[ -z "$ORPHANS" ]]; then
    pass "No files without a valid owner/group in /home, /tmp, /var/tmp"
else
    warn "Orphaned files found (userdel without -r leaves these):"
    echo "$ORPHANS" | while read -r f; do echo "    $f"; done
fi

echo ""

# ── Dangling Symlinks in /etc ─────────────────────────────────────────────────
echo "── Dangling Symlinks (/etc) ──"

DANGLING=$(find /etc -xtype l 2>/dev/null | head -10)
if [[ -z "$DANGLING" ]]; then
    pass "No dangling symlinks under /etc"
else
    info "Dangling symlink(s) under /etc — often harmless (alternatives leftovers), verify each:"
    echo "$DANGLING" | while read -r l; do echo "    $l -> $(readlink "$l")"; done
fi

echo ""

# ── Login Activity ────────────────────────────────────────────────────────────
echo "── Login Activity ──"

NEVER=$(lastlog 2>/dev/null | grep -c 'Never logged in')
info "$NEVER account(s) have never logged in (mostly service accounts — expected)"
info "Most recent logins:"
last -n 3 2>/dev/null | head -3 | while read -r line; do echo "    $line"; done

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
echo "  Summary: $PASS passed | $WARN warnings | $INFO informational"
if [[ $WARN -gt 0 ]]; then
    echo "  Review WARN items above before moving on."
fi
echo "══════════════════════════════════════════════════════"
echo ""
