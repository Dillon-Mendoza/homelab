#!/bin/bash
# Week 10 Audit — System Health Baseline (tp-mudd)
# Re-run anytime. This is the week's diagnostic toolkit turned into a standing
# check: units, disk/inodes, deleted-open files, memory/swap/OOM, pressure,
# process states, DNS stack, routing, link errors, journal errors.
# Run it BEFORE something breaks — a baseline you know beats one you guess.
# Run on: tp-mudd (Fedora 44) only. Uses sudo only where noted; degrades
# gracefully without it.

PASS=0
WARN=0
INFO=0

pass() { echo "[PASS] $*"; ((PASS++)); }
warn() { echo "[WARN] $*"; ((WARN++)); }
info() { echo "[INFO] $*"; ((INFO++)); }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  AUDIT: System Health Baseline — $(hostname)"
echo "  $(date) | up: $(uptime -p)"
echo "══════════════════════════════════════════════════════"
echo ""

# ── systemd Health ────────────────────────────────────────────────────────────
echo "── systemd Health ──"

FAILED=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
if [[ "$FAILED" -eq 0 ]]; then
    pass "No failed units"
else
    warn "$FAILED failed unit(s) — diagnose with: systemctl status <unit>; journalctl -u <unit>"
    systemctl --failed --no-legend | awk '{print "    " $1}' | head -5
fi

ERRCOUNT=$(journalctl -b -p err -q --no-pager 2>/dev/null | wc -l)
if [[ "$ERRCOUNT" -eq 0 ]]; then
    pass "Zero err-priority journal lines this boot"
elif [[ "$ERRCOUNT" -le 25 ]]; then
    info "$ERRCOUNT err-priority journal lines this boot — triage: journalctl -b -p err"
else
    warn "$ERRCOUNT err-priority journal lines this boot — something is noisy: journalctl -b -p err"
fi

CORES=$(coredumpctl list --no-legend 2>/dev/null | wc -l)
if [[ "$CORES" -eq 0 ]]; then
    pass "No recorded core dumps (no recent segfaults)"
else
    info "$CORES core dump(s) recorded — inspect with: coredumpctl list | tail"
fi

echo ""

# ── Storage ───────────────────────────────────────────────────────────────────
echo "── Storage: Blocks, Inodes, Ghosts ──"

DISK_HOT=$(df -h --output=pcent,target -x tmpfs -x devtmpfs -x overlay 2>/dev/null | tail -n +2 | tr -dc '0-9%/a-zA-Z \n' | awk '$1+0 >= 85 {print "    " $0}')
if [[ -z "$DISK_HOT" ]]; then
    pass "All real filesystems under 85% block usage"
else
    warn "Filesystem(s) at/over 85% — next: du -xsh /* then lsof +L1"
    echo "$DISK_HOT"
fi

INODE_HOT=$(df -i --output=ipcent,target -x tmpfs -x devtmpfs -x overlay 2>/dev/null | tail -n +2 | awk '$1+0 >= 85 {print "    " $0}')
if [[ -z "$INODE_HOT" ]]; then
    pass "All real filesystems under 85% inode usage (df -i — the Week 10 reflex)"
else
    warn "Inode usage at/over 85% — 'No space left' incoming despite free blocks:"
    echo "$INODE_HOT"
fi

GHOSTS=$(lsof +L1 2>/dev/null | awk 'NR>1 && $7+0 > 104857600 {print $1, $2, int($7/1048576)"MB"}' | sort -u | head -3)
if [[ -z "$GHOSTS" ]]; then
    pass "No deleted-but-open files over 100MB holding disk space"
else
    warn "Deleted-but-open file(s) >100MB — df and du will disagree until the holder exits:"
    echo "$GHOSTS" | while read -r l; do echo "    $l"; done
fi

echo ""

# ── Memory + Pressure ─────────────────────────────────────────────────────────
echo "── Memory, Swap, Pressure ──"

AVAIL_PCT=$(free | awk '/^Mem:/ {printf "%d", $7/$2*100}')
if [[ "$AVAIL_PCT" -ge 20 ]]; then
    pass "Memory: ${AVAIL_PCT}% available (the column that matters — not 'free')"
else
    warn "Memory: only ${AVAIL_PCT}% available — check ps aux --sort=-%mem | head"
fi

SWAP_USED=$(free -m | awk '/^Swap:/ {print $3}')
if [[ -z "$SWAP_USED" || "$SWAP_USED" -eq 0 ]]; then
    pass "No swap in use"
elif [[ "$SWAP_USED" -lt 512 ]]; then
    info "${SWAP_USED}MB swap used — fine if si/so are zero: vmstat 1 3"
else
    warn "${SWAP_USED}MB swap used — if vmstat si/so are nonzero, RAM is exhausted"
fi

OOM=$(journalctl -k -b -g -i 'out of memory' -q --no-pager 2>/dev/null | wc -l)
if [[ "$OOM" -eq 0 ]]; then
    pass "No OOM-killer events this boot"
