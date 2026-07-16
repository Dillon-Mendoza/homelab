#!/bin/bash
# Week 07 Audit — Auth Stack + Crypto Posture + Compliance Baseline
# Re-run anytime. Checks PAM/faillock/pwquality state, auditd health, crypto
# policy, TLS trust store, disk-encryption status, and integrity tooling.
# Run on: tp-mudd (Fedora 44) only.

PASS=0
WARN=0
INFO=0

pass() { echo "[PASS] $*"; ((PASS++)); }
warn() { echo "[WARN] $*"; ((WARN++)); }
info() { echo "[INFO] $*"; ((INFO++)); }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  AUDIT: Auth + Crypto + Compliance"
echo "  Host: $(hostname) | $(date)"
echo "══════════════════════════════════════════════════════"
echo ""

# ── PAM / Account Hardening ───────────────────────────────────────────────────
echo "── PAM + Account Hardening ──"

if command -v authselect &>/dev/null; then
    PROFILE=$(authselect current 2>/dev/null | head -1)
    if [[ -n "$PROFILE" ]]; then
        pass "authselect manages PAM: $PROFILE"
    else
        warn "authselect installed but no profile selected — PAM configs may be hand-managed"
    fi
fi

if grep -rq 'pam_faillock' /etc/pam.d/system-auth 2>/dev/null; then
    pass "pam_faillock is in the auth stack (lockout after failed attempts)"
    DENY=$(grep -E '^\s*deny\s*=' /etc/security/faillock.conf 2>/dev/null | tr -d ' ' | cut -d= -f2)
    info "faillock deny threshold: ${DENY:-default (3)}"
else
    warn "pam_faillock not found in system-auth — no failed-login lockout"
fi

MINLEN=$(grep -E '^\s*minlen' /etc/security/pwquality.conf 2>/dev/null | tr -d ' ' | cut -d= -f2)
info "pwquality minlen: ${MINLEN:-default (8)} — complexity enforced at password change"

for f in /etc/security/faillock.conf /etc/security/pwquality.conf; do
    OWNER=$(stat -c '%U %a' "$f" 2>/dev/null)
    [[ "$OWNER" == root* ]] && pass "$f owned by root ($OWNER)" || warn "$f ownership unexpected: $OWNER"
done

echo ""

# ── auditd ────────────────────────────────────────────────────────────────────
echo "── auditd ──"

if systemctl is-active --quiet auditd; then
    pass "auditd is active"
    RULES=$(sudo auditctl -l 2>/dev/null)
    if [[ "$RULES" == "No rules" || -z "$RULES" ]]; then
        info "No custom audit rules loaded (SELinux AVC auditing still works regardless)"
    else
        info "Active audit rules:"
        echo "$RULES" | head -5 | while read -r r; do echo "    $r"; done
    fi
    LEFTOVER=$(sudo auditctl -l 2>/dev/null | grep -c week07)
    if [[ "$LEFTOVER" -eq 0 ]]; then
        pass "No leftover week07 lab rules"
    else
        warn "week07 lab audit rule(s) still loaded — remove: sudo auditctl -W /etc/passwd -p wa -k week07-passwd"
    fi
else
    warn "auditd is NOT active — kernel-level accounting is off"
fi

echo ""

# ── Crypto Posture ────────────────────────────────────────────────────────────
echo "── Crypto Posture ──"

POLICY=$(update-crypto-policies --show 2>/dev/null)
case "$POLICY" in
    DEFAULT|FUTURE|FIPS) pass "System crypto policy: $POLICY (weak algorithms excluded)" ;;
    LEGACY) warn "System crypto policy is LEGACY — old protocols/ciphers re-enabled system-wide; intended?" ;;
    *) info "Crypto policy: ${POLICY:-unknown}" ;;
esac

if rpm -q ca-certificates &>/dev/null; then
    pass "CA trust bundle installed: $(rpm -q ca-certificates)"
