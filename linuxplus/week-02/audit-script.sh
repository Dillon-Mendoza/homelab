#!/bin/bash
# Week 02 Audit — Storage Health + Device/Module Sanity
# Re-run anytime. Checks fstab integrity, mount option hygiene, disk/inode
# pressure, and unexpected kernel module state.
# Run on: tp-mudd (Fedora). Adjust filesystem checks for xfs vs ext4 as noted.

PASS=0
WARN=0
INFO=0

pass() { echo "[PASS] $*"; ((PASS++)); }
warn() { echo "[WARN] $*"; ((WARN++)); }
info() { echo "[INFO] $*"; ((INFO++)); }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  AUDIT: Storage Health + Device/Module Sanity"
echo "  Host: $(hostname) | $(date)"
echo "══════════════════════════════════════════════════════"
echo ""

# ── /etc/fstab Integrity ──────────────────────────────────────────────────────
echo "── /etc/fstab Integrity ──"

if [[ -f /etc/fstab ]]; then
    pass "/etc/fstab exists"

    NON_NOFAIL=$(grep -vE '^\s*#|^\s*$' /etc/fstab | awk '{print $1, $2, $4}' | grep -vE 'nofail|^UUID=.*\s/\s' | grep -vE '^\S+\s+/\s')
    if [[ -n "$NON_NOFAIL" ]]; then
        info "Entries without 'nofail' (expected for root/swap, verify others intentionally required at boot):"
        echo "$NON_NOFAIL" | while read -r line; do echo "    $line"; done
    else
        pass "All non-root fstab entries use 'nofail' or are root/swap"
    fi

    UUID_COUNT=$(grep -cE '^\s*UUID=' /etc/fstab)
    DEVPATH_COUNT=$(grep -cE '^\s*/dev/' /etc/fstab)
    info "fstab entries using UUID=: $UUID_COUNT | using raw /dev/ path: $DEVPATH_COUNT"
    if [[ "$DEVPATH_COUNT" -gt 0 ]]; then
        warn "Some fstab entries reference /dev/ paths directly — device letters can shift on reboot, prefer UUID="
    fi
else
    warn "/etc/fstab not found — unexpected on any standard install"
fi

echo ""

# ── Currently Mounted vs. fstab ────────────────────────────────────────────────
echo "── Mount State ──"

MOUNT_FAIL=$(findmnt --verify 2>&1 | grep -i 'fail\|error')
if [[ -z "$MOUNT_FAIL" ]]; then
    pass "findmnt --verify reports no fstab/mount inconsistencies"
else
    warn "findmnt --verify flagged issues:"
    echo "$MOUNT_FAIL" | while read -r line; do echo "    $line"; done
fi

echo ""

# ── Disk Space vs. Inode Usage ─────────────────────────────────────────────────
echo "── Disk Space + Inode Pressure ──"

while read -r fs size used avail pct mount; do
    [[ "$fs" == "Filesystem" ]] && continue
    pct_num=${pct%\%}
    if [[ "$pct_num" -ge 90 ]]; then
        warn "Filesystem $mount is ${pct}% full ($fs)"
    fi
done < <(df -h --output=source,size,used,avail,pcent,target 2>/dev/null | tail -n +2)
pass "Disk space check complete (thresholds: warn at >=90%)"

while read -r fs inodes iused ifree ipct mount; do
    [[ "$fs" == "Filesystem" ]] && continue
    ipct_num=${ipct%\%}
    if [[ "$ipct_num" -ge 90 ]]; then
        warn "Filesystem $mount is at ${ipct} INODE usage ($fs) — df -h space %% may look fine while this is critical"
    fi
done < <(df -i --output=source,itotal,iused,ifree,ipcent,target 2>/dev/null | tail -n +2)
pass "Inode usage check complete (thresholds: warn at >=90%)"

echo ""

# ── LVM Layer Sanity (if present) ─────────────────────────────────────────────
echo "── LVM Sanity ──"

if command -v pvs &>/dev/null; then
    PV_COUNT=$(sudo pvs --noheadings 2>/dev/null | wc -l)
    if [[ "$PV_COUNT" -gt 0 ]]; then
        info "$PV_COUNT physical volume(s) detected"
        VG_ATTR_ISSUES=$(sudo vgs --noheadings -o vg_name,vg_attr 2>/dev/null | grep -vE '\bwz--n-\b')
        if [[ -n "$VG_ATTR_ISSUES" ]]; then
            warn "Volume group(s) with non-standard attributes (check for partial/inactive state):"
            echo "$VG_ATTR_ISSUES"
        else
            pass "All volume groups report standard writable/resizable/allocatable attributes"
        fi
    else
        info "No LVM physical volumes detected on this host — expected if this device boots from a plain partition"
    fi
else
    info "LVM tools (pvs/vgs/lvs) not installed on this host"
fi

echo ""

# ── Kernel Module Sanity ───────────────────────────────────────────────────────
echo "── Kernel Module Sanity ──"

TAINTED=$(cat /proc/sys/kernel/tainted 2>/dev/null)
if [[ "$TAINTED" == "0" ]]; then
    pass "Kernel is not tainted (no out-of-tree or unsigned modules loaded)"
else
    warn "Kernel tainted flag is $TAINTED — a module outside the mainline kernel is loaded (check with 'dmesg | grep -i taint')"
fi

MOD_COUNT=$(lsmod | tail -n +2 | wc -l)
info "$MOD_COUNT kernel modules currently loaded"

echo ""

# ── SUID/SGID on Storage-Relevant Binaries (crossover with Week 1) ────────────
echo "── Storage-Tool Binary Sanity ──"

for bin in mount umount fdisk parted; do
    BINPATH=$(command -v "$bin" 2>/dev/null)
    if [[ -n "$BINPATH" ]]; then
        OWNER=$(stat -c '%U' "$BINPATH")
        if [[ "$OWNER" == "root" ]]; then
            pass "$bin ($BINPATH) owned by root"
        else
            warn "$bin ($BINPATH) is NOT owned by root — owned by $OWNER"
        fi
    else
        info "$bin not found on this host"
    fi
done

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
echo "  Summary: $PASS passed | $WARN warnings | $INFO informational"
if [[ $WARN -gt 0 ]]; then
    echo "  Review WARN items above before moving on."
fi
echo "══════════════════════════════════════════════════════"
echo ""
