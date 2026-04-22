# Ubuntu Server - Firewall Configuration
Tool: UFW
Date Configured: April 22nd 2026

---

## Active Rules

| Port | Service | Interface |
|------|---------|-----------|
| 22 | SSH | tailscale0 only |
| 19999 | Netdata | tailscale0 only |
|9443 | Portainer | tailscale0 only |
| 80 | HTTP | tailscale0 only |
| 443 | HTTPS | tailscale0 only |

---

## Cleanup Performed

### Ghost process on port 8080 cleared
Port 8080 was open in UFW with a docker-proxy process holding it, but no container claimed it. Likely a remnant of a previous Nextcloud container attempt.

```bash
# Identify what's listening on a port
sudo ss -tlnpp | grep

# Find process by port
sudo lsof -i :

# Inspect all containers for port references
sudo docker inspect $(sudo docker ps -aq) | grep -i

# Kill the ghost process
sudo kill <pid>

# Remove the UFW rule
sudo ufw delete allow
```

### Duplicate SSH rules removed
Port 22 and 22/tcp were both listed - redundant. Both removed after Tailscale-bound rule was confirmed working.

### UFW not starting on boot - fixed
UFW was previously masked or not enabled on boot. Fixed with:

```bash
sudo system enable ufw
sudo systemctl is-enabled ufw
```

---

# Key Commands

```bash
# Check current rules
sudo ufw status verbose

# Add a service bound to Tailscale only
sudo ufw allow in on tailscale to any port

# Delete a broad rule
sudo ufw delete allow

# Check UFW is enabled on boot
sudo systemctl is-enabled ufw

# Check SELinux-equivalent denials (Ubuntu uses AppArmor)
sudo aa-status
```
---

## Troubleshooting

**Port appears open but nothing is listening**
- Run `sudo ss -tlnpp | grep <port>` — if no output, nothing is bound
- Run `sudo docker inspect $(sudo docker ps -aq) | grep -i <port>`
  to rule out containers
- If docker-proxy appears but no container claims it, it's a ghost
- Kill the process with `sudo kill <pid>` and remove the UFW rule

**Locked out after firewall changes**
- Always add Tailscale-bound rule first and verify SSH works
  in a new terminal before deleting broad rules
- Physical access to device is the fallback if locked out remotely

**UFW not starting on boot**
- Check status with `sudo systemctl is-enabled ufw`
- Enable with `sudo systemctl enable ufw`

---

## Principles
- Default deny on all interfaces
- No services exposed on physical interface
- All access routed through Tailscale mash (tailscale0)
- Every new service must be explicitly added to tailscale0 with intention
- UFW enabled on boot via systemctl

---

## Notes
- Port 8080 was open with no active container - ghost docker-proxy process cleared April 21st 2026, rule removed
- UFW was previously not starting on boot - fixed April 21st 2026