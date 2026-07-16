#!/bin/bash
# Week 06 Audit — Firewall Posture + Container Hygiene + Hardening Baseline
# Re-run anytime. Checks firewalld state vs documented policy, SELinux mode,
# sshd/sudo posture, SUID/world-writable drift, and container leftovers.
# Run on: tp-mudd (Fedora 44) only.

PASS=0
WARN=0
INFO=0

pass() { echo "[PASS] $*"; ((PASS++)); }
warn() { echo "[WARN] $*"; ((WARN++)); }
info() { echo "[INFO] $*"; ((INFO++)); }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  AUDIT: Firewall + Containers + Hardening"
echo "  Host: $(hostname) | $(date)"
echo "══════════════════════════════════════════════════════"
echo ""

# ── Firewall Posture ──────────────────────────────────────────────────────────
echo "── Firewall Posture ──"

if systemctl is-active --quiet firewalld; then
    pass "firewalld is active"

    DEFZONE=$(firewall-cmd --get-default-zone 2>/dev/null)
    info "Default zone: $DEFZONE"

    RUNTIME_PORTS=$(sudo firewall-cmd --list-ports 2>/dev/null)
    PERM_PORTS=$(sudo firewall-cmd --permanent --list-ports 2>/dev/null)
    if [[ "$RUNTIME_PORTS" == "$PERM_PORTS" ]]; then
        pass "Runtime and permanent port lists match (no unsaved/unloaded drift)"
    else
        warn "Runtime ports [$RUNTIME_PORTS] differ from permanent [$PERM_PORTS] — a reload or reboot will change behavior"
    fi

    RUNTIME_SVCS=$(sudo firewall-cmd --list-services 2>/dev/null)
    PERM_SVCS=$(sudo firewall-cmd --permanent --list-services 2>/dev/null)
    if [[ "$RUNTIME_SVCS" == "$PERM_SVCS" ]]; then
        pass "Runtime and permanent service lists match"
    else
        warn "Runtime services [$RUNTIME_SVCS] differ from permanent [$PERM_SVCS]"
    fi

    OPEN_PORTS=$(sudo firewall-cmd --list-ports 2>/dev/null)
    if [[ -z "$OPEN_PORTS" ]]; then
        pass "No raw ports opened in the default zone (tp-mudd policy: no inbound except tailscale0)"
    else
        warn "Ports open in default zone: $OPEN_PORTS — cross-check against documented policy"
    fi
    info "Services allowed in default zone: ${RUNTIME_SVCS:-none}"
else
    warn "firewalld is NOT active — this host's documented policy depends on it"
fi

FWD=$(sysctl -n net.ipv4.ip_forward 2>/dev/null)
if [[ "$FWD" == "0" ]]; then
    pass "ip_forward is 0 — this laptop is not routing (correct: it is not an exit node)"
else
    warn "net.ipv4.ip_forward=1 — this host will forward packets; intended?"
fi

echo ""

# ── SELinux ───────────────────────────────────────────────────────────────────
echo "── SELinux ──"

MODE=$(getenforce 2>/dev/null)
if [[ "$MODE" == "Enforcing" ]]; then
    pass "SELinux is Enforcing"
else
    warn "SELinux mode is $MODE — fleet standard for Fedora hosts is Enforcing"
fi

CFGMODE=$(grep -E '^SELINUX=' /etc/selinux/config 2>/dev/null | cut -d= -f2)
if [[ "$CFGMODE" == "enforcing" ]]; then
    pass "Persistent config also says enforcing (survives reboot)"
else
    warn "/etc/selinux/config says '$CFGMODE' — runtime and boot-time modes will diverge"
fi

AVC_TODAY=$(sudo ausearch -m AVC -ts today 2>/dev/null | grep -c '^type=AVC')
if [[ "$AVC_TODAY" -eq 0 ]]; then
    pass "No AVC denials logged today"
else
    info "$AVC_TODAY AVC denial(s) today — review: sudo ausearch -m AVC -ts today | audit2allow (read, don't apply)"
fi

echo ""

# ── SSH Hardening ─────────────────────────────────────────────────────────────
echo "── SSH Effective Config (sshd -T) ──"

