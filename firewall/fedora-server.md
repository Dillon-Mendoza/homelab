# Fedora Server - Firewall Configuration
Tool: FirewallD
Date Configured: April 19th 2026

---

Active Zones

FedoraServer (default)
- Interface: enp1s0 (physical NIC)
- Allowed Services: dhcpv6-client
- Notes: No SSH on physical interface. All administrative access is via Tailscale only

tailscale
- Interface: tailscale0
- Allowed Services: ssh
- Allowed Ports: 3000/tcp (Gitea)
- Notes: All services confined to Tailscale mesh. Only devices inside the Tailscale network can reach SSH, Gitea, and any future services.

---

## Cleanup Performed

### FirewallD was masked - unmasked and enabled
FirewallD had been masked during a previous UFW installation attempt. UFW was also not starting on boot, leaving no active firewall.

```bash
#Unmask and start FirewallD
sudo systemctl unmask firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Verify
sudo systemctl status firewalld
```

### Cockpit removed
Cockpit (port 9090) was open by default in the FedoraServer zone. Not actively used - removed to reduce attack surface.

```bash
sudo firewalld-cmd --remove-service=cockpit --permanent
sudo firewall-cmd --reload
```

### SSH removed from physical interface
SSH was open on enp1s0 (physical NIC). Since all SSh access is via Tailscale, this was unnecessary exposure. removed after confirming Tailscale SSh worked in a separate terminal.
```

---

Key Commands

'''bash
# Check active zones
sudo firewall-cmd --list-all-zones

# Check specific zones only
sudo firewall-cmd --list-all-zones | grep -A 15 "FedoraServer\|tailscale"

# Add a service to tailscale zone
sudo firewall-cmd --zone=tailscale --add-service= --permanent

# Add a port to tailscale zone
sudo firewall-cmd --zone=tailscale --add-port=/tcp --permanent

# Remove a service from a zone
sudo firewall-cmd --zone= --remove-service= --permanent

# Reload after changes
sudo firewall-cmd --reload

# Check SELinux mode
getenforce
sestatus

# Check SELinux denials
sudo ausearch -m avc recent
'''

---

## Troubleshooting

**Permission denied that doesn't match rwx permissions**
- SELinux is likely the cause
- Run `sudo ausearch -m avc -ts recent` to check for denials
- If Docker volume mounts are blocked, add `:z` flag to relabel
  the host directory as `container_file_t`

**FirewallD masked and won't start**
- Run `sudo systemctl unmask firewalld` before attempting to start
- Confirm no conflicting firewall tool is active (UFW, iptables)

**Locked out after firewall changes**
- Always add Tailscale-bound rule first and verify SSH works
  in a new terminal before deleting broad rules
- Physical access to device is the fallback if locked out remotely

---

## Principles
- Default deny on all interfaces
- No services exposed on physical interface except dhcpv6-client
- All access routed through Tailscale mesh
- Every new service must be explicitly added to the tailscale zone with intention
- SELinux running in enforcing/targeted mode - do not disable

---

## Notes
- FirewallD was masked due to previous UFW attempt — unmasked April 2026
- Cockpit removed from default zone April 2026
- SSH removed from physical interface April 2026
- SELinux enforcing/targeted — `ausearch -m avc -ts recent` is the
  first stop for mysterious permission denials