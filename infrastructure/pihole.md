# Pi Zero 2W — Pi-hole DNS Node Setup
**Date:** June–July 2026
**Device:** mini-mudd (Raspberry Pi Zero 2W)
**Role:** Dedicated Pi-hole DNS resolver for the Tailscale mesh

---

## Overview

Mini-mudd was re-flashed and repurposed from an undefined "network sentinel"
role into a dedicated DNS filtering node for the Tailscale mesh. Pi-hole runs
as the custom upstream resolver under Tailscale MagicDNS — MagicDNS remains
authoritative for `.ts.net` resolution, Pi-hole handles and filters everything
else.

**Query path:**
```
Mesh device → MagicDNS (100.100.100.100) → Pi-hole (mini-mudd) → Cloudflare (1.1.1.1)
```

---

## Why Re-flash to Pi OS Lite

Pi OS Full was running at idle with ~148Mi available and 196Mi already in
swap — before Pi-hole was even installed. On 512MB total RAM, swap thrashing
on a microSD card would cause DNS timeouts under real mesh load.

Re-flashing to Pi OS Lite (32-bit) brought idle memory to ~300Mi available
and ~14Mi in swap. Verified via `free -h` before and after.

**Why 32-bit over 64-bit:**
The Pi Zero 2W's ARM Cortex-A53 is 64-bit capable, but 32-bit userspace has
a smaller memory footprint per process. On 512MB RAM, every MB matters.

---

## Pi-hole Installation

Used the official kickstart installer:

```bash
curl -sSL https://install.pi-hole.net | bash
```

**Install choices:**
- Upstream DNS: Cloudflare (1.1.1.1)
- Interface: tailscale0 (see pihole.toml configuration below)
- Logging: Show everything (full domain + client logging for visibility
  during learning and debugging phase)
- Blocking: Enabled

---

## Critical: pihole.toml Configuration

The installer defaults to `wlan0` as the listening interface and `LOCAL`
as the listening mode. Both must be changed for mesh-only DNS to work.

**Problem:** With default settings, Pi-hole bound to `wlan0` and rejected
queries from Tailscale's `100.x.x.x` CGNAT range as "non-local network."
Confirmed via `pihole tail`:

```
ignoring query from non-local network <tailscale-ip> (logged only once)
```

**Fix in `/etc/pihole/pihole.toml`:**

```toml
# Change from wlan0 to tailscale0
interface = "tailscale0"

# Change from LOCAL to BIND
# BIND mode: accept queries only on the specified interface
listeningMode = "BIND"
```

After editing:

```bash
sudo systemctl restart pihole-FTL
```

**Why BIND mode:**
`LOCAL` mode only accepts queries from subnets attached to a local interface.
Since `tailscale0` wasn't Pi-hole's configured interface, the Tailscale CGNAT
range looked non-local. `BIND` mode binds FTL to the specified interface and
accepts queries arriving on it regardless of subnet.

---

## Diagnostic: Finding the Interface Problem

`tcpdump` confirmed packets were arriving on `tailscale0` but receiving no
response — Pi-hole was swallowing queries without answering:

```bash
sudo tcpdump -i tailscale0 port 53
```

Output showed inbound queries from mesh devices but zero response packets.
This pointed to Pi-hole receiving queries but failing to respond — not a
firewall or ACL issue.

`pihole tail` then showed the explicit rejection message, confirming the
`LOCAL` mode + wrong interface combination was the root cause.

---

## UFW Rules

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 22 proto tcp   # SSH — management only
sudo ufw allow in on tailscale0 to any port 53 proto udp   # DNS
sudo ufw allow in on tailscale0 to any port 53 proto tcp   # DNS
sudo ufw allow in on tailscale0 to any port 80 proto tcp   # Pi-hole admin UI
sudo ufw enable
```

All rules scoped to `tailscale0` only. No services exposed on physical
interfaces. Admin UI (port 80) accessible from the mesh only.

---

## Tailscale Serve (HTTPS for Admin UI)

Pi-hole's admin UI runs on HTTP by default. Wrapped in `tailscale serve`
for TLS encryption, even within the mesh:

```bash
tailscale serve --bg http://localhost:80
```

Admin UI accessible at:
```
https://mini-mudd.<tailnet-name>.ts.net/admin
```

Tailscale handles TLS cert automatically. The `--bg` flag runs it
persistently in the background.

---

## Netdata Child Node

Mini-mudd runs as a Netdata child node reporting to `dell-ubuntu` as parent.
Installed via Netdata kickstart script and claimed to Netdata Cloud.

**Known issue:** `go.d.plugin` crashes on 32-bit ARM with:
```
panic: unaligned 64-bit atomic operation
```
This is a known incompatibility between Go's 64-bit atomic operations and
32-bit userspace. Fixed by disabling the plugin:

```bash
sudo chmod -x /usr/libexec/netdata/plugins.d/go.d.plugin
sudo systemctl restart netdata
```

Netdata child node functions correctly without `go.d.plugin`.

**Memory under full load (Pi-hole + Netdata):**
~200-220Mi available, ~40Mi swap. Stable under real mesh DNS traffic.

---

## Password Management

Pi-hole v6 uses `pihole setpassword` (not `pihole -a -p` from v5):

```bash
pihole setpassword
```

Prompts interactively. Run immediately after install — the auto-generated
password is shown only once during installation.

---

## Troubleshooting Reference

**DNS queries timing out:**
1. Check UFW: `sudo ufw status verbose` — confirm port 53 open on tailscale0
2. Check packets arriving: `sudo tcpdump -i tailscale0 port 53`
3. Check Pi-hole logs: `sudo pihole tail`
4. Verify interface binding in `/etc/pihole/pihole.toml`

**"ignoring query from non-local network" in pihole tail:**
- Root cause: `listeningMode = "LOCAL"` rejecting CGNAT addresses
- Fix: Change to `listeningMode = "BIND"` and set `interface = "tailscale0"`

**Admin UI unreachable:**
- Confirm port 80 open on tailscale0 in UFW
- Confirm `tailscale serve` is running: `tailscale serve status`

**SSH host key mismatch after re-flash:**
- Expected after re-flashing — device generates new host key
- Fix: `ssh-keygen -R <hostname-or-ip>`
- Re-accept fingerprint on next connection