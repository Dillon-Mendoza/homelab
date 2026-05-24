# Mudd Labs - Homelab Infrastructure

> *Rooted in craft. Reaching past the last mark*

I'm Dillon, transitioning out of nine years in hospitality into linux administration and Python development. This repo documents the homelab infrastructure I've built under the **Mudd Labs** brand: the architecture, the hardening decisions, the automation I've written, and the projects I've shipped. It's a working portfolio, not a showcase; everything here was built to solve a real problem or learn something I didn't know yet.

---

## Infrastructure Overview

| Device | Role | OS |
|---|---|---|
| ThinkPad T14 | Dev Machine, daily driver | Fedora 43 |
| Dell Server | Hypervisor host -> Fedora KVM/QEMU VM (n8n, Gitea) | Ubuntu / Fedora |
| Raspberry Pi 4 | Backup exit node, Portainer agent, Netdata | Raspberry Pi OS |
| Raspberry Pi Zero 2 W | Netdata node | Raspberry Pi OS |
| Oracle Cloud (mudd-cloud) | Primary Tailscale exit node | Ubuntu 22.04 |
| Desktop | Parked | Windows 11 |

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

### Network Monitor - Discord Webhook Alerts
A Bash + n8n workflow I built to ping networked devices on a schedule, parse reachability output, and fire Discord alerts when something goes dark.
The bash script handles the pinging and output formatting; n8n handles conditional routing and webhook delivery. Built as the first **MuddBuilt** automation gig.
-> 'projects/network-monitor/'

### Gitea Push Notifications
An n8n pipeline I wired up to route Gitea webhook push events to Discord and a local log file. First real automation I built on this stack.
-> 'projects/discord-webhook/'

---

## Infrastructure Highlights

- **Tailscale ACL** — tiered default-deny policy across six device tags (`t0`–`t3`, `cloud`, `parked`). Designed the trust hierarchy, wrote the ACL, tested it, broke it once, fixed it.
- **Firewall hardening** — every device locked to `tailscale0` only. Documented per device in `firewall/`.
- **n8n** — Dockerized on the Fedora KVM/QEMU VM with SELinux-compatible volume mounts. Health check script in crontab.
- **Gitea** — self-hosted, bare metal on the Fedora VM, internal webhook pipeline live.
- **Netdata** — monitoring nodes running on the Dell, Pi 4, and Pi Zero 2 W.

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
