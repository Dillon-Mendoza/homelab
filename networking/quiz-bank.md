# Networking Quiz Bank — Answers at Bottom
# Usage: teaching model draws 5 ("Quiz me on networking"); subnetting has
# its own drills file — this bank covers DNS, packets, and the mesh.

## Questions

1. `dig internal-app` fails on tp-mudd; `getent hosts internal-app`
   succeeds. Explain the two resolution paths and name the config file
   where they diverge.
2. A capture shows: SYN → SYN-ACK → ACK → PSH-ACK → RST. The application
   log shows nothing. What happened at each arrow, and what does the RST
   with no app log suggest?
3. NXDOMAIN vs SERVFAIL vs timeout from dig — what does each verdict
   accuse, and which one is DNSSEC's usual signature?
4. Why can a DNS cache hit be invisible to tcpdump on ALL interfaces, and
   which single command proves whether resolved answered from cache?
5. `tailscale ping muddpi` says `via DERP(dfw)` for 5 packets, then
   `direct 98.x.x.x:41641`. Narrate what happened underneath.
6. A peer is absent from `tailscale status` on pi-zero but visible on
   tp-mudd. Nothing is "down." Explain via the netmap/ACL model.
7. Big file transfers between two tailnet peers stall; small pings fine.
   The interface MTU says 1280. Reconcile these facts and give the
   diagnostic ping.
8. Your LAN host has 192.168.1.240/28 configured by mistake (should be
   /24). Predict exactly which destinations work and which fail, and name
   the 5.3 symptom category.
9. In a pcap, HTTP request headers are readable with `-A` but an HTTPS
   session shows only the ClientHello's server name. What does each fact
   imply for security and for debugging?
10. `ss -tlnp` shows a service on `*:9090`, local curl works, remote curl
    times out. List the remaining suspects in the order you'd check, with
    one command each.

## Answers

1. dig queries the nameserver in /etc/resolv.conf directly. getent walks
   /etc/nsswitch.conf `hosts:` — files, then resolve (systemd-resolved via
   D-Bus, which uses per-interface upstreams incl. MagicDNS), never
   touching resolv.conf. Divergence point: /etc/nsswitch.conf. A broken
   resolv.conf (or a name only MagicDNS/hosts knows) splits them exactly
   this way.
2. Handshake completed (SYN, SYN-ACK, ACK), client sent data (PSH-ACK),
   then the connection was killed by RST. RST with no application log =
   the app likely never saw it: something between socket accept and app
   (crash on read, or an intermediary/firewall reset, or the process died).
   Kernel accepts the handshake on a listening socket before the app
   necessarily handles the data — packets prove kernel-level acceptance,
   not app-level processing.
3. NXDOMAIN: authoritative "this name does not exist" — the zone/name is
   the issue (or a filtering resolver like Pi-hole saying so on purpose).
   SERVFAIL: the recursive resolver itself failed — upstream broken, or
   DNSSEC validation failure (its classic signature). Timeout: no answer
   at all — network path or dead server.
4. systemd-resolved caches answers in-process; a cache hit is answered
   over D-Bus/loopback stub without any packet leaving — nothing for
   tcpdump to see even on `-i any` for port 53 on real interfaces.
   `resolvectl query name` shows the source; `resolvectl statistics`
   shows cache hits (accept: compare `dig +stats` query time ~0ms).
5. First packets relayed through the Dallas DERP server (TLS-wrapped,
   still e2e-encrypted) because no direct path existed yet; meanwhile
   both ends STUN-probed and hole-punched; once simultaneous UDP opened
   the NAT mappings, the connection upgraded live to the direct
   endpoint:port shown.
6. The ACL is evaluated server-side into each node's netmap: pi-zero
   (tag:t3, leaf) is granted almost nothing, so forbidden peers aren't
   "blocked" — they're never included in its netmap and simply don't
   exist from its viewpoint. tp-mudd (tag:t0) sees everything because its
   netmap includes everything.
7. 1280 is tailscale0's NORMAL MTU (WireGuard overhead headroom) — not
   itself the fault. Stalls mean something in the path drops fragments or
   ICMP frag-needed (PMTUD black hole), so flows sized over the usable
   MTU hang while small pings pass. Diagnostic:
   `ping -M do -s 1252 <peer>` (1252 + 28 = 1280) and walk sizes down to
   find the ceiling.
8. On-link range becomes .241–.254 only: those hosts reachable. Gateway
   at .1 is now outside the subnet → no route to it → everything off-LAN
   (internet, other .1.x hosts outside .240/28) unreachable. Category:
   interface misconfiguration (netmask), the "can reach some LAN, not the
   internet" signature.
9. HTTP is plaintext — anyone on-path reads full requests (why TLS
   exists); for debugging it means pcaps are self-documenting. HTTPS
   encrypts the payload; the SNI hostname in ClientHello remains visible
   (metadata leak — and how filtering appliances block by hostname), so
   debugging TLS from pcaps is limited to handshake metadata unless you
   have keys.
10. (a) Host firewall — `sudo firewall-cmd --list-all` (or ufw status):
    port not opened; (b) network-path/platform firewall (cloud security
    list, router ACL — for tailnet peers: the Tailscale ACL) — test from
    another vantage or review policy; (c) routing/reachability —
    `tracepath <host>` / `tailscale ping`; (d) wire truth — tcpdump on
    the server: SYNs arriving and unanswered = local filter; no SYNs =
    upstream. Local curl working already cleared bind address.
