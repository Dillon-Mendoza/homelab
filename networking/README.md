# Networking — Deep Dives and Practice

Goes deeper than the Linux+ objectives require, anchored to the network you
actually run. This is the one non-linuxplus directory that *supports* the
exam rather than competing with it: subnetting feeds D1 questions, the DNS
and tcpdump material feeds objectives 1.4 and 5.3 directly.

## When to Use What

| File | Use when | Exam relevance |
|---|---|---|
| `subnetting-drills.md` | 15-min drills, any time — now is fine | D1 — CIDR questions are free points once the method is automatic |
| `dns-deep-dive.md` | After week-03 test-out, or when a DNS question stings | 1.4, 5.3 — and your two incidents were both DNS-adjacent |
| `tcpdump-lab.sh` | One Session-B-sized block, post-week-03 | 1.4 tools; builds the packet-level intuition 5.3 assumes |
| `tailscale-internals.md` | Post-exam, or when the mesh misbehaves | Zero direct — but it's YOUR network, and interviews love it |

## Invocation

- `"Drill me on subnetting"` — 5 timed problems, harder each round
- `"Explain this capture: [paste tcpdump output]"`
- `"Quiz me on the DNS resolution chain"`
- `"Extend the tcpdump lab with [X]"`

## Ground Rules

Same as linuxplus: everything here runs on `tp-mudd` alone. Captures are on
loopback and tp-mudd's own interfaces; no other homelab device is a target.
tcpdump on your own machine capturing your own traffic is fine everywhere;
pointing capture or scan tools at networks you don't own is not — the drills
never need to.
