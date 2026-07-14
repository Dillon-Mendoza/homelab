# Linux+ Study Protocol — Claude Content Generation
# XK0-006 V8 | Target: September 14, 2026

This file defines how Claude generates weekly study content for the Linux+ sprint.
Claude reads this file, curriculum.md, and topic-map.md before generating anything.

---

## Invocation Commands

**"Generate week [N] content"**
Claude reads topic-map.md to confirm the week's domain, objectives, calendar window,
and session goals. Reads curriculum.md for full objective scope. Generates four files
into week-[NN]/ (zero-padded). Confirms output with a one-line summary per file.

**"Regenerate week [N] [filename]"**
Regenerates that single file only. Use when a specific file needs revision.

**"Generate week [N] supplemental — weak area: [topic]"**
Generates supplemental-[topic].md and supplemental-lab.sh in the week folder.
Used when a Claude test-out returns a repeat recommendation for a specific gap.

**"Test me out on week [N]"**
Claude quizzes on that week's objectives. 8–10 questions, mix of multiple choice
and scenario-based. Returns pass or repeat recommendation with specific gaps named.

**"Mark week [N] session [A/B] complete"**
Claude updates the checkbox in topic-map.md progress tracker.

---

## Output Files — Four Per Week

### 1. cheatsheet.md — Session A material (45 min read)

Header block:
- Week number, phase, domain, objectives covered, calendar window

Body format — for every command, concept, or tool in scope:
- Name → what it does → syntax → concrete example using homelab context where possible
- Every runnable example must work on tp-mudd alone (see Hard Constraint below)
- Prefer real tp-mudd paths (`/home/tp-mudd/...`); no generic /path/to/file examples
  when a real one exists
- Other fleet devices (dell-ubuntu, dell-fedora, muddpi, pi-zero, mudd-cloud) may
  appear as *conceptual* reference points only — never as a command target

End with a "Quick Recall" section:
- 12–15 items, one line each, no explanation
- Format: `command or concept` — one-phrase definition
- These are for self-testing after the read

Constraints:
- Dense but scannable in 45 minutes
- No filler, no padding
- Every line earns its place
- Difficulty calibrated for someone who has run a Linux homelab for months but is
  not yet fluent with the exam's specific command flags and edge cases

### 2. lab-script.sh — Session B hands-on (45–60 min)

Structure:
```bash
#!/bin/bash
# Week NN — [Topic]
# Objectives: [X.X, X.X]
# Run on: tp-mudd only — fully self-contained, no other devices required
# Estimated time: 45–60 min

DRY_RUN=true   # Set to false to execute. true echoes commands instead.
```

Each task block:
```bash
# ── TASK N: [What this does] ──────────────────────────────────────────────
# Why it matters: [one sentence — exam context or real-world relevance]
# Command:
run_cmd "actual-command --with flags"
```

Use a `run_cmd` wrapper that respects DRY_RUN:
```bash
run_cmd() { if $DRY_RUN; then echo "[DRY RUN] $*"; else eval "$@"; fi; }
```

Include `echo` progress markers between tasks so the session has a visible flow.
End with a summary comment block: what was practiced, which objectives were covered.

**HARD CONSTRAINT — ThinkPad only.** Every lab task and audit check must be fully
executable on tp-mudd (ThinkPad T14, Fedora 44) with no other device involved:
- No SSH to other homelab nodes, and no task that requires another node to be
  powered on or reachable. Public internet targets (e.g. `1.1.1.1`) are fine for
  path/DNS tools; other homelab devices are not, even as ping targets.
- Simulate multi-machine and cross-distro scenarios locally instead — these teach
  more than remote inspection anyway:
  - dpkg/apt family practice → Ubuntu container via podman (ships with Fedora)
  - disks, LVM, RAID, filesystems → loop devices backed by files in /tmp
  - client/server network tools → run both ends on tp-mudd (localhost services,
    `iperf3 -s` + `-c 127.0.0.1`, `ssh localhost` for remote-syntax practice)
  - virtualization → tp-mudd has AMD-V; use qemu-img on throwaway images and,
    as optional stretch, a disposable local VM via libvirt/virt-install
