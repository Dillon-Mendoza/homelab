# Subnetting — Method + Drills

CIDR questions are free exam points for anyone who stops counting on fingers.
The method below turns every question into two lookups and a subtraction.
Target: any drill problem in under 30 seconds, no scratch paper.

---

## The Method — Two Facts, Everything Else Derived

**Fact 1 — the powers of 2, cold:**
128, 64, 32, 16, 8, 4, 2, 1 (left to right = bit values in one octet)

**Fact 2 — the /24 anchor:** a /24 is one full octet: 256 addresses, 254
usable. Every other prefix is measured from the nearest octet boundary
(/8, /16, /24, /32).

**The block-size trick (does 90% of the work):**
For any prefix, find the "interesting octet" (the one the mask ends in) and:

```
block size = 2^(bits remaining in that octet)
```

| Prefix | Interesting octet | Block size | Networks look like |
|---|---|---|---|
| /25 | 4th | 128 | .0, .128 |
| /26 | 4th | 64 | .0, .64, .128, .192 |
| /27 | 4th | 32 | .0, .32, .64, .96 ... |
| /28 | 4th | 16 | .0, .16, .32 ... |
| /29 | 4th | 8 | .0, .8, .16 ... |
| /30 | 4th | 4 | .0, .4, .8 ... |
| /23 | 3rd | 2 | x.x.0.0, x.x.2.0, x.x.4.0 ... |
| /22 | 3rd | 4 | x.x.0.0, x.x.4.0 ... |
| /20 | 3rd | 16 | x.x.0.0, x.x.16.0 ... |

**To answer any "what network is host X in":** round the interesting octet
DOWN to the nearest multiple of the block size. Network = that. Broadcast =
next block minus 1. Usable = everything between.

**Host math:** usable hosts = 2^(32 − prefix) − 2. The −2 is network +
broadcast. (/31 point-to-point and /32 host-routes are the exceptions.)

**Mask spellings** (know both directions): /26 = 255.255.255.192 — because
the last octet has 2 network bits: 128+64 = 192. Mask octet = sum of the
leading bit values.

---

## Worked Example

"Host 192.168.1.207/27 — network, broadcast, usable range?"

1. /27 → 4th octet, block size 32 → networks at 0, 32, 64, 96, 128, 160, 192, 224
2. 207 rounds down to 192 → **network 192.168.1.192/27**
3. Next block 224, minus 1 → **broadcast 192.168.1.223**
4. **Usable: .193–.222** (30 hosts = 2^5 − 2)

That host is tp-mudd's actual LAN address. If the LAN were ever segmented,
this is the math that does it.

---

## Drill Set A — Mechanics (answers at the bottom, no peeking mid-set)

1. 10.10.10.130/26 — network and broadcast?
2. How many usable hosts in a /29?
3. 172.16.37.99/20 — what network?
4. Write 255.255.254.0 as a prefix.
5. What mask gives at least 500 usable hosts with the fewest addresses?
6. 192.168.50.14/30 — usable addresses?
7. Which two of these are on the same network as 10.0.4.10/22:
   10.0.5.200, 10.0.8.1, 10.0.7.254?
8. Smallest subnet that fits 25 hosts?
9. 100.115.92.205/28 — network and broadcast?
10. A /16 split into /24s — how many subnets?

## Drill Set B — Scenarios From Your Own Network

1. Your LAN is 192.168.1.0/24 with the gateway at .1. You want a /26 carved
   out for lab VMs that must NOT contain the gateway or tp-mudd (.207).
   Which /26 blocks qualify?
2. Tailscale hands out addresses from **100.64.0.0/10** (the CGNAT range,
   RFC 6598). What is its address span, and how many addresses is that?
3. A Tailscale peer shows 100.101.102.103. Prove it's inside 100.64.0.0/10
   using the block-size trick on the second octet.
4. `dell-fedora` is a KVM guest on a default libvirt NAT network,
   192.168.122.0/24. Can it ever collide with your LAN's 192.168.1.0/24?
   What single change would risk a collision?
5. You promote the parked desktop and give it a static 192.168.1.240/28 by
   mistake (instead of /24). What breaks, and why does it *mostly* still work?

---

## Answers — Set A

1. Block 64 → net **10.10.10.128**, bcast **10.10.10.191**
2. 2^3 − 2 = **6**
3. /20 → 3rd octet, block 16; 37 → 32 → **172.16.32.0/20**
4. 254 = 255−1 → 7 bits in 3rd octet → **/23**
5. 500 ≤ 2^9−2 = 510 → 9 host bits → **/23** (255.255.254.0)
6. Block 4: net .12, bcast .15 → **.13 and .14**
7. /22 block 4 in 3rd octet: 10.0.4.0–10.0.7.255 → **10.0.5.200 and 10.0.7.254** (10.0.8.1 is the next block's network address territory)
8. 25 ≤ 2^5−2 = 30 → **/27**
9. Block 16: 205 → 192 → net **.192**, bcast **.207**
10. 2^(24−16) = **256**

## Answers — Set B

1. Blocks: .0–.63 (contains .1, out), .64–.127 (**qualifies**),
   .128–.191 (**qualifies**), .192–.255 (contains .207, out).
2. /10 → 2nd octet, block 64: 64 → span **100.64.0.0 – 100.127.255.255**,
   2^22 = **4,194,304 addresses**.
3. 2nd octet block 64: 101 rounds down to 64 → same block as 100.64.0.0 ✓
4. No collision as-is — different /24s. The risk: connecting to someone
   else's LAN (hotel, friend's house) that USES 192.168.122.0/24 — then the
   VM's NAT range and the physical LAN overlap and routing gets ambiguous.
   Same reason 192.168.0.0/24 and .1.0/24 make bad VPN-reachable LANs.
5. Its network becomes 192.168.1.240/28 (.241–.254 usable). It can reach the
   gateway only if ARP happens to work... it can't: .1 is outside its subnet,
   so it sends to the gateway via... its route says the gateway is
   unreachable (not on-link). Mostly-works version: hosts .241–.254 are
   "on-link" so it talks to them fine; everything else — including the
   gateway at .1 — is unreachable. Classic "can ping some LAN hosts but not
   the internet" = mask mismatch. (5.3 symptom: interface misconfiguration.)
