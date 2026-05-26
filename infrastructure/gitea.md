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
| Database SQLite3 | `/var/lib/gitea/data/gitea.db` |
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

# Enable on boot
sudo systemctl enable gitea
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

## Key app.ini Settings

File location: `/etc/gitea/app.ini`

```ini
[server]
HTTP_PORT = 3000
ROOT_URL = http://:3000/
DOMAIN = 
SSH_DOMAIN =
OFFLINE_MODE = true

[database]
DB_TYPE = sqlite3
PATH = /var/lib/gitea/data/gitea.db

[webhook]
ALLOWED_HOST_LIST = 127.0.0.1

[log]
MODE = console
LEVEL = info
ROOT_PATH = /var/lib/gitea/log
```

> `ALLOWED_HOST_LIST = 127.0.0.1` is required for n8n webhook
> integration Without it Gitea blocks all webhook calls to loopback
> addresses by default (SSRF protection)

> `OFFLINE_MODE = true` disables external CDN asset loading -
> appropriate for a mesh-only service with no public exposure

---

## n8n Webhook Integration

Gitea triggers n8n workflows via webhooks on push events. Tailscale IP is used for this integration.

---

## Directory Structure

```
/var/lib/gitea
|--data/
| |--gitea.db   #SQLite database
| |--gitea-repositories/ # All repo data
| |--lfs/   # Large file storage
```

---

## Troubleshooting Reference

| Symptom | Cause | Fix |
|---|---|---|
| Gitea unreachable on port 3000 | Service not running | `sudo systemctl restart gitea` |
| Webhook delivery blocked | `ALLOWED_HOST_LIST` missing | Add `ALLOWED_HOST_LIST = 127.0.0.1` to `[webhook]` block, restart |
| SSH clone failing | Wrong SSH domain | Verify `SSH_DOMAIN` in `app.ini` matches Tailscale IP |
| Service fails to start | Config error in `app.ini` | Run `gitea doctor` for diagnostics |

---

## Rebuild Checklist

- [ ] Install Gitea binary to `/usr/local/bin/gitea`
- [ ] Create `gitea` system user
- [ ] Create data directories under `/var/lib/gitea`
- [ ] Set correct ownership: `sudo chown -R gitea:gitea /var/lib/gitea`
- [ ] Configure `/etc/gitea/app.ini`
- [ ] Add `[webhook]` block with `ALLOWED_HOST_LIST = 127.0.0.1`
- [ ] Enable and start service: `sudo systemctl enable --now gitea`
- [ ] Verify accessible at `http://<TAILSCALE-IP>:3000`
- [ ] Recreate repos and restore from backup if rebuilding