- Ubuntu/Debian command differences stay in cheatsheets and notes as exam
  knowledge — the exam tests both families; only *execution* is Fedora-local.
- Other fleet devices (dell-ubuntu, dell-fedora, muddpi, pi-zero, mudd-cloud)
  may be referenced conceptually ("this is what production does") but never
  as something the student must run a command on or against.

### 3. audit-script.sh — Security/validation (re-runnable anytime)

Purpose: audit or validate the week's topic area on the local system.
Not a one-time exercise — designed to be useful as an ongoing tool.
Same hard constraint as the lab: every check runs on tp-mudd alone and must not
fail just because another homelab device is powered off.

Output format:
```
══════════════════════════════════════════
  AUDIT: [Topic] — $(date)
══════════════════════════════════════════
[PASS] Description of what was checked
[WARN] Description of something worth attention
[INFO] Neutral finding
══════════════════════════════════════════
  Summary: X passed, Y warnings
══════════════════════════════════════════
```

Examples by domain:
- Permissions weeks: suspicious SUID/SGID files, world-writable directories
- User management weeks: sudo access, locked accounts, password aging
- SSH weeks: sshd_config insecure settings, authorized_keys permissions
- Firewall weeks: active rules dump, open ports cross-referenced against expected state
- Logging weeks: log file permissions, rsyslog status, journal persistence mode

### 4. notes.md — Reference and context

Sections (in order):

**Exam Objective Mapping**
- Objective codes covered this week with their full titles from curriculum.md

**Key Man Pages**
- 3–5 man pages relevant to this week's commands
- Format: `man [section] command` — what section to read specifically (not just "read it")

**Video Timestamps**
- Point to the relevant section of the XK0-006 theory course (12hr YouTube series)
  for Session A reinforcement. Use topic name since timestamps shift between versions.
- Point to relevant section of the XK0-006 labs course (7hr YouTube series) for
  Session B context.

**Things That Trip People Up**
- 4–6 exam gotchas specific to this week's objectives
- Focus on: things that look right but aren't, flag combinations that are counterintuitive,
  behavior differences between distros (Ubuntu vs Fedora matters for this homelab)

**Connect to the Homelab**
- One paragraph explaining where this week's topic is already live in the homelab
- Reference specific devices, services, config files that are already in production
- This is the bridge between abstract exam content and real experience already earned
- Fleet devices are cited here as conceptual anchors only — the paragraph must
  never instruct running anything on a device other than tp-mudd

---

## Quality Standards

- Write like a technical mentor. Not a textbook, not a tutorial for beginners.
- Dillon has run a multi-device Tailscale homelab for months. Do not over-explain
  concepts already demonstrated by the homelab (e.g. do not explain what SSH is).
- Be specific: real commands, real paths, real device names.
- Calibrate difficulty upward as weeks progress. Week 1 can be foundational.
  Week 10 should assume the prior 9 weeks landed.
- If a topic has a known exam trap (e.g. xfs cannot shrink), surface it explicitly.
  Do not bury it in general explanation.

---

## Test-Out Protocol

After completing both sessions for a week, Dillon says: "Test me out on week [N]"

Claude generates 8–10 questions:
- Mix: ~60% scenario-based ("Given this output, what is the cause"), ~40% definition/syntax
- Difficulty: matches XK0-006 performance-based question style
- No hints during the quiz

Scoring:
- 8/10 or higher → PASS. Claude updates the test-out checkbox in topic-map.md.
- 7/10 or lower → REPEAT. Claude names the specific gaps (not just "review the week").
  Dillon says "Generate week [N] supplemental — weak area: [named gap]"

A repeat does not mean the week failed. It means targeted drilling is needed before advancing.

---

## Source of Truth Files

Before generating any content, Claude reads:
1. `curriculum.md` — complete XK0-006 objective reference with all sub-topics
2. `topic-map.md` — sprint schedule, session goals, and progress tracker

CLAUDE.md at the repo root contains the homelab device inventory, network architecture,
and working style agreement. That context is always available and does not need to be
repeated here.
