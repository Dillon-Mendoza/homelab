# Tailscale DNS Configuration
**Date configured:** July 2026
**Scope:** Mesh-only DNS filtering via Pi-hole as custom upstream resolver

---

## Architecture

Tailscale's DNS stack has two layers working together:

**MagicDNS** — Tailscale's built-in DNS resolver (`100.100.100.100`).
Authoritative for `.ts.net` hostnames and reverse lookups within the mesh.
Always enabled. Handles device name resolution across the tailnet.

**Custom Nameserver** — Pi-hole running on `mini-mudd`. Handles all
non-`.ts.net` queries, filtering ad/tracking domains before resolution.
Set as a global nameserver in the Tailscale admin console.

**Full query path:**
```
Mesh device → MagicDNS (100.100.100.100) → Pi-hole → Cloudflare (1.1.1.1)
```

MagicDNS forwards non-tailnet queries to Pi-hole as its upstream resolver.
Pi-hole's IP does not appear directly in `resolvectl status` on mesh devices —
it operates one hop behind MagicDNS. This is expected behavior, not a
misconfiguration.

---

## Admin Console Settings (DNS Tab)

### MagicDNS
- **Status:** Enabled
- **Do not disable.** Disabling breaks `.ts.net` hostname resolution,
  `tailscale serve` HTTPS URLs, and SSH config aliases using `.ts.net`
  hostnames.

### Global Nameservers
- Pi-hole's Tailscale IP set as global nameserver
- Scoped to mesh only (no LAN-wide DNS)

### Override DNS Servers Toggle
- **Status:** Enabled
- When disabled (default), devices prefer their local DNS configuration
  and ignore the custom nameserver entirely. Must be enabled for Pi-hole
  to receive queries from mesh devices.

### Use with Exit Node Toggle
- **Status:** Enabled
- When disabled, devices using an exit node bypass Pi-hole and use the
  exit node's local resolver instead. Enabling preserves Pi-hole as the
  DNS resolver regardless of exit node routing.
- **Tradeoff:** With this enabled, Pi-hole becomes load-bearing for exit
  node users. If `mini-mudd` goes down, DNS fails for anyone actively
  using the exit node.

---

## Layer Separation

Pi-hole and the exit node operate on separate layers in the same direction:

| Layer | Tool | Function |
|-------|------|----------|
| Name resolution | Pi-hole | Intercepts DNS queries, blocks known ad/tracking domains |
| Traffic routing | Exit node (mudd-cloud) | Routes internet traffic through Oracle Phoenix, masking physical location |

They are complementary, not redundant. A DNS query is resolved by Pi-hole
before the connection is routed through the exit node. Both layers apply
to outbound traffic.

---

## systemd-resolved Behavior

On Linux nodes using `systemd-resolved`, `resolvectl status` shows DNS
routing per interface. Key things to understand:

**`+DefaultRoute`** on an interface means DNS queries without a specific
domain match are sent to that interface's resolver.

**`~.`** as a DNS domain means "match everything" — effectively sets that
interface as the catch-all resolver.

When multiple interfaces have `+DefaultRoute`, `systemd-resolved` picks
one. On nodes with both a physical interface (WiFi/Ethernet) and
`tailscale0`, the physical interface may win unless Tailscale's DNS
override is enabled.

**Confirming DNS routing on a node:**
```bash
resolvectl status
```

Look for `tailscale0` having `+DefaultRoute` and `~.` in the DNS Domain
field. If it shows `-DefaultRoute`, Pi-hole is not receiving that node's
queries.

**Confirming Pi-hole is receiving queries:**
Check the Pi-hole admin UI query log or run:
```bash
sudo pihole tail
```

---

## Troubleshooting

**Device not showing in Pi-hole client list:**
- Device may not have made a DNS query yet — browse something to trigger
- Device may have hardcoded DNS in local network config, bypassing
  Tailscale's nameserver
- Check `resolvectl status` on the device — confirm `tailscale0` has
  `+DefaultRoute`

**Queries resolving through local router instead of Pi-hole:**
- Confirm "Override DNS Servers" toggle is enabled in Tailscale admin
  console DNS settings
- Restart `tailscaled` on the device: `sudo systemctl restart tailscaled`
- Wait ~30 seconds for config to re-propagate, then re-check
  `resolvectl status`

**Exit node traffic bypassing Pi-hole:**
- Enable "Use with exit node" toggle in Tailscale admin console DNS
  settings

**Cloud VM (Oracle) DNS not routing through Pi-hole:**
- Oracle's VCN metadata resolver (`169.254.169.254`) on `ens3` competes
  with `tailscale0` for `+DefaultRoute`
- `CorpDNS: true` in `tailscale debug prefs` confirms Tailscale is
  pushing DNS config
- Resolution: `sudo resolvectl dns tailscale0 <pi-hole-tailscale-ip>`
  and `sudo resolvectl domain tailscale0 ~.` to force `tailscale0` as
  default route — note this does not persist across reboots without
  additional configuration

---

## Notes

- Pi-hole is intentionally mesh-only at this stage. No LAN-wide DNS
  configuration. Devices outside the Tailscale mesh use their own
  resolvers.
- Option B (Pi-hole owns DNS outright, MagicDNS disabled) is a deferred
  project — a good exercise when covering DNS/DHCP in Linux+ study material,
  since it requires configuring Pi-hole to forward `.ts.net` queries and
  handling the loss of automatic hostname resolution.