else
    warn "$OOM OOM-killer event(s) this boot — victims listed in: journalctl -k -g -i oom"
fi

for res in cpu memory io; do
    AVG10=$(awk -F'avg10=' '/^some/ {print $2+0}' /proc/pressure/$res 2>/dev/null)
    if [[ -z "$AVG10" ]]; then
        info "PSI not readable for $res"
    elif (( $(echo "$AVG10 < 5" | bc -l) )); then
        pass "PSI $res: some avg10=${AVG10}% — no meaningful stall pressure"
    else
        warn "PSI $res: some avg10=${AVG10}% — tasks are stalling on $res right now"
    fi
done

echo ""

# ── Processes ─────────────────────────────────────────────────────────────────
echo "── Process States ──"

LOAD1=$(awk '{print $1}' /proc/loadavg)
NPROC=$(nproc)
if (( $(echo "$LOAD1 < $NPROC" | bc -l) )); then
    pass "Load $LOAD1 on $NPROC cores — headroom"
else
    warn "Load $LOAD1 on $NPROC cores — if CPU is idle too, suspect I/O (vmstat: b, wa)"
fi

ZOMBIES=$(ps -eo stat= | grep -c '^Z' )
if [[ "$ZOMBIES" -eq 0 ]]; then
    pass "No zombie processes"
else
    warn "$ZOMBIES zombie(s) — kill the PARENT, not the zombie: ps -eo pid,ppid,stat,cmd | awk '\$3~/^Z/'"
fi

DSTATE=$(ps -eo stat= | grep -c '^D')
if [[ "$DSTATE" -eq 0 ]]; then
    pass "No uninterruptible (D-state) processes"
else
    warn "$DSTATE D-state process(es) — stuck on I/O; these inflate load and ignore SIGKILL"
fi

echo ""

# ── Network + DNS Stack ───────────────────────────────────────────────────────
echo "── Network + DNS Stack ──"

if ip route show default | grep -q .; then
    pass "Default route present: $(ip route show default | head -1)"
else
    warn "No default route — nothing off-box will work: ip route / nmcli device status"
fi

IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
if [[ -n "$IFACE" ]]; then
    DROPS=$(ip -s link show "$IFACE" 2>/dev/null | awk '/RX:/{getline; rx=$4} /TX:/{getline; tx=$4} END{print rx+tx}')
    if [[ "${DROPS:-0}" -eq 0 ]]; then
        pass "No RX/TX drops on $IFACE"
    else
        info "$DROPS dropped packet(s) on $IFACE since boot — watch trend, not the absolute"
    fi
fi

if [[ "$(readlink /etc/resolv.conf)" == *"stub-resolv.conf"* ]]; then
    pass "/etc/resolv.conf is the systemd-resolved stub symlink (Fedora's expected shape)"
else
    warn "/etc/resolv.conf is NOT the expected stub symlink — was it replaced? (lab Task 4 restore: ln -sfn ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf)"
fi

if getent hosts fedoraproject.org >/dev/null 2>&1; then
    pass "Name resolution working (getent → nsswitch → resolved path)"
else
    warn "getent resolution FAILED — isolate: dig fedoraproject.org @1.1.1.1 (works = local resolver fault)"
fi

echo ""

# ── Security-Signal Sweep (5.4) ───────────────────────────────────────────────
echo "── Security Signals ──"

if command -v ausearch &>/dev/null; then
    AVC=$(sudo -n ausearch -m AVC -ts today 2>/dev/null | grep -c '^type=AVC')
    if ! sudo -n true 2>/dev/null; then
        info "SELinux denial check needs sudo — run: sudo ausearch -m AVC -ts today"
    elif [[ "$AVC" -eq 0 ]]; then
        pass "No SELinux AVC denials today"
    else
        warn "$AVC AVC denial(s) today — context, boolean, or policy: sealert -a /var/log/audit/audit.log"
    fi
fi

LEGACY=$(ss -tlnH 2>/dev/null | awk '{split($4,a,":"); p=a[length(a)]} p==21||p==23||p==69 {print p}' | sort -u)
if [[ -z "$LEGACY" ]]; then
    pass "No insecure legacy protocols listening (telnet/ftp/tftp)"
else
    warn "Legacy protocol port(s) listening: $LEGACY — these should not exist"
fi

FAILED_LOGINS=$(journalctl -b -q --no-pager _COMM=sshd -g 'Failed password' 2>/dev/null | wc -l)
if [[ "$FAILED_LOGINS" -eq 0 ]]; then
    pass "No failed SSH password attempts this boot"
else
    info "$FAILED_LOGINS failed SSH login line(s) this boot — expected noise if exposed; review sources"
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
echo "  Summary: $PASS passed | $WARN warnings | $INFO informational"
if [[ $WARN -gt 0 ]]; then
    echo "  Each WARN above names its next diagnostic command — that IS the week."
fi
echo "══════════════════════════════════════════════════════"
echo ""