else
    warn "ca-certificates package missing — TLS verification will fail broadly"
fi

CRYPT_DEVS=$(lsblk -rno TYPE 2>/dev/null | grep -c crypt)
if [[ "$CRYPT_DEVS" -gt 0 ]]; then
    pass "$CRYPT_DEVS dm-crypt (LUKS) device(s) active — disk encryption in use"
else
    info "No LUKS volumes active — for a laptop that leaves the house, whole-disk encryption is worth a deliberate decision (data-at-rest, objective 3.5)"
fi

GPGKEYS=$(gpg --list-secret-keys 2>/dev/null | grep -c '^sec')
info "$GPGKEYS GPG secret key(s) in your keyring"
LAB_KEY=$(gpg --list-keys week07@lab.local 2>/dev/null | grep -c week07)
if [[ "$LAB_KEY" -eq 0 ]]; then
    pass "No leftover week07 lab GPG keys"
else
    warn "week07 lab GPG key still present — delete it (lab cleanup step 4f)"
fi

echo ""

# ── SSH Crypto Surface ────────────────────────────────────────────────────────
echo "── SSH Algorithm Surface ──"

if sudo sshd -T &>/dev/null; then
    WEAK_C=$(sudo sshd -T 2>/dev/null | awk '$1=="ciphers"{print $2}' | tr ',' '\n' | grep -cE 'cbc|3des|arcfour')
    if [[ "$WEAK_C" -eq 0 ]]; then
        pass "No CBC/3DES/arcfour ciphers offered by sshd"
    else
        warn "$WEAK_C weak cipher(s) in sshd's offer — crypto policy or sshd_config needs attention"
    fi
    WEAK_M=$(sudo sshd -T 2>/dev/null | awk '$1=="macs"{print $2}' | tr ',' '\n' | grep -cE 'md5|sha1[^2-]?$')
    if [[ "$WEAK_M" -eq 0 ]]; then
        pass "No MD5/plain-SHA1 MACs offered by sshd"
    else
        info "$WEAK_M SHA1-family MAC(s) offered (often -etm variants; review against policy)"
    fi
else
    info "sshd not evaluable on this host"
fi

echo ""

# ── Integrity + Compliance Tooling ────────────────────────────────────────────
echo "── Integrity Tooling ──"

if rpm -q aide &>/dev/null; then
    if [[ -f /var/lib/aide/aide.db.gz ]]; then
        DB_AGE=$(( ( $(date +%s) - $(stat -c %Y /var/lib/aide/aide.db.gz) ) / 86400 ))
        if [[ "$DB_AGE" -le 30 ]]; then
            pass "AIDE database present, ${DB_AGE}d old"
        else
            warn "AIDE database is ${DB_AGE}d old — stale baselines hide exactly what AIDE exists to catch"
        fi
    else
        warn "AIDE installed but no database — run: sudo aide --init"
    fi
else
    info "AIDE not installed (optional lab Task 8 covers it)"
fi

RPMV=$(sudo rpm -Va --nofiledigest 2>/dev/null | grep -E '^..5.*bin/' | head -3)
if [[ -z "$RPMV" ]]; then
    pass "No modified binaries detected by rpm -Va (spot check)"
else
    warn "Binaries differing from package database — investigate:"
    echo "$RPMV" | while read -r line; do echo "    $line"; done
fi

BANNER_ISSUE=$(wc -c < /etc/issue 2>/dev/null)
info "/etc/issue: ${BANNER_ISSUE:-0} bytes | /etc/motd: $(wc -c < /etc/motd 2>/dev/null || echo 0) bytes (banner plumbing — content is a policy decision)"

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
echo "  Summary: $PASS passed | $WARN warnings | $INFO informational"
if [[ $WARN -gt 0 ]]; then
    echo "  Review WARN items above before moving on."
fi
echo "══════════════════════════════════════════════════════"
echo ""
