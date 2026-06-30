# Raspberry Pi Zero 2 W — Firewall Configuration
**Tool:** UFW
**Date configured:** April 2026
**Updated:** June 2026 (post re-flash to Pi OS Lite 32-bit)

---

## Active Rules

| Port | Service | Interface |
|------|---------|-----------|
| 22 | SSH | tailscale0 only |

---

## June 2026 Update — Re-flash and Role Transition

Device was re-flashed from Pi OS Full to Pi OS Lite (32-bit) due to memory
pressure at idle (148Mi available, 196Mi already in swap on Full vs. 300Mi
available, 14Mi in swap on Lite — confirmed via `free -h` before and after).

Role is transitioning from "network sentinel (in progress, no defined use
case)" to `tag:dns` — a dedicated Pi-hole node serving DNS for the Tailscale
mesh as a custom upstream resolver under MagicDNS (Option A: MagicDNS stays
authoritative for `.ts.net` resolution, Pi-hole handles and filters
everything else).

Since this was a fresh OS install rather than a cleanup of an existing
config, there was no broad "Anywhere" SSH rule to delete. UFW was enabled
directly with the Tailscale-only rule already in place:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 22 proto tcp
sudo ufw enable
```

Verified clean baseline:

```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22 on tailscale0           ALLOW IN    Anywhere
22 (v6) on tailscale0      ALLOW IN    Anywhere (v6)
```

Enabled on boot, confirmed via `systemctl is-enabled ufw` → `enabled`.

**Next planned ports (not yet added — pending Pi-hole install):**
- UDP/TCP 53 (DNS) from `tag:t0`, `tag:t1`, `tag:t2`, `tag:cloud` via Tailscale ACL
- TCP 80 (Pi-hole admin UI) from `tag:t0` only

Per the project principle of adding services with intention, these ports
will be opened on UFW (and granted in the Tailscale ACL via the new
`tag:dns` tag) only once Pi-hole is actually installed and ready to serve —
not provisioned in advance of the service existing.

---

## Cleanup Performed (Original, April 2026)

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

**SSH host key mismatch after re-flash**
- Expected behavior, not a security issue — a fresh OS install generates
  a new host key
- Clear the stale entry: `ssh-keygen -R <hostname-or-ip>`
- Re-accept the new key on next connection

---

## Principles
- Default deny on all interfaces
- No service exposed on physical interface
- All access routed through Tailscale mesh (tailscale0)
- Every new service must be explicitly added to tailscale0 with intention
- UFW enabled on boot via systemctl

---

## Notes
- Cleanest baseline of all homelab devices at time of original configuration
- Re-flashed June 2026 to Lite (32-bit) to resolve memory pressure ahead of
  Pi-hole install
- Device role: transitioning from network sentinel (no use case) to
  `tag:dns` — dedicated Pi-hole DNS node for the Tailscale mesh
- Future services will follow same Tailscale-only, add-with-intention
  pattern established here
