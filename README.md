# Mudd Labs - Homelab Infrastructure

> *Rooted in craft. Reaching past the last mark*

I'm Dillon, transitioning out of nine years in hospitality into Linux administration and Python development. This repo documents the homelab infrastructure I've built under the **Mudd Labs** brand: the architecture, the hardening decisions, the automation I've written, and the projects I've shipped. It's a working portfolio, not a showcase; everything here was built to solve a real problem or learn something I didn't know yet.

---

## Infrastructure Overview

| Device | Role | OS |
|---|---|---|
| ThinkPad T14 | Dev machine, daily driver | Fedora 43 |
| Dell Server | Hypervisor host → Fedora KVM/QEMU VM (n8n, Gitea), Netdata parent node | Ubuntu 24.04 / Fedora 43 |
| Raspberry Pi 4 | Backup exit node, Netdata child node | Raspberry Pi OS |
| Raspberry Pi Zero 2W | Pi-hole DNS resolver, Netdata child node | Raspberry Pi OS Lite (32-bit) |
| Oracle Cloud (mudd-cloud) | Primary Tailscale exit node | Ubuntu 22.04 |
| Desktop | Parked — no defined role | Windows 11 |

All devices connected via a **Tailscale mesh** running a tiered default-deny ACL I designed and implemented from scratch.

---

## Repository Structure

```
homelab/
├── firewall/          # Per-device firewall hardening runbooks
├── incidents/         # Outage write-ups and post-mortems
├── infrastructure/    # Service and device architecture docs
├── linuxplus/         # Linux+ certification study material
├── projects/          # Automation and tooling projects
└── troubleshooting/   # Issue resolution logs
```

---

## Projects

### Muddroom — Homelab Dashboard
A Django web application serving as a live dashboard for the Mudd Labs mesh.
Displays device reachability, service status, and infrastructure health pulled
from the Tailscale network. Served over `tailscale serve` with HTTPS. Built
as a deliberate portfolio piece — chose Django over pre-built tools (Uptime
Kuma, Dashy) specifically to build real Python web development experience.
→ Active development

### Pi-hole DNS Filtering (tag:dns)
Pi-hole running on the Pi Zero 2W as a dedicated DNS resolver for the
Tailscale mesh. Custom upstream resolver under Tailscale MagicDNS — all
non-`.ts.net` queries route through Pi-hole for filtering and logging before
reaching upstream. Includes a full `tag:dns` ACL, UFW hardening scoped to
`tailscale0`, and `tailscale serve` HTTPS wrapping the admin UI.
→ `infrastructure/pi-hole.md`

### Network Monitor — Discord Webhook Alerts
A Bash + n8n workflow that pings networked devices on a schedule, parses
reachability output, and fires Discord alerts when something goes dark.
The Bash script handles pinging and output formatting; n8n handles conditional
routing and webhook delivery. Built as the first **MuddBuilt** automation gig.
→ `projects/network-monitor/`

### Gitea Push Notifications
An n8n pipeline wired to route Gitea webhook push events to Discord and a
local log file. First real automation built on this stack.
→ `projects/discord-webhook/`

---

## Infrastructure Highlights

- **Tailscale ACL** — tiered default-deny policy across purpose-built device
  tags (`tag:t0`–`tag:t2`, `tag:dns`, `tag:cloud`, `tag:parked`, `tag:guest`).
  Designed the trust hierarchy, wrote the ACL, tested it, broke it once, fixed
  it. Each tag has a defined role and a narrow, justified ruleset.
- **Pi-hole** — mesh-wide DNS filtering via a dedicated `tag:dns` node.
  Integrated as a custom upstream under Tailscale MagicDNS. Full diagnostic
  path documented including interface binding, listening mode configuration,
  and `tcpdump`-based query tracing.
- **Firewall hardening** — every device locked to `tailscale0` only via UFW
  or FirewallD. No services exposed on physical interfaces. Documented per
  device in `firewall/`.
- **n8n** — Dockerized on the Fedora KVM/QEMU VM with SELinux-compatible
  volume mounts. Health check script in crontab.
- **Gitea** — self-hosted, bare metal on the Fedora VM. Internal webhook
  pipeline live. Dual-remote push configured (Gitea + GitHub).
- **Netdata** — parent node on Dell Ubuntu, child nodes on Pi 4 and Pi Zero
  2W. All nodes claimed to Netdata Cloud.
- **Tailscale exit nodes** — primary on Oracle Cloud (mudd-cloud), backup
  on Pi 4. Default-deny ACL with explicit egress grants per tag.

---

## Certifications in Progress

- **CompTIA Linux+** — actively studying; material and study pipeline in `linuxplus/`

---

## About Mudd Labs

Mudd Labs is the brand I built this work under. The mission is simple:
*rooted in craft, reaching past the last mark.* I'm not trying to pass
a test and land a job title — I'm building real infrastructure, documenting
it to production standard, and shipping tools that solve actual problems.
The portfolio speaks for itself or it doesn't. I'm betting on it.