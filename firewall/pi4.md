# Raspberry Pi 4 - Firewall Configuration
Tool: UFW
Date Configured: April 22nd 2026

---

## Active Rules

| Port | Service | Interface |
|------|---------|-----------|
| 22 | SSH | tailscale0 only |
| 80 | HTTP | tailscale0 only |
| 443 | HTTPS | tailscale0 only |
| 9001 | Portainer Agent | tailscale0 only |

---

## Cleanup Performed

### Ghost rules removed
Ports 8000 and 5000 were open with no active containers or processes listening. Identified and removed:

```bash
# Confirm nothing is listening on a port
sudo ss -tlnpp | grep

# Inspect all containers for port reference
sudo docker inspect $(sudo docker ps -aq) | grep -i

# If confirmed ghost, delete the rule
sudo ufw delete allow
```

### Duplicate SSH rules removed
22/tcp and 22/tcp (OpenSSH) were both present - redundant.
Removed both rules after Tailscale-bound rule was confirmed working.

---

## Key Commands

```bash
# Check current rules
sudo ufw status verbose

# Add a service bound to Tailscale only
sudo ufw allow in on tailscale0 to any port

# Delete a broad rule
sudo ufw delete allow

# Delete a named rule
sudo ufw delete allow "OpenSSH"

# Find what process owns a port
sudo ss -tlnpp | grep

# Identify process by port
sudo lsof -i :

# Kill a ghost process
sudo kill

# Check UFW is enabled on boot
sudo systemctl is-enabled ufw
```

---

## Troubleshooting

**Port appears open but nothing is listening**
- Run 'sudo ss -tlnpp | grep <port> - if no output, nothing is bound
- Run 'sudo docker inspect $(sudo docker ps -aq) | grep -i <port>' to rule out containers
- If docker-proxy appears but no container claims it, it's a ghost
- Kill the process with 'sudo kill <pid>' and remove the UFW rule

**Locked out after firewall changes**
- Always add Tailscale-bound rule first and verify SSH works in a new terminal before deleting broad rules
- Physical access to device is the fallback if locked out remotely

---

## Principles
- Default deny on all interfaces
- No service exposed on physical interface
- All access routed through Tailscale mesh (tailscale0)
- Every new service must be explicitly added to tailscale0 with intention
- UFW enabled on boot via systemctl

---

## Notes
- Vaultwarden and Uptime Kuma containers running but unreachable
    - port mapping issue, to be resolved separately
- Pi-hole attempted but caused instability - deferred to future project
- Ghost processes on 8000 and 5000 cleared