# Incident Report: Tailscale ACL Exit Node Outage
**Date:** 2026-05-03  
**Severity:** Network-wide — all non-ThinkPad devices lost internet  
**Root Cause:** Missing `autogroup:internet` grant in Tailscale ACL blocked exit node forwarding  
**Status:** Resolved
 
---
 
## Summary
 
After implementing a tiered default-deny Tailscale ACL, all devices routing through the Pi 4 exit node lost internet access. DNS resolved correctly, the LAN was healthy, and the gateway was reachable — but no traffic could reach the public internet. The fix was adding a single ACL grant permitting all tagged devices to forward traffic through `autogroup:internet`.
 
A secondary issue was discovered: the Fedora VM had gone offline during the outage and required a Tailscale daemon restart to re-establish its connection and pull the updated ACL rules.
 
---
 
## What Was Affected
 
| Device | Tag | Impact |
|---|---|---|
| ThinkPad T14 | tag:t0 | Unaffected — not using exit node |
| Pi 4 | tag:t2 | Unaffected — IS the exit node |
| Dell Ubuntu Host | tag:t1 | No internet |
| Dell Fedora VM | tag:t1 | No internet + Tailscale went offline |
| Inspiron 5593 | tag:t1 | No internet |
| Pi Zero 2 W | tag:t3 | No internet |
 
---
 
## Diagnostic Process
 
### Step 1 — Establish what works and what doesn't
 
The first clue was that the ThinkPad and Pi 4 were unaffected. The Pi 4 is the exit node. Every other device routes traffic through it. This meant the problem was somewhere in that forwarding path.
 
```bash
# Test if the internet is reachable at all (hostname)
curl -I https://google.com --max-time 5
 
# Test if the internet is reachable by IP (bypasses DNS)
curl -4 -I https://8.8.8.8 --max-time 5
```
 
**What to look for:**
- If hostname works but IP doesn't → DNS is fine, routing is broken
- If both fail → routing is broken or internet is genuinely down
- If IP works but hostname doesn't → DNS is the problem
 
---
 
### Step 2 — Rule out DNS
 
```bash
dig archive.ubuntu.com
dig archive.ubuntu.com @8.8.8.8
```
 
**What to look for:**
- `status: NOERROR` with IPs in ANSWER SECTION → DNS working
- First works, second times out → system resolver fine, routing is the issue
 
---
 
### Step 3 — Rule out local firewall
 
```bash
sudo ufw status verbose
```
 
**What to look for:**
- `Default: deny (outgoing)` → UFW blocking all outbound
- `Default: allow (outgoing)` → UFW not the problem
 
---
 
### Step 4 — Rule out routing and gateway
 
```bash
ip route show default
ping -c 4 192.168.1.1
```
 
**What to look for:**
- No default route → traffic has nowhere to go
- Gateway responds but internet doesn't → problem is upstream or in Tailscale
 
---
 
### Step 5 — Inspect Tailscale routing table
 
This was the command that cracked the case.
 
```bash
ip route show table 52
```
 
**What this is:** Tailscale maintains its own routing table (table 52) separate from the system table. When a device uses an exit node, Tailscale injects a `default` route into table 52 sending all traffic through the exit node peer.
 
**What to look for:**
- `default dev tailscale0` → ALL internet traffic going through the exit node
- No default entry → device not using an exit node
 
**What we saw:**
```
default dev tailscale0
100.70.136.32 dev tailscale0   ← Pi 4 (exit node)
```
 
Every device had `default dev tailscale0` — all internet traffic routing through the Pi 4. ACL wasn't permitting that forwarding so traffic disappeared.
 
---
 
## Root Cause
 
`autogroup:internet` represents traffic destined for the public internet via an exit node. Without an explicit grant, exit node forwarding is silently blocked even if peer-to-peer grants exist.
 
**The missing grant:**
```json
{
    "src": ["tag:t0", "tag:t1", "tag:t2", "tag:t3", "tag:parked", "tag:guest", "tag:cloud"],
    "dst": ["autogroup:internet"],
    "ip":  ["*"],
}
```
 
---
 
## Secondary Issue: Fedora VM Tailscale Offline
 
The Fedora VM is a KVM guest — its traffic path goes through the Dell Ubuntu host. When internet broke, it lost its path to the Tailscale coordination server and dropped offline, operating on a stale cached ACL. Physical LAN devices tolerate this better than VMs behind a host NAT layer.
 
**Fix:**
```bash
sudo systemctl restart tailscaled && sudo tailscale down && sudo tailscale up
```
 
**Key insight:** Any time a VM is offline during an ACL change, restart the daemon before diagnosing anything else.
 
---
 
## Commands Reference
 
| Command | Purpose |
|---|---|
| `curl -4 https://ifconfig.me` | Show current public IPv4 |
| `curl -6 https://ifconfig.me` | Show current public IPv6 |
| `curl -4 -I https://hostname --max-time 5` | Test HTTPS reachability, force IPv4 |
| `dig hostname` | Resolve hostname using system DNS |
| `dig hostname @8.8.8.8` | Resolve using specific DNS server |
| `sudo ufw status verbose` | Show UFW rules and default policies |
| `ip route show default` | Show system default route |
| `ip route show table 52` | Show Tailscale's internal routing table |
| `ping -c 4 192.168.1.1` | Test LAN gateway connectivity |
| `tailscale status` | Show all peers and connection state |
| `tailscale status \| grep "exit node"` | Filter for exit node status |
| `sudo tailscale set --exit-node=NAME` | Set active exit node |
| `sudo tailscale set --exit-node=` | Remove exit node |
| `sudo tailscale down && sudo tailscale up` | Restart Tailscale connection |
| `sudo systemctl restart tailscaled` | Full daemon restart for stale nodes |
 
---
 
## Lessons Learned
 
1. `autogroup:internet` is required for exit node forwarding — peer grants alone are not enough.
2. Active nodes receive ACL updates automatically. Stale/offline nodes need a daemon restart.
3. `ip route show table 52` is the first Tailscale diagnostic command to run.
4. VMs drop off Tailscale faster than physical devices during network disruptions.
5. Always diagnose layer by layer: DNS → routing → firewall → application.
6. Always use `curl -4` or `curl -6` when testing exit nodes — mixed address families make results misleading.
 
---
 
## Updated ACL (Post-Fix)
 
```json
"grants": [
    {
        "src": ["tag:t0"],
        "dst": ["*"],
        "ip":  ["*"],
    },
    {
        "src": ["tag:t1"],
        "dst": ["tag:t2", "tag:t3", "tag:parked", "tag:guest"],
        "ip":  ["*"],
    },
    {
        "src": ["tag:t2"],
        "dst": ["tag:t3", "tag:parked", "tag:guest"],
        "ip":  ["*"],
    },
    {
        "src": ["tag:t0", "tag:t1", "tag:t2", "tag:t3", "tag:parked", "tag:guest", "tag:cloud"],
        "dst": ["autogroup:internet"],
        "ip":  ["*"],
    },
    {
        "src": ["tag:guest"],
        "dst": ["tag:t1"],
        "ip":  ["tcp:3000"],
    },
],
```
 
---
 
*Filed under: homelab/incidents*
 
