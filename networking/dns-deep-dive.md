# DNS — The Full Chain, Deeper Than the Exam

Both documented homelab incidents were DNS-adjacent. That's not coincidence —
DNS sits at the intersection of caching, layering, and stale state, which is
where systems actually fail. This doc goes from protocol to your specific
stack.

---

## The Resolution Chain — Who Asks Whom

```
application
  → stub resolver (glibc, per nsswitch.conf)
    → local caching resolver (systemd-resolved on Fedora / Pi-hole if pointed there)
      → recursive resolver (ISP, 1.1.1.1, or Pi-hole's upstream)
        → root servers          ("ask .com's servers")
          → TLD servers         ("ask example.com's servers")
            → authoritative     (the actual answer, with a TTL)
```

- **Stub** = asks one question, expects a full answer. Every ordinary process.
- **Recursive** = does the walking (root → TLD → authoritative) and caches.
- **Authoritative** = owns the zone; its answers are the truth, TTL says how
  long anyone may cache it.
- **Watch recursion happen:** `dig +trace example.com` performs the walk
  yourself, showing each delegation. Run it once slowly — the whole
  architecture is in that output.

## Record Types — the table worth owning

| Type | Maps | Notes |
|---|---|---|
| A / AAAA | name → IPv4 / IPv6 | the workhorses |
| CNAME | name → another name | no other records may coexist at a CNAME; can't be at a zone apex |
| MX | domain → mail host + priority | lower priority number wins |
| TXT | name → arbitrary text | SPF/DKIM/verification live here |
| NS | zone → its authoritative servers | delegation glue |
| SOA | zone → serial, refresh, retry, TTLs | `dig soa domain` — zone metadata |
| PTR | IP → name (reverse) | `dig -x 1.1.1.1`; lives under in-addr.arpa |
| SRV | service → host:port | `_service._proto.name` — LDAP/Kerberos land |
| CAA | domain → allowed CAs | which CAs may issue certs for the domain |

## dig Cookbook

```bash
dig example.com                    # full ceremony: QUESTION/ANSWER/AUTHORITY sections
dig +short example.com             # just the answer
dig example.com @1.1.1.1           # bypass local resolver — THE isolation move
dig +trace example.com             # walk the delegation chain yourself
dig -x 100.100.100.100             # reverse (PTR)
dig mx gmail.com +short            # specific record type
dig +norecurse example.com @a.root-servers.net   # see a referral, not an answer
dig example.com +stats | grep 'Query time'       # cache hit ≈ 0ms, miss = real latency
```

Read the flags line: `qr rd ra` normal; **`aa`** = authoritative answer;
status **NXDOMAIN** = name doesn't exist (an authoritative "no") vs
**SERVFAIL** = the resolver failed (a broken "can't answer") vs **timeout**
= nobody answered at all. Three different failures, three different causes:
NXDOMAIN → the name/zone; SERVFAIL → the recursive resolver (often DNSSEC);
timeout → network path or dead server.

## TTL and the Two Lies of Caching

`dig +short example.com` twice — the second answer's TTL (visible without
+short) counts down: you hit a cache. Caches are why DNS "works" at scale
and why every DNS change appears broken for someone: old answers live until
TTL expiry, *per cache*. The n8n incident was this pattern in miniature —
not TTL, but the same class: **a resolver answering from state that stopped
being true** (a container holding resolv.conf from a network that no longer
existed). When DNS "lies", the question is always: *which cache, how stale,
and what refreshes it.* Flush points on Fedora: `resolvectl flush-caches`;
for a container: restart it; for a browser: it has its own.

---

## Your Actual Stack, Layer by Layer (tp-mudd)

1. `/etc/nsswitch.conf` `hosts:` line — the router. `files` (=/etc/hosts) →
   `myhostname` → `resolve` (systemd-resolved via D-Bus) → `dns` (resolv.conf,
   effectively never reached when resolved is up).
2. **systemd-resolved** — the local stub+cache at 127.0.0.53. Per-interface
   upstreams (`resolvectl status`): the LAN interface learns DNS from DHCP;
   **tailscale0 gets 100.100.100.100 — MagicDNS.**
3. **MagicDNS** — Tailscale's resolver at 100.100.100.100 answers for peer
   names (`muddpi` → its 100.x address) and forwards everything else. This is
   why `ssh muddpi` works with no /etc/hosts entry. Split-DNS routing:
   resolved sends `*.ts.net` and bare peer names to 100.100.100.100, the
   rest to the LAN's DNS.
4. **Pi-hole** (per infra docs) — a filtering recursive resolver on the
   network path: ad/tracker domains return NXDOMAIN or 0.0.0.0 on purpose.
   Debugging rule of thumb: when one machine resolves a name and another
   doesn't, check which resolver each actually uses (`resolvectl status`,
   not assumptions) before blaming the zone.
5. `/etc/resolv.conf` — on Fedora, a symlink to resolved's stub file; week-10
   lab Task 4 proved which tools read it (dig) and which never do (glibc path).

**The layered-stack triage sequence** (each step isolates one layer):

```bash
getent hosts NAME          # what applications actually get (full nsswitch path)
dig NAME                   # what the resolv.conf path gets
dig NAME @1.1.1.1          # bypass everything local — is the zone itself fine?
resolvectl status          # who are my upstreams, per interface?
resolvectl query NAME      # resolved's own verdict, with which protocol/interface
```

Any disagreement between two adjacent steps names the broken layer.

---

## Exercises (tp-mudd only, 20 minutes)

1. `dig +trace fedoraproject.org` — count the delegations. Name each server's
   role using the chain diagram.
2. `resolvectl status` — write down, from memory afterward: which interface
   uses which DNS server, and where MagicDNS appears.
3. `dig muddpi` vs `getent hosts muddpi` vs `resolvectl query muddpi` —
   predict which succeed and why before running. (No packets to muddpi are
   involved — the RESOLVER answers whether the host is up or not. Resolution
   ≠ reachability; a question the incidents already taught the hard way.)
4. Find a domain with a CNAME chain (`dig www.github.com`) — follow name →
   name → A in the ANSWER section.
5. `dig +dnssec fedoraproject.org | grep -E 'RRSIG|flags'` — the `ad` flag
   and RRSIG records are DNSSEC: signed answers, the anti-spoofing layer.
