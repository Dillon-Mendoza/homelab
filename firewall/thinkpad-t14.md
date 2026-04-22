# ThinkPad T14 — Firewall Configuration
**Tool:** FirewallD
**Date configured:** April 2026

---

## Active Zones

### FedoraWorkstation (default)
- **Interface:** wlp3s0 (wireless NIC)
- **Allowed services:** dhcpv6-client
- **Notes:** No inbound SSH. ThinkPad is a Tier 0 device —
  connections flow outbound only. Nothing SSHes into this machine.

### tailscale
- **Interface:** tailscale0
- **Allowed services:** none
- **Notes:** Zone exists to correctly handle Tailscale traffic.
  No inbound ports needed — all homelab access is outbound from
  this device.

---

## Cleanup Performed

### Overly permissive port range removed
Default FedoraWorkstation zone had `1025-65535/tcp` and
`1025-65535/udp` open — essentially every non-privileged port.
Removed entirely.

```bash
sudo firewall-cmd --remove-port=1025-65535/tcp --permanent
sudo firewall-cmd --remove-port=1025-65535/udp --permanent
sudo firewall-cmd --reload
```

### SSH removed from inbound
SSH was open inbound by default. Removed — this machine only
SSHes outbound into other homelab devices, never accepts inbound
connections.

```bash
sudo firewall-cmd --remove-service=ssh --permanent
sudo firewall-cmd --reload
```

### Samba-client removed
Present in default zone but not in use. Not related to Windows
dual-boot — only relevant for network file sharing which is not
configured. Removed to reduce unnecessary exposure.

```bash
sudo firewall-cmd --remove-service=samba-client --permanent
sudo firewall-cmd --reload
```

---

## Key Commands

```bash
# Check active zones
sudo firewall-cmd --list-all-zones

# Check specific zone
sudo firewall-cmd --zone=tailscale --list-all

# Add a port to tailscale zone if needed in future
sudo firewall-cmd --zone=tailscale --add-port=<port>/tcp --permanent

# Reload after changes
sudo firewall-cmd --reload

# Check SELinux mode
getenforce
sestatus

# Check SELinux denials
sudo ausearch -m avc -ts recent
```

---

## Troubleshooting

**Homelab devices unreachable from ThinkPad**
- Verify Tailscale is running: `tailscale status`
- Verify tailscale0 is bound to tailscale zone:
  `sudo firewall-cmd --zone=tailscale --list-all`
- Test outbound SSH: `ssh <user>@<tailscale-ip>`

**Permission denied unrelated to rwx permissions**
- SELinux is likely the cause
- Run `sudo ausearch -m avc -ts recent` to check for denials

---

## Principles
- Default deny on all interfaces
- No inbound services — outbound only workstation
- All homelab access routed through Tailscale mesh
- Tailscale zone exists for correct traffic handling, not inbound access
- SELinux running in enforcing/targeted mode — do not disable

---

## Notes
- Tier 0 device — daily driver and dev machine
- Dual-boot Fedora 43 and Windows 11 — Samba not needed,
  Windows partition accessed locally not over network
- Connects via home WiFi and iPhone hotspot — no public WiFi
- FedoraWorkstation default zone had 1025-65535 open — removed
  April 2026
- SELinux enforcing/targeted — `ausearch -m avc -ts recent` is the
  first stop for mysterious permission denials