if command -v sshd &>/dev/null && sudo sshd -T &>/dev/null; then
    EFFECTIVE=$(sudo sshd -T 2>/dev/null)
    for kv in "permitrootlogin no" "passwordauthentication no" "x11forwarding no"; do
        key=${kv% *}; want=${kv#* }
        got=$(echo "$EFFECTIVE" | awk -v k="$key" '$1 == k {print $2}')
        if [[ "$got" == "$want" ]]; then
            pass "$key = $got"
        else
            warn "$key = ${got:-unset} (fleet posture expects '$want')"
        fi
    done
else
    info "sshd not available for -T evaluation on this host"
fi

echo ""

# ── sudo Posture ──────────────────────────────────────────────────────────────
echo "── sudo Posture ──"

if sudo visudo -c &>/dev/null; then
    pass "sudoers syntax is valid (visudo -c)"
else
    warn "visudo -c reports sudoers syntax problems — fix before it locks you out"
fi

NOPASSWD=$(sudo grep -rE '^[^#]*NOPASSWD' /etc/sudoers /etc/sudoers.d/ 2>/dev/null)
if [[ -z "$NOPASSWD" ]]; then
    pass "No NOPASSWD grants — every privilege escalation requires authentication"
else
    warn "NOPASSWD grant(s) found:"
    echo "$NOPASSWD" | while read -r line; do echo "    $line"; done
fi

WHEEL=$(getent group wheel | cut -d: -f4)
info "wheel group members: ${WHEEL:-none}"

echo ""

# ── Permission Drift ──────────────────────────────────────────────────────────
echo "── Permission Drift (SUID / world-writable) ──"

SUID_COUNT=$(sudo find /usr -perm -4000 -type f 2>/dev/null | wc -l)
info "$SUID_COUNT SUID binaries under /usr (baseline this number; investigate growth)"

UNEXPECTED_SUID=$(sudo find /home /tmp /var/tmp /opt -perm -4000 -type f 2>/dev/null)
if [[ -z "$UNEXPECTED_SUID" ]]; then
    pass "No SUID files outside system binary directories"
else
    warn "SUID file(s) in user-writable locations — investigate immediately:"
    echo "$UNEXPECTED_SUID" | while read -r f; do echo "    $f"; done
fi

WW_NOSTICKY=$(sudo find /home /var /opt -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null | head -5)
if [[ -z "$WW_NOSTICKY" ]]; then
    pass "No world-writable directories missing the sticky bit (checked /home /var /opt)"
else
    warn "World-writable dir(s) without sticky bit:"
    echo "$WW_NOSTICKY" | while read -r d; do echo "    $d"; done
fi

echo ""

# ── Cleartext Protocol Services ───────────────────────────────────────────────
echo "── Banned Protocols ──"

BAD_PKGS=""
for pkg in telnet-server tftp-server vsftpd; do
    rpm -q "$pkg" &>/dev/null && BAD_PKGS="$BAD_PKGS $pkg"
done
if [[ -z "$BAD_PKGS" ]]; then
    pass "No telnet/tftp/ftp server packages installed"
else
    warn "Cleartext-protocol server(s) installed:$BAD_PKGS — remove unless deliberately required"
fi

echo ""

# ── Container Hygiene ─────────────────────────────────────────────────────────
echo "── Container Hygiene (podman) ──"

if command -v podman &>/dev/null; then
    RUNNING=$(podman ps -q 2>/dev/null | wc -l)
    STOPPED=$(podman ps -aq --filter status=exited 2>/dev/null | wc -l)
    info "$RUNNING running container(s), $STOPPED stopped leftover(s)"
    if [[ "$STOPPED" -gt 0 ]]; then
        warn "Stopped containers accumulate storage — review: podman ps -a; prune: podman container prune"
    fi

    PRIVILEGED=$(podman ps -q 2>/dev/null | while read -r c; do
        [[ "$(podman inspect "$c" --format '{{.HostConfig.Privileged}}' 2>/dev/null)" == "true" ]] && podman inspect "$c" --format '{{.Name}}'
    done)
    if [[ -z "$PRIVILEGED" ]]; then
        pass "No privileged containers running"
    else
        warn "PRIVILEGED container(s) running: $PRIVILEGED — full host capabilities granted"
    fi

    DANGLING=$(podman images -f dangling=true -q 2>/dev/null | wc -l)
    if [[ "$DANGLING" -eq 0 ]]; then
        pass "No dangling image layers"
    else
        info "$DANGLING dangling image layer(s) — reclaim: podman image prune"
    fi
else
    info "podman not installed"
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
