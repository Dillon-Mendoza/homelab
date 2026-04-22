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