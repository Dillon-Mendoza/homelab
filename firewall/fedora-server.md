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

Key Commands

'''bash
# Check active zones
sudo firewall-cmd --list-all-zones

# Add a service to tailscale zone
sudo firewall-cmd --zone=tailscale --add-service= --permanent

# Add a port to tailscale zone
sudo firewall-cmd --zone=tailscale --add-port=/tcp --permanent

# Reload after changes
sudo firewall-cmd --reload

# Check SELinux denials if something breaks
sudo ausearch -m avc recent
'''

---

Principles
- Default deny on all interfaces
- No services exposed on physical interface except dhcpv6-client
- All access routed through Tailscale mesh
- Every new service must be explicitly added to the tailscale zone with intention