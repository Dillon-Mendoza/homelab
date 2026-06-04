# Incident: DNS Failure in n8n Container After Network Change

**Date:** 2026-05-06  
**Status:** Partially resolved  
**Systems affected:** `fedora-vm` — Docker, n8n, Discord webhook integration

---

## Symptom

n8n workflows failed on all HTTP requests to Discord with the following error:

```
The DNS server returned an error, perhaps the server is offline
```

---

## Investigation

Host-level connectivity was confirmed working — internet access and external HTTPS both functional. DNS resolution inside the n8n container was broken:

```bash
docker exec -it n8n ping google.com
# ping: bad address 'google.com'
```

---

## Root Cause

The host network interface changed from Wi-Fi to Ethernet. NetworkManager rewrote `/etc/resolv.conf` on the host. The n8n container, already running with `--network host`, inherited its DNS configuration at startup and was never updated when the host's DNS changed. The container held stale state until restarted.

---

## Resolution

Container restart forced DNS re-initialization:

```bash
docker restart n8n
```

Discord webhook integration resumed immediately after restart.

---

## Open Item — Hardening Not Applied

The recommended fix is to pin static DNS in `/etc/docker/daemon.json` so Docker no longer inherits from the host at container startup:

```json
{
  "dns": ["8.8.8.8", "1.1.1.1"]
}
```

Apply with:

```bash
sudo systemctl restart docker
```

This has not been applied. If the host network interface changes again, the same failure will recur and will require another container restart to resolve.