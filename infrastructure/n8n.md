# n8n Infrastructure - Build & Configuration
*Mudd Labs | Fedora Server (Dell Inspiron) | Last Updated April 15th 2026*

---

## Overview

n8n is a self-hosted workflow automation tool running in Docker on the Fedora server. It serves as the central automation and event routing layer for Mudd Labs infrastructure.

---

## Device Context

| Field | Value |
|-------|-------|
| Host machine | Dell Inspiron (Fedora Server) |
| Tailscale IP | `xxx.xxx.xxx.xx` |
| Tailscale tag | `tag:t1` |
| Host user | `mudd-fedora` (UID 1000) |
| n8n data directory | `/home/mudd-fedora/.n8n` |
| Log directory | `/var/log/n8n` |
| n8n image | `docker.n8n.io/n8nio/n8n:1.111.0` |
| n8n port | `5678` |

---

# Prerequisites

Before running n8n, create the required host directories:

'''bash
mkdir -p /home/mudd-fedora/.n8n
sudo mkdir -p /var/log/n8n
sudo chown -R 1000:1000 /var/log/n8n
'''

> **Note:** The ':z' flag on the volume mounts handles SELinux relabeling automatically. Do not skit it - Fedora runs SELinux enforcing by default and the container will fail to start without it.

---

## Docker Run Command

```bash
docker rm -f n8n
 
docker run -d \
  --name n8n \
  --network host \
  -e N8N_HOST=<TAILSCALE-IP> \
  -e N8N_PROTOCOL=https \
  -e WEBHOOK_URL=<TAILSCALE-IP> \
  -e N8N_DIAGNOSTICS_ENABLED=false \
  -e N8N_VERSION_NOTIFICATIONS_ENABLED=false \
  -e N8N_HIRING_BANNER_ENABLED=false \
  -e N8N_PERSONALIZATION_ENABLED=false \
  -v /home/mudd-fedora/.n8n:/home/node/.n8n:z \
  -v /usr/local/bin/muddbuilt:/scripts:z \
  -v /var/log/n8n:/var/log/n8n:z \
  --restart unless-stopped \
  docker.n8n.io/n8nio/n8n:1.111.0
```
### Volume Mount Breakdown
 
| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `/home/mudd-fedora/.n8n` | `/home/node/.n8n` | Persists workflows, credentials, and encryption key across restarts |
| `/var/log/n8n` | `/var/log/n8n` | Persists workflow log output on the host filesystem |
| '/usr/local/bin/muddbuilt:/scripts:z' | '/scripts' | Exposes MuddBuilt scripts and device config to the container for the network monitor workflow
 
> **Critical:** All 3 mounts require the `:z` flag for SELinux compatibility. Without it the container will throw `EACCES: permission denied` and crash-loop on startup.
 
---
 
## Verify Container is Running
 
```bash
docker ps | grep n8n
docker logs n8n --tail 20
```
 
---
 
## Accessing n8n
 
| Method | URL |
|--------|-----|
| Local (Fedora server) | `http://127.0.0.1:5678` |
| Tailscale (any mesh device) | `https://100.114.239.28` (via Tailscale Serve) |
 
> n8n is exposed over HTTPS externally via Tailscale Serve. Internally (Gitea webhooks) it communicates over plain HTTP on localhost — no TLS needed for loopback traffic.
 
---
 
## Gitea Webhook Configuration
 
Gitea runs bare metal on the same Fedora server as n8n. Webhooks must use HTTP on localhost — not HTTPS, not the Tailscale IP.
 
### app.ini Configuration
 
File location: `/etc/gitea/app.ini`
 
Add or verify the following block exists:
 
```ini
[webhook]
ALLOWED_HOST_LIST = 127.0.0.1
```
 
> Without this, Gitea blocks all webhook calls to loopback addresses by default (SSRF protection). This must be set explicitly.
 
After editing:
 
```bash
sudo systemctl restart gitea
```
 
### Webhook URL Format
 
```
http://127.0.0.1:5678/webhook/<production-webhook-key>
```
 
> Always use the **production** webhook URL from n8n, not the test URL. The test URL only works when the listener is manually activated in the canvas.
 
---
 
## Troubleshooting Reference
 
| Symptom | Cause | Fix |
|---------|-------|-----|
| Container crash-loops on startup with `EACCES` | SELinux blocking writes to host-mounted volume | Ensure `:z` flag is on both `-v` mounts |
| Container crash-loops with `permission denied on /home/node/.n8n/config` | Host directory owned by wrong user or missing `:z` | Run `sudo chown -R 1000:1000 /home/mudd-fedora/.n8n` and verify `:z` flag |
| Gitea webhook delivery shows TLS error | Webhook URL set to `https://` | Change Gitea webhook URL to `http://127.0.0.1:5678/...` |
| Gitea webhook delivery denied (`ALLOWED_HOST_LIST`) | No `[webhook]` block in `app.ini` | Add `ALLOWED_HOST_LIST = 127.0.0.1` to `/etc/gitea/app.ini`, restart Gitea |
| Webhook fires but n8n doesn't receive it | Using test URL instead of production URL | Grab production URL from Webhook node, update Gitea, activate workflow |
| Workflow not auto-triggering on push | Workflow not activated | Toggle the activation switch top-right of n8n canvas |
| n8n data lost after container recreate | No volume mount on original container | Always use the docker run command above with both `-v` mounts |
 
---
 
## Health Check Cron Job
 
A host-level Bash script checks container status every 15 minutes and fires a Discord alert if n8n is down. Runs independently of n8n — not affected by container failures.
 
### Script Location
 
```
/usr/local/bin/check-n8n.sh
```
 
### Script Contents
 
```bash
#!/bin/bash
DISCORD_WEBHOOK="<your-discord-webhook-url>"
 
if docker ps | grep -q n8n; then
    : # container is running, do nothing
else
    curl -X POST "$DISCORD_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d '{"content": "n8n container is down"}'
fi
```
 
### Make Executable
 
```bash
sudo chmod +x /usr/local/bin/check-n8n.sh
```
 
### Cron Entry
 
```bash
crontab -e
```
 
Add:
 
```
*/15 * * * * /usr/local/bin/check-n8n.sh
```
 
Verify:
 
```bash
crontab -l
```
 
> Cron runs on the system clock — fires at :00, :15, :30, :45 of every hour regardless of when the job was added.
 
### Manual Test
 
```bash
# Test with container running (should do nothing)
/usr/local/bin/check-n8n.sh
 
# Test with container stopped (should fire Discord alert)
docker stop n8n
/usr/local/bin/check-n8n.sh
docker start n8n
```
 
---
 
## Rebuild Checklist
 
If n8n ever needs to be rebuilt from scratch:
 
- [ ] Create host directories (`/home/mudd-fedora/.n8n`, `/var/log/n8n`)
- [ ] Set ownership: `sudo chown -R 1000:1000 /var/log/n8n`
- [ ] Run docker command with all 3 `:z` volume mounts
- [ ] Verify container is running: `docker ps | grep n8n`
- [ ] Confirm `/etc/gitea/app.ini` has `[webhook]` block
- [ ] Rebuild workflows in n8n UI
- [ ] Grab production webhook URLs and update Gitea webhooks
- [ ] Activate workflows in n8n canvas
- [ ] Verify cron job is registered: `crontab -l`
- [ ] Verify health check script is executable: `ls -la /usr/local/bin/check-n8n.sh`