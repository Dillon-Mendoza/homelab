# Gitea Infrastructure
*Mudd Labs | Dell Server - Fedora VM | Last Updated: May 2026*

---

## Overview

Gitea is a lightweight self-hosted version control platform running bare metal on the Fedora VM inside the Dell Server. It serves as the internal Git host for all Mudd Labs repositories and is the source of webhook events routed through n8n.

---

## Device Context

| Field | Value |
|---|---|
| Host Machine | Dell Server - Fedora KVM/QEMU VM |
| Tailscale tag | `tag:t1` |
| Run user | `gitea` |
| Binary Location | `/usr/local/bin/gitea` |
| Config file | `/etc/gitea/app.ini` |
| Data directory | `/var/lib/gitea` |
| Repository root | `/var/lib/gitea/data/gitea-repositories` |
| Database SQLite3 - `/var/lib/gitea/data/gitea.db` |
| Version | 1.22.6 |
| HTTP port | `3000` |
| SSH port | `22` |

---

## Service Management

Gitea runs as a systemd service, enabled at boot

```bash
# Check status
sudo systemctl status gitea

# Start / Stop / Restart
sudo systemctl start gitea
sudo systemctl stop gitea
sudo systemctl restart gitea
```

---

## Accessing Gitea

| Method | URL |
|---|---|
| Local (Fedora VM) | `<LOCAL-HOST>:3000` |
| Tailscale (any mesh device) | `http://<TAILSCALE-IP>:3000` |

> Gitea is accessible over HTTP on port 3000 via the Tailscale mesh
> `tag:guest` devices are granted `tcp:3000` access via ACL for
> read-only Gitea access

---

