# Raspberry Pi Zero 2 W — Firewall Configuration
**Tool:** UFW
**Date configured:** April 2026

---

## Active Rules

| Port | Service | Interface |
|------|---------|-----------|
| 22 | SSH | tailscale0 only |

---

## Cleanup Performed

### SSH locked to Tailscale only
SSH was open to Anywhere on all interfaces. Locked down to
tailscale0 only after confirming Tailscale-bound rule worked
in a separate terminal before deleting the broad rule.

```bash
# Add Tailscale-bound rule first
sudo ufw allow in on tailscale0 to any port 22

# Verify SSH works via Tailscale in new terminal before proceeding
ssh <user>@<ip-address>

# Then delete the broad rule
sudo ufw delete allow 22
```

---

## Key Commands

```bash
# Check current rules
sudo ufw status verbose

# Add a service bound to Tailscale only
sudo ufw allow in on tailscale0 to any port <port>

# Delete a broad rule
sudo ufw delete allow <port>

# Check UFW is enabled on boot
sudo systemctl is-enabled ufw
```

---

## Troubleshooting

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
- No service exposed on physical interface
- All access routed through Tailscale mesh (tailscale0)
- Every new service must be explicitly added to tailscale0 with intention
- UFW enabled on boot via systemctl

---

## Notes
- Cleanest baseline of all homelab devices at time of configuration
- Only SSH was open — locked to Tailscale in April 2026
- Device role: network sentinel (in progress)
- Future services will follow same Tailscale-only pattern