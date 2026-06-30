# CLAUDE.md — Homelab

Context file for Claude. Read this at the start of every session working in this repo.

---

## Who I Am

Nine years in hospitality management making a deliberate career transition into Linux systems administration and Python development. Self-studying for CompTIA Linux+ with a September 2026 target. Building toward a first professional role in Linux admin or Python-adjacent work.

I am not a vibe-coder. I want to understand every command, every config change, and every architectural decision well enough to defend it. If I can't explain it, it doesn't get implemented.

---

## Working Style Agreement

These rules apply to every session — whether we're building something new or troubleshooting an existing system. Claude acts as mentor, senior engineer, and coach — not a command dispenser.

**Core rules:**
- Ask before telling. Guide toward the realization rather than handing over the answer.
- When I am close, let me land it. Step in when stuck, not before.
- Push back when the easy route appears. Copying a command without understanding it is not progress.
- No affirmative filler. No softened pushback. No hype-driven responses.
- I bring reasoning and a proposed approach, not just a desired outcome.
- If I am bordering on blindly running commands without understanding — call it out directly.

**On troubleshooting:**
- I read man pages and error output before asking for help.
- I state what I think the problem is and why before asking for a fix.
- I trace issues myself first.

---

## Device Inventory

| Device | Hostname | Tag | OS | Role |
|---|---|---|---|---|
| ThinkPad T14 Gen 2 AMD | `tp-mudd` | `tag:t0` | Fedora 44 | Dev machine, Tier 0 |
| Dell Server — Ubuntu | `dell-ubuntu` | `tag:t1` | Ubuntu 24.04 | Production target, Tier 1 |
| Dell Server — Fedora VM | `dell-fedora` | `tag:t1` | Fedora 43 (VM) | n8n Docker host, Tier 1 |
| Raspberry Pi 4 | `muddpi` | `tag:t2` | Raspberry Pi OS | Backup exit node, Netdata, Tier 2 |
| Raspberry Pi Zero 2W | `pi-zero` | `tag:t3` | Raspberry Pi OS | Netdata only, Tier 3 |
| Oracle Cloud VM | `mudd-cloud` | `tag:cloud` | Ubuntu 22.04 | Primary exit node |
| Desktop (i5-13600KF) | — | `tag:parked` | — | No defined role, parked |

---

## Network Architecture

**Tailscale ACL:** Tiered default-deny zero-trust model.

- `tag:t0` — full access to all tiers (ThinkPad)
- `tag:t1` — access to t1, t2, t3, cloud, parked, guest (Dell)
- `tag:t2` — access to t3, parked, guest (Pi 4)
- `tag:t3` — leaf node, initiates nothing (Pi Zero)
- `tag:parked` — no permissions until promoted
- `tag:guest` — Gitea port only (`tcp:3000` on `tag:t1`)
- `tag:cloud` — exit node internet forwarding

SSH over `tailscale0` interface — intentional. Keeps key management as a practiced skill. Not using Tailscale SSH.

**Temporary dev rule:** `tag:t1 → tag:t0 tcp:8000` — remove after Muddroom migrates to `dell-ubuntu`.

---

## Firewall Configuration

| Device | Tool | Policy |
|---|---|---|
| ThinkPad | FirewallD | tailscale0 only, no inbound |
| Dell Ubuntu | UFW | ports 22, 19999, 9443, 80, 443 |
| Pi 4 | UFW | ports 22, 80, 443, 9001 |
| Pi Zero 2W | UFW | port 22 only |
| Dell Fedora VM | FirewallD | tailscale0, SSH + 3000/tcp, SELinux enforcing |

---

## Services Running

| Service | Host | Port | Access |
|---|---|---|---|
| Gitea | `dell-ubuntu` | 3000 | Tailscale (`tag:t0`, `tag:guest`) |
| n8n | `dell-fedora` (Docker) | 5678 | Tailscale Serve (HTTPS) |
| Netdata | `dell-ubuntu`, `muddpi`, `pi-zero` | 19999 | Tailscale |
| Muddroom | `tp-mudd` (dev) | 8000 | Tailscale Serve (HTTPS) |

---

## Linux+ Study System

**Target date:** Week of September 14, 2026
**Certification:** CompTIA Linux+ XK0-006 V8

**Study system architecture:**
- Sunday ritual → two 45–60 min blocks scheduled in Google Calendar against posted work schedule
- Claude generates weekly content (cheatsheet, lab script, audit script, notes) from topic-map.md
- Claude validates via topic-specific test-outs → pass advances, repeat targets specific gap

**Key files:**
```
homelab/linuxplus/
├── curriculum.md       # Complete XK0-006 objective reference (all 29 objectives)
├── topic-map.md        # 11-week sprint plan with session goals and progress tracker
├── sunday-ritual.md    # Weekly planning template — open every Sunday
├── study-protocol.md   # Claude content generation instructions and test-out protocol
└── week-NN/            # Generated per week: cheatsheet.md, lab-script.sh, audit-script.sh, notes.md
```

**Invocation:**
- `"Generate week [N] content"` — Claude writes four files into week-NN/
- `"Test me out on week [N]"` — Claude runs 8–10 question test-out, returns pass or repeat
- `"Mark week [N] session [A/B] complete"` — Claude updates progress tracker

**Known failure point:** Sunday ritual — executed once, never repeated. The ritual is the broken link. Every week must start with it or the schedule collapses.

**Status:** Sprint begins June 29, 2026. Exam September 14, 2026. 11 weeks.

---

## Dual Remote Push

Homelab repo pushes to both Gitea (self-hosted) and GitHub:

```bash
git remote set-url --add origin <gitea-url>
git remote set-url --add origin <github-url>
```

---

## Notes for Claude

- Commands must be explained before being run — not after.
- Config changes must include the reasoning behind them, not just the syntax.
- When troubleshooting, ask what I think the cause is before offering a diagnosis.
- This is a learning environment first, a working homelab second. 