#!/bin/bash
# Week 05 Audit — Service Health + Process Hygiene + Package Sanity
# Re-run anytime. Checks failed/masked units, zombie and runaway processes,
# scheduling state, package verification, and journal persistence.
# Run on: tp-mudd (Fedora 44) only.

PASS=0
WARN=0
INFO=0

pass() { echo "[PASS] $*"; ((PASS++)); }
warn() { echo "[WARN] $*"; ((WARN++)); }
info() { echo "[INFO] $*"; ((INFO++)); }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  AUDIT: Services + Processes + Packages"
echo "  Host: $(hostname) | $(date)"
echo "══════════════════════════════════════════════════════"
echo ""

# ── Unit Health ───────────────────────────────────────────────────────────────
echo "── systemd Unit Health ──"

FAILED=$(systemctl --failed --no-legend 2>/dev/null | awk '{print $1}')
if [[ -z "$FAILED" ]]; then
    pass "No units in failed state"
else
    warn "Failed unit(s) — diagnose with 'systemctl status <unit>' and 'journalctl -u <unit>':"
    echo "$FAILED" | while read -r u; do echo "    $u"; done
fi

MASKED=$(systemctl list-unit-files --state=masked --no-legend 2>/dev/null | awk '{print $1}' | grep -vE '^(ctrl-alt-del|.*@)' | head -10)
if [[ -n "$MASKED" ]]; then
    info "Masked unit(s) — each was a deliberate decision; confirm you remember why:"
    echo "$MASKED" | while read -r u; do echo "    $u"; done
else
    info "No masked units beyond systemd defaults"
fi

ENABLED_NOT_RUNNING=$(systemctl list-unit-files --state=enabled --type=service --no-legend 2>/dev/null | awk '{print $1}' | while read -r u; do
    systemctl is-active --quiet "$u" 2>/dev/null || echo "$u"
done | head -8)
if [[ -n "$ENABLED_NOT_RUNNING" ]]; then
    info "Enabled but not currently active (normal for oneshot/conditional units — verify intent):"
    echo "$ENABLED_NOT_RUNNING" | while read -r u; do echo "    $u"; done
fi

echo ""

# ── Process Hygiene ───────────────────────────────────────────────────────────
echo "── Process Hygiene ──"

ZOMBIES=$(ps aux | awk '$8 ~ /^Z/ {print $2}' | wc -l)
if [[ "$ZOMBIES" -eq 0 ]]; then
    pass "No zombie processes"
else
    warn "$ZOMBIES zombie(s) present — find the parent with 'ps -o ppid= -p <zpid>' and fix/restart it"
    ps aux | awk '$8 ~ /^Z/ {print "    PID " $2 " (" $11 ")"}'
fi

DSTATE=$(ps aux | awk '$8 ~ /^D/ {print $2}' | wc -l)
if [[ "$DSTATE" -eq 0 ]]; then
    pass "No processes stuck in uninterruptible I/O sleep (D state)"
else
    warn "$DSTATE process(es) in D state — persistent D states point at a storage/IO problem"
fi

info "Top 3 CPU consumers right now:"
ps aux --sort=-%cpu | head -4 | tail -3 | awk '{printf "    %s%% %s (%s)\n", $3, $11, $1}'
info "Top 3 memory consumers right now:"
ps aux --sort=-%mem | head -4 | tail -3 | awk '{printf "    %s%% %s (%s)\n", $4, $11, $1}'

NPROC=$(nproc)
LOAD1=$(awk '{print $1}' /proc/loadavg)
if awk -v l="$LOAD1" -v n="$NPROC" 'BEGIN {exit !(l < n)}'; then
    pass "1-min load average $LOAD1 is below CPU count ($NPROC)"
else
    warn "1-min load average $LOAD1 meets/exceeds CPU count ($NPROC) — investigate with top/pidstat"
fi

echo ""

# ── Scheduling State ──────────────────────────────────────────────────────────
echo "── Scheduling ──"

if systemctl is-active --quiet crond; then
    pass "crond is active"
else
    warn "crond is NOT active — user crontabs and /etc/cron.* will not fire"
fi

CRONLINES=$(crontab -l 2>/dev/null | grep -cvE '^\s*#|^\s*$')
info "Your user crontab has ${CRONLINES:-0} active line(s)"

TIMERS=$(systemctl list-timers --no-legend 2>/dev/null | wc -l)
info "$TIMERS system timer(s) scheduled — review: systemctl list-timers"

STALE_CRON=$(crontab -l 2>/dev/null | grep -E 'week0[0-9]|/tmp/' )
if [[ -n "$STALE_CRON" ]]; then
    warn "Crontab contains lab/tmp entries — leftovers from a lab session?"
    echo "$STALE_CRON" | while read -r line; do echo "    $line"; done
else
    pass "No leftover lab entries in your crontab"
fi

echo ""

# ── Package Sanity ────────────────────────────────────────────────────────────
echo "── Package Sanity ──"

GPGOFF=$(grep -l 'gpgcheck=0' /etc/yum.repos.d/*.repo 2>/dev/null)
if [[ -z "$GPGOFF" ]]; then
    pass "Every enabled repo file enforces gpgcheck"
else
    warn "gpgcheck=0 found in: $GPGOFF — packages from these repos install unverified"
fi

THIRDPARTY=$(ls /etc/yum.repos.d/*.repo 2>/dev/null | grep -vE 'fedora|updates' | head -5)
if [[ -n "$THIRDPARTY" ]]; then
    info "Third-party repo file(s) present — each one is trusted code by definition:"
    echo "$THIRDPARTY" | while read -r r; do echo "    $r"; done
fi

info "Last 3 package transactions (dnf history):"
sudo dnf history 2>/dev/null | head -5 | tail -3 | while read -r line; do echo "    $line"; done

VERIFY=$(sudo rpm -V openssh-server 2>/dev/null | grep -v '^..5....T.*c ')
if [[ -z "$VERIFY" ]]; then
    pass "rpm -V openssh-server: no unexpected changes to package files (config edits excluded)"
else
    warn "openssh-server files differ from the package database (review — config edits are normal, binary changes are not):"
    echo "$VERIFY" | head -5 | while read -r line; do echo "    $line"; done
fi

echo ""

# ── Journal Configuration ─────────────────────────────────────────────────────
echo "── Journal ──"

if [[ -d /var/log/journal ]]; then
    pass "Journal is persistent (/var/log/journal exists) — logs survive reboots"
else
    warn "Journal is volatile (no /var/log/journal) — logs vanish at reboot; 'mkdir /var/log/journal' + restart journald to persist"
fi

info "Journal disk usage: $(journalctl --disk-usage 2>/dev/null | grep -o '[0-9.]*[MG]' | head -1 || echo 'unknown')"

ERRCOUNT=$(journalctl -b -p err --no-pager 2>/dev/null | wc -l)
info "$ERRCOUNT journal line(s) at priority err+ this boot — review: journalctl -b -p err"

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
echo "  Summary: $PASS passed | $WARN warnings | $INFO informational"
if [[ $WARN -gt 0 ]]; then
    echo "  Review WARN items above before moving on."
fi
echo "══════════════════════════════════════════════════════"
echo ""
