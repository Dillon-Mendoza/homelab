# Device Inventory

**Last updated** 2026-05-26
**Maintainer:** Mudd Labs

---

## Overview

This document tracks all physical and cloud devices in the Mudd Labs homelab - hardware specs, OS, installed services, Tailscale tag, and current status

---

## Devices

### ThinkPad T14

| Field | Value |
|---|---|
| **Role** | Dev Machine / Daily Driver |
| **Tailscale Tag** | `tag:t0` |
| **Status** | Active |

**Hardware**

| Component | Detail |
|---|---|
| CPU | AMD Ryzen 7 PRO 5850U |
| RAM | 32GB|
| Storage | 1 TB NVMe |

**OS**

| Partition | OS |
|---|---|
| Primary | Fedora 43 |
| Secondary | Windows 11 |

**Services / Software**

- Primary development environment
- Tailscale client (mesh anchor)
- FirewallD - no inbound rules; SSH inbound removed

---

### Dell Server - `dell-ubuntu`

| Field | Value |
|---|---|
| **Role** | Server host (Ubuntu) + VM host (Fedora KVM/QEMU) |
| **Tailscale Tag** | `tag:t1` |
| **Status** | Active |

**Hardware**

| Component | Detail |
|---|---|
| CPU | Intel Core i7-1065G7 (4C/8T, up to 3.90GHz) |
| GPU | Intel Iris Plus Graphics G7 (integrated) |
| RAM | 8GB |

**OS - Host**

- Ubuntu 24.04.4 LTS

**Services - Host**

- Netdata
- KVM/QEMU (hosts Fedora VM)

**OS - Fedora VM**

- Fedora Linux 43 (Server Edition) (KVM/QEMU guest)

**Services - Fedora VM**

- n8n (Docker container, `docker.n8nio/n8n:1.111.0`, `--network host`)
- Gitea (bare metal)
- 15 minute cron health check for n8n container (`/usr/local/bin/check-n8n.sh`)
- FirewallD — `enp1s0`: dhcpv6-client only; `tailscale0`: SSH + 3000/tcp (Gitea); SELinux enforcing/targeted

---

### Raspberry Pi 4 Model B — `pi4`
 
| Field | Value |
|---|---|
| **Role** | Backup exit node, Netdata node |
| **Tailscale tag** | `tag:t2` |
| **Status** | Active |
 
**Hardware**
 
| Component | Detail |
|---|---|
| CPU | Broadcom BCM2711, quad-core Cortex-A72 @ 1.8GHz |
| RAM | 4GB |
 
**OS**
 
- Debian GNU/Linux 12 (Bookworm)

**Services**
 
- Tailscale exit node (backup)
- Netdata
- UFW — ports 22, 80, 443, 9001; Vaultwarden

---

### Raspberry Pi Zero 2 W — `mini-mudd`
 
| Field | Value |
|---|---|
| **Role** | Netdata node |
| **Tailscale tag** | `tag:t3` |
| **Status** | Active (limited use case) |
 
**Hardware**
 
| Component | Detail |
|---|---|
| CPU | BCM2837, quad-core Cortex-A53 @ 1.00GHz |
| GPU | Broadcom BCM2835-VC4 (integrated) |
 
**OS**
 
- Debian GNU/Linux 13 (Trixie)

**Services**
 
- Netdata
- UFW — port 22 on `tailscale0` only
- No defined secondary use case; revisit when a specific need emerges

---

### mudd-cloud — Oracle Cloud (Phoenix)
 
| Field | Value |
|---|---|
| **Role** | Primary Tailscale exit node |
| **Tailscale tag** | `tag:cloud` |
| **Status** | Active |
 
**Hardware**
 
| Component | Detail |
|---|---|
| Provider | Oracle Cloud Infrastructure (Always Free tier) |
| Region | Phoenix |
 
**OS**
 
- Ubuntu 22.04 LTS

**Services**
 
- Tailscale exit node (primary)
- UFW — ports 22, 19999, 9443, 80, 443

---

### Desktop — `mudd-desktop`
 
| Field | Value |
|---|---|
| **Role** | Parked |
| **Tailscale tag** | `tag:parked` |
| **Status** | Parked |
 
**Hardware**
 
| Component | Detail |
|---|---|
| CPU | Intel Core i5-13600KF |
| GPU | NVIDIA RTX 4060 |
| RAM | 16GB |
| Storage | ~930GB |
 
**OS**
 
- Windows 11

**Notes**
 
- No active services. Parked pending a defined use case.
- ACL: currently reachable from `tag:t1`; tightening to `tag:t0` only is a known open item.

---
 
## Status Summary
 
| Device | Tag | Status | Primary Role |
|---|---|---|---|
| ThinkPad T14 | `tag:t0` | Active | Dev machine |
| Dell Server | `tag:t1` | Active | Server / VM host |
| Raspberry Pi 4 | `tag:t2` | Active | Backup exit node |
| Raspberry Pi Zero 2 W | `tag:t3` | Active | Netdata node |
| mudd-cloud | `tag:cloud` | Active | Primary exit node |
| Desktop | `tag:parked` | Parked | — |
 