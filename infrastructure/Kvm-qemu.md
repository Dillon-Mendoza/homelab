# KVM/QEMU — Fedora VM

**Last updated:** 2026-05  
**Host:** `dell-ubuntu` (Ubuntu 24.04.4 LTS)  
**Guest:** `fedora-vm` (Fedora Linux 43 Server Edition)

---

## Overview

The Fedora VM runs as a KVM/QEMU guest on `dell-ubuntu`, provisioned via GNOME Boxes (libvirt backend). It hosts the primary services for the Mudd Labs homelab: Gitea, n8n, and Tailscale.

---

## VM Specifications

| Field | Value |
|---|---|
| **VM name** | `fedora-vm` |
| **Hypervisor** | KVM/QEMU 8.2.2 (libvirt 10.0.0) |
| **Machine type** | pc-q35-8.2 |
| **vCPUs** | 8 (4 cores × 2 threads, host-passthrough) |
| **RAM** | 4GB |
| **Disk** | 25G qcow2 (`/var/lib/libvirt/images/fedora-vm.qcow2`) |
| **Disk layout** | LVM — 15G allocated to `fedora-root`; ~8G unallocated in `vda3` |
| **Security** | AppArmor + DAC labels (libvirt-managed); SELinux enforcing/targeted inside guest |

---

## Networking

The VM uses QEMU user-mode networking (`type='user'`). This means:

- The VM has no routable LAN IP — it cannot be reached directly from the local network
- Outbound connections work normally (VM can reach the internet)
- All inbound access is via Tailscale, which the VM joins independently from inside the guest

This is intentional. Tailscale establishes its mesh connection outbound at startup, giving the VM its own Tailscale IP independent of the host's network configuration.

---

## Shared Storage

A virtiofs mount shares a directory from the Ubuntu host into the VM:

| Host path | Guest mount | Purpose |
|---|---|---|
| `/home/mudd/homelab-logs` | `/mnt/homelab-logs` | Log storage off the VM's constrained disk |

This keeps logs off the 25G virtual disk and onto the host's larger filesystem.

---

## Services

| Service | Runtime | Notes |
|---|---|---|
| Gitea | Bare metal (systemd) | Self-hosted Git — port 3000/tcp |
| n8n | Docker (`--network host`) | Workflow automation — binds to host network stack |
| Tailscale | Bare metal (systemd) | Mesh access — only inbound path to this VM |

n8n runs as a Docker container with `--network host`, so no Docker port mapping is used. It binds directly to the VM's network stack.

### Disk usage (as of 2026-05)

Root filesystem is at 62% used (9.2G of 15G). Monitor this — Gitea repo data and n8n execution logs will grow over time. The ~8G of unallocated LVM space in `vda3` is available to extend `fedora-root` if needed.

---

## Common Commands

### VM management (run on `dell-ubuntu`)

```bash
# Check VM state
virsh list --all

# Start VM
virsh start fedora-vm

# Shutdown VM (graceful)
virsh shutdown fedora-vm

# Force stop
virsh destroy fedora-vm

# View full VM config
virsh dumpxml fedora-vm
```

### Service management (run inside `fedora-vm`)

```bash
# Check running services
systemctl status gitea
systemctl status tailscaled
docker ps

# Restart n8n container
docker restart n8n
```

---

## Known Issues

### Docker DNS failure after host network change

**Incident:** `incidents/dns-failure-wifi-ethernet.md`  
**Status:** Partially resolved — root cause documented, hardening not yet applied

When the host network interface changed from Wi-Fi to Ethernet, the n8n container retained stale DNS configuration and failed to resolve external hostnames. A container restart restored DNS, but the underlying issue remains.

**Open item:** Apply static DNS to `/etc/docker/daemon.json`:

```json
{
  "dns": ["8.8.8.8", "1.1.1.1"]
}
```

Then restart Docker:

```bash
sudo systemctl restart docker
```

This prevents Docker from inheriting host DNS at container startup, making it resilient to future host network changes.