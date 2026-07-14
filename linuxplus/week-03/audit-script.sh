#!/bin/bash
# Week 03 Audit — Network State + DNS Resolution Sanity
# Re-run anytime. Checks interface/route health, DNS resolution chain,
# listening-port hygiene, and name resolution end to end.
# Run on: tp-mudd (Fedora 44) only. No other homelab device needs to be up —
# reachability checks target this host's own gateway and the public internet.

PASS=0
WARN=0
INFO=0

pass() { echo "[PASS] $*"; ((PASS++)); }
warn() { echo "[WARN] $*"; ((WARN++)); }
info() { echo "[INFO] $*"; ((INFO++)); }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  AUDIT: Network State + DNS Resolution Sanity"
echo "  Host: $(hostname) | $(date)"
echo "══════════════════════════════════════════════════════"
echo ""

# ── Interface State ────────────────────────────────────────────────────────────
echo "── Interface State ──"

if ip link show tailscale0 &>/dev/null; then
    TS_STATE=$(ip -br link show tailscale0 | awk '{print $2}')
    if [[ "$TS_STATE" == "UNKNOWN" || "$TS_STATE" == "UP" ]]; then
        pass "tailscale0 present and up (state: $TS_STATE — UNKNOWN is normal for tun devices)"
    else
        warn "tailscale0 exists but state is $TS_STATE"
    fi
    TS_IP=$(ip -br addr show tailscale0 | awk '{print $3}')
    if [[ "$TS_IP" == 100.* ]]; then
        pass "tailscale0 has a CGNAT-range address: $TS_IP"
    else
        warn "tailscale0 address unexpected: ${TS_IP:-none}"
    fi
else
    warn "tailscale0 interface not found — Tailscale down or not installed"
fi

DOWN_IFACES=$(ip -br link | awk '$2 == "DOWN" {print $1}' | grep -v '^lo')
if [[ -n "$DOWN_IFACES" ]]; then
    info "Interfaces administratively/physically down (verify intentional):"
    echo "$DOWN_IFACES" | while read -r line; do echo "    $line"; done
fi

echo ""

# ── Routing ────────────────────────────────────────────────────────────────────
echo "── Routing ──"

if ip route | grep -q '^default'; then
    GW=$(ip route | awk '/^default/ {print $3, "dev", $5; exit}')
    pass "Default route present: via $GW"
else
    warn "No default route — this host cannot reach anything off-subnet"
fi

echo ""

# ── DNS Resolution Chain ───────────────────────────────────────────────────────
echo "── DNS Resolution Chain ──"

if [[ -L /etc/resolv.conf ]]; then
    info "/etc/resolv.conf is a symlink -> $(readlink /etc/resolv.conf) (manager-owned, do not hand-edit)"
else
    info "/etc/resolv.conf is a regular file — verify what manages it before editing"
fi

NS_COUNT=$(grep -c '^nameserver' /etc/resolv.conf 2>/dev/null)
if [[ "$NS_COUNT" -ge 1 ]]; then
    pass "$NS_COUNT nameserver line(s) configured"
    if grep -q '^nameserver 100.100.100.100' /etc/resolv.conf; then
        info "Tailscale MagicDNS (100.100.100.100) is the active resolver — queries forward per tailnet DNS config (Pi-hole on pi-zero)"
    fi
else
    warn "No nameserver lines in /etc/resolv.conf — DNS resolution will fail"
fi

HOSTS_ORDER=$(grep '^hosts:' /etc/nsswitch.conf 2>/dev/null)
if echo "$HOSTS_ORDER" | grep -q 'files'; then
    pass "nsswitch.conf hosts line includes 'files': $HOSTS_ORDER"
else
    warn "nsswitch.conf hosts line missing 'files' — /etc/hosts entries will be ignored: $HOSTS_ORDER"
fi

# Malformed /etc/hosts lines: non-comment lines that don't start with an address-like field
BAD_HOSTS=$(grep -vE '^\s*#|^\s*$' /etc/hosts | awk 'NF < 2 || $1 !~ /^[0-9a-fA-F:.]+$/' )
if [[ -z "$BAD_HOSTS" ]]; then
    pass "/etc/hosts entries are well-formed (address + at least one name)"
else
    warn "/etc/hosts has malformed line(s):"
    echo "$BAD_HOSTS" | while read -r line; do echo "    $line"; done
fi

echo ""

# ── Live Resolution Test ───────────────────────────────────────────────────────
echo "── Live Resolution Test ──"

if getent hosts anthropic.com &>/dev/null; then
    pass "External name resolves through the full NSS chain (getent hosts anthropic.com)"
else
    warn "getent hosts anthropic.com failed — resolution broken at NSS level"
fi

if command -v dig &>/dev/null; then
    DIG_TIME=$(dig +stats anthropic.com 2>/dev/null | awk '/Query time/ {print $4}')
    if [[ -n "$DIG_TIME" ]]; then
        if [[ "$DIG_TIME" -lt 200 ]]; then
            pass "dig query answered in ${DIG_TIME}ms"
        else
            warn "dig query took ${DIG_TIME}ms — slow resolver, check path to Pi-hole"
        fi
    else
        warn "dig produced no stats — resolver may not be answering"
    fi
else
    info "dig not installed (bind-utils on Fedora, dnsutils on Ubuntu)"
fi

echo ""

# ── Listening Ports ────────────────────────────────────────────────────────────
echo "── Listening Ports ──"

# Ports bound to all interfaces (0.0.0.0 or [::]) — each one is exposed on
# every interface the firewall allows. On tp-mudd policy is: no inbound
# except over tailscale0, so wildcard binds deserve a look.
WILDCARD=$(ss -tulnH 2>/dev/null | awk '$5 ~ /^(0\.0\.0\.0|\[::\]):/ {print $1, $5}' | sort -u)
if [[ -n "$WILDCARD" ]]; then
    info "Sockets bound to ALL interfaces (cross-check against this host's firewall policy):"
    echo "$WILDCARD" | while read -r line; do echo "    $line"; done
else
    pass "No sockets bound to wildcard addresses"
fi

LISTEN_COUNT=$(ss -tulnH 2>/dev/null | wc -l)
info "$LISTEN_COUNT listening sockets total — full detail: sudo ss -tulpn"

echo ""

# ── Reachability Spot-Check (this host's own uplink only) ─────────────────────
echo "── Uplink Reachability ──"

GW_IP=$(ip route | awk '/^default/ {print $3; exit}')
if [[ -n "$GW_IP" ]]; then
    if ping -c 1 -W 2 "$GW_IP" &>/dev/null; then
        pass "Default gateway $GW_IP reachable (link + IP layer healthy)"
    else
        warn "Default gateway $GW_IP NOT answering ping — local link problem, look no further out"
    fi
else
    warn "No default gateway to test (no default route)"
fi

if ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
    pass "Internet reachable by IP (1.1.1.1) — combined with the DNS checks above, the full chain is testable"
else
    warn "1.1.1.1 NOT reachable — if the gateway check passed, the problem is upstream of this host"
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
