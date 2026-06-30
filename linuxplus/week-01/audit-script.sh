#!/bin/bash
# Week 01 Audit — Boot Integrity + Shell Environment
# Re-run anytime. Checks boot config integrity, PATH safety, shell config hygiene.
# Run on: tp-mudd (Fedora). Adjust paths for Ubuntu nodes as noted.

PASS=0
WARN=0
INFO=0

pass() { echo "[PASS] $*"; ((PASS++)); }
warn() { echo "[WARN] $*"; ((WARN++)); }
info() { echo "[INFO] $*"; ((INFO++)); }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  AUDIT: Boot Integrity + Shell Environment"
echo "  Host: $(hostname) | $(date)"
echo "══════════════════════════════════════════════════════"
echo ""

# ── GRUB Configuration ────────────────────────────────────────────────────────
echo "── GRUB / Boot Configuration ──"

if [[ -f /boot/grub2/grub.cfg ]]; then
    pass "GRUB config exists at /boot/grub2/grub.cfg"
else
    warn "GRUB config not found at /boot/grub2/grub.cfg (Ubuntu: check /boot/grub/grub.cfg)"
fi

if [[ -f /etc/default/grub ]]; then
    pass "/etc/default/grub exists (user-editable GRUB parameters)"
    TIMEOUT=$(grep '^GRUB_TIMEOUT=' /etc/default/grub | cut -d= -f2)
    info "GRUB_TIMEOUT is set to: ${TIMEOUT:-not set}"
    if grep -q 'rd.break\|init=/bin/bash\|single' /etc/default/grub 2>/dev/null; then
        warn "GRUB_CMDLINE_LINUX contains a debug/emergency boot parameter — confirm this is intentional"
    fi
else
    warn "/etc/default/grub not found"
fi

INITRD="/boot/initramfs-$(uname -r).img"
if [[ -f "$INITRD" ]]; then
    pass "initrd present and matches running kernel: $INITRD"
else
    INITRD_ALT="/boot/initrd.img-$(uname -r)"
    if [[ -f "$INITRD_ALT" ]]; then
        pass "initrd present (Ubuntu path): $INITRD_ALT"
    else
        warn "initrd not found for running kernel $(uname -r) — check /boot/"
    fi
fi

echo ""

# ── Kernel Parameters ─────────────────────────────────────────────────────────
echo "── Kernel Parameters ──"

CMDLINE=$(cat /proc/cmdline)
info "Boot parameters: $CMDLINE"

if echo "$CMDLINE" | grep -qE 'rd.break|init=/bin/bash|emergency|rescue'; then
    warn "Emergency/debug parameter present in active kernel cmdline — expected only during troubleshooting"
else
    pass "No emergency or debug parameters in active kernel cmdline"
fi

echo ""

# ── PATH Safety ───────────────────────────────────────────────────────────────
echo "── PATH Integrity ──"

UNSAFE_PATH=0
IFS=':' read -ra PATHDIRS <<< "$PATH"
for dir in "${PATHDIRS[@]}"; do
    if [[ "$dir" == "." || "$dir" == "" ]]; then
        warn "PATH contains '.' or empty entry — current directory in PATH is a security risk"
        UNSAFE_PATH=1
    fi
    if [[ -d "$dir" && -w "$dir" ]] && [[ "$(stat -c '%U' "$dir")" != "$(whoami)" ]] && [[ "$(stat -c '%U' "$dir")" != "root" ]]; then
        warn "PATH directory $dir is writable by a user other than you or root"
        UNSAFE_PATH=1
    fi
done

if [[ $UNSAFE_PATH -eq 0 ]]; then
    pass "PATH entries appear safe (no '.' and no unexpected writable directories)"
fi

info "Current PATH: $PATH"

echo ""

# ── Shell Config File Permissions ─────────────────────────────────────────────
echo "── Shell Config File Permissions ──"

for cfg in ~/.bashrc ~/.bash_profile ~/.profile; do
    if [[ -f "$cfg" ]]; then
        PERMS=$(stat -c '%a' "$cfg")
        OWNER=$(stat -c '%U' "$cfg")
        if [[ "$PERMS" == "644" || "$PERMS" == "600" || "$PERMS" == "640" ]]; then
            pass "$cfg exists with safe permissions ($PERMS, owned by $OWNER)"
        else
            warn "$cfg has unusual permissions ($PERMS) — should be 644 or 600"
        fi
    else
        info "$cfg does not exist"
    fi
done

GLOBAL_PROFILE="/etc/profile"
if [[ -f "$GLOBAL_PROFILE" ]]; then
    GPERMS=$(stat -c '%a' "$GLOBAL_PROFILE")
    GOWNER=$(stat -c '%U' "$GLOBAL_PROFILE")
    if [[ "$GOWNER" == "root" ]]; then
        pass "/etc/profile owned by root ($GPERMS)"
    else
        warn "/etc/profile is NOT owned by root — owned by $GOWNER"
    fi
fi

echo ""

# ── /tmp Sticky Bit ───────────────────────────────────────────────────────────
echo "── /tmp Configuration ──"

TMP_PERMS=$(stat -c '%a' /tmp)
if [[ "$TMP_PERMS" == "1777" ]]; then
    pass "/tmp has sticky bit set (1777) — world-writable but protected"
else
    warn "/tmp permissions are $TMP_PERMS, expected 1777 with sticky bit"
fi

echo ""

# ── SUID File Inventory ───────────────────────────────────────────────────────
echo "── SUID File Inventory ──"
echo "  (Note: this takes a moment — scanning full filesystem)"

SUID_COUNT=$(find / -perm -4000 -type f 2>/dev/null | wc -l)
info "SUID files found on system: $SUID_COUNT"

echo "  SUID files outside /usr:"
UNEXPECTED_SUID=$(find / -perm -4000 -type f 2>/dev/null | grep -v '^/usr' | grep -v '^/bin' | grep -v '^/sbin')
if [[ -z "$UNEXPECTED_SUID" ]]; then
    pass "No unexpected SUID files outside standard system directories"
else
    warn "SUID files found in unexpected locations:"
    echo "$UNEXPECTED_SUID" | while read -r f; do echo "    $f"; done
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
echo "  Summary: $PASS passed | $WARN warnings | $INFO informational"
if [[ $WARN -gt 0 ]]; then
    echo "  Review WARN items above before moving on."
fi
echo "══════════════════════════════════════════════════════"
echo ""
