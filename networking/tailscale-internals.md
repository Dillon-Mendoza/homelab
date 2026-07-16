# Tailscale Internals — How Your Mesh Actually Works

You operate a tiered zero-trust overlay network daily and have already
debugged it in production (the ACL outage). This doc fills in the machinery
under the commands you already run. Post-exam material — but also the single
best interview topic you own, because you can go four layers deep on demand.

---

## Layer 0 — WireGuard

Tailscale is a control plane wrapped around **WireGuard**, the in-kernel VPN
(Linux+ 3.5 lists it). WireGuard's model is radically small:

- Each node has a **Curve25519 keypair**. A peer = a public key + allowed IPs.
- Packets are encrypted (ChaCha20-Poly1305) to a peer's public key, sent over
  UDP. No handshake daemons, no TLS, no certificates — key possession IS identity.
- "Allowed IPs" is both routing table and firewall: a packet from a peer is
  accepted only if its source falls in that peer's allowed range.

What WireGuard deliberately does NOT do: key distribution, NAT traversal,
peer discovery. Plain WireGuard means hand-copying public keys between every
node pair — n² config lines. Everything Tailscale adds exists to delete that
work.

## Layer 1 — The Coordination Server (Control Plane)

`tailscaled` on each node talks HTTPS to Tailscale's coordination server,
which is a **key and policy exchange, not a traffic relay**:

- Your node uploads its public key + endpoints; downloads the **netmap** —
  every peer it's *allowed* to see, their keys, IPs, and endpoints.
- The ACL is evaluated **server-side into each node's netmap** — with default
  deny, a forbidden peer isn't "blocked", it's *absent from the netmap
  entirely*. (Why `tailscale status` on pi-zero shows so little: tag:t3
  initiates nothing, so almost nothing exists from its point of view.)
- **The outage lesson, mechanized:** nodes get netmap updates over a
  long-lived connection. A node that's offline during an ACL change keeps
  operating on its **stale cached netmap** — exactly what dell-fedora did.
  `systemctl restart tailscaled` forces a fresh netmap pull. Now the fix from
  the incident writeup has a mechanism, not just a procedure.
- Login identity: your identity provider (Google, etc.) authenticates once;
  node keys expire per policy; **tags** replace user identity for servers —
  which is why every fleet machine is `tag:something` and the tags, not
  hostnames, appear in the ACL.

## Layer 2 — Getting Packets Through (Data Plane)

Two peers usually sit behind NATs. Establishment sequence:

1. **STUN**-style probing (via DERP servers' STUN service) discovers each
   node's public ip:port mapping.
2. Both sides send UDP simultaneously at each other's discovered endpoints —
   **hole punching**. Works through most NATs: the outbound packet opens the
   state-table hole the inbound one needs.
3. Hard NATs (symmetric/CGNAT) defeat this → fall back to **DERP**: TLS-
   wrapped relays run by Tailscale. Traffic stays end-to-end encrypted (DERP
   relays ciphertext it cannot read) but adds latency.
4. Connections **upgrade live**: first packets flow via DERP, then switch to
   direct when hole punching lands.

```bash
tailscale netcheck        # your NAT type, nearest DERP, UDP reachability
tailscale ping muddpi     # 'via DERP(xxx)' vs 'direct a.b.c.d:port' — and
                          # watch it upgrade mid-ping. tailscale ping tests the
                          # TUNNEL layer; regular ping tests IP — different layers,
                          # different failures.
tailscale status          # per-peer: direct endpoint, relay, idle, offline
```

## Layer 3 — The Node's Own Plumbing (what you see on-host)

- `tailscale0` — a **TUN device**: tailscaled reads/writes IP packets in
  userspace, encrypts/decrypts, sends UDP out the real interface.
- Addresses come from **100.64.0.0/10** (CGNAT space, RFC 6598 — chosen to
  never collide with private LANs; the subnetting drills cover its span).
- **Routing table 52 + policy rules**: `ip rule` shows a fwmark-based rule
  set steering traffic to `ip route show table 52`. Tailscale-destined (and,
  with an exit node, ALL) traffic hits table 52 before the main table — main
  table looks normal while everything actually flows through the tunnel.
  `ip route show table 52` cracked the ACL outage precisely because that's
  where the truth lives.
- tailscaled's own UDP escapes the exit-node loop via fwmark: packets marked
  by tailscaled bypass the table-52 default route. (Otherwise the tunnel
  would try to route itself through itself.)
- **MagicDNS**: resolved forwards peer names to 100.100.100.100 — tailscaled
  itself answers locally from the netmap. Peer naming needs no external DNS.
- **MTU**: tailscale0 runs at **1280** (WireGuard overhead + worst-case
  headroom). Symptom pattern when MTU goes wrong through tunnels: small
  packets fine, big transfers hang — `ping -M do -s 1400 <peer-100.x>` will
  demonstrate fragmentation-needed behavior that plain LAN pings never show.

## Exit Nodes — Your Outage, End to End

Advertising: `mudd-cloud` runs `tailscale up --advertise-exit-node` and has
`net.ipv4.ip_forward=1` (the 3.2 sysctl — forwarding boxes always need it).
Using: `tailscale set --exit-node=mudd-cloud` injects `default` into table 52
→ every packet (not just 100.x) enters the tunnel, exits mudd-cloud, SNAT'd
to its address. The ACL gate: forwarding through an exit node is authorized
by a grant to **`autogroup:internet`** — a peer grant lets you reach the exit
node; only the autogroup grant lets traffic go THROUGH it to the world.
Missing grant = the exact silent blackhole of 2026-05-03: DNS fine, LAN fine,
gateway fine, internet gone.

---

## Interview Compression (90 seconds, from your own network)

"My homelab runs a tiered zero-trust overlay on Tailscale — WireGuard data
plane, hosted control plane. Every device is tagged into a tier; the ACL is
default-deny and evaluated into each node's netmap, so an unauthorized peer
doesn't even appear in the routing picture. SSH rides inside the tunnel but I
kept key-based sshd instead of Tailscale SSH to keep key management a
practiced skill. I've debugged it at the routing-policy level — exit-node
forwarding failed after an ACL change, and the diagnosis came down to reading
Tailscale's policy routing table, table 52, and understanding that offline
nodes operate on stale cached network maps until the daemon refreshes."

Every sentence of that is checkable, and you have the incident writeup to
prove the last one.
