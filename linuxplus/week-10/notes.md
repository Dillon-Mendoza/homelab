# Week 10 — Reference Notes
# Objectives: 5.1–5.5 | Calendar: Aug 31–Sep 6

---

## Exam Objective Mapping

**5.1 — Summarize monitoring concepts and configurations in a Linux system**
- Service monitoring: SLA (agreement), SLI (indicator/measurement), SLO (objective)
- Data acquisition: SNMP traps, MIBs, agent vs agentless
- Configs: thresholds, alerts, events, notifications, webhooks, health checks, log aggregation

**5.2 — Analyze and troubleshoot hardware, storage, and Linux OS issues**
- Kernel panic/corruption, filesystem won't mount, filesystem full, inode exhaustion
- GRUB misconfiguration, systemd unit failures, missing/disabled drivers, device failure
- Partition not writable, quotas, memory leaks, PATH misconfiguration
- Killed/unresponsive processes, segfaults, server inaccessible/won't power on

**5.3 — Analyze and troubleshoot networking issues**
- Misconfigured firewalls, DHCP/DNS failures, MTU mismatch, bonding, MAC spoofing
- Routing/gateway issues, unreachable server, IP conflicts, dual-stack, link down/negotiation

**5.4 — Analyze and troubleshoot security issues**
- SELinux denials (policy/context/boolean), permission and ACL denials
- Account access failures, unpatched systems, exposed services, remote access,
  certificate issues, insecure protocols, cipher failures, misconfigured repos

**5.5 — Analyze and troubleshoot performance issues**
- OOM, swapping, high CPU/load/context switching, high I/O wait and disk latency
- Packet drops, jitter, latency, disconnects; slow startup, sluggish terminal,
  blocked processes, CPU bottleneck, slow remote storage

Domain 5 is 22% of the exam — roughly one question in five. Nothing this week
is a new tool; it is nine weeks of tools re-indexed by symptom.

---

## Key Man Pages

`man 8 vmstat` — FIELD DESCRIPTION section only. Six lines of it (r, b, si,
so, wa, cs) decode every 5.5 output-interpretation question. Read it after lab
Task 5 while your own numbers are fresh.

`man 5 systemd.exec` — the "Process Exit Codes" section near the bottom: the
table where 203/EXEC lives, alongside its siblings (200–243). One skim tells
you these codes are systemd talking, not the application.

`man 8 lsof` — search for `+L1` (link count section). Two paragraphs that
explain exactly why lab Task 2c's deleted file kept its blocks.

`man 5 proc` — the `/proc/loadavg` and `/proc/pressure` entries. loadavg's
first sentence states the D-state inclusion that makes "high load, idle CPU"
make sense; the pressure entry documents PSI's some/full lines.

`man 1 resolvectl` — the `dns`, `revert`, and `flush-caches` verbs you used in
Task 4, plus `status` output format. This page is the map of Fedora's actual
DNS stack; `man 8 systemd-resolved` is the companion if the stub/symlink model
still feels loose.

---

## Video Timestamps

**Theory Course (12hr — nGPK6YBbKpg):**
The Domain 5 material sits at the end of the course — monitoring concepts
(5.1) first, then the troubleshooting sections in objective order. The
methodology steps and SLA/SLO/SLI get their own segment: watch that one before
Session A if the ladder ordering (SLO stricter than SLA) doesn't stick from the
cheatsheet alone. The symptom catalogs (5.2–5.5) are best watched AFTER the
lab — every symptom they list, you will have caused at least one cousin of.

**Labs Course (7hr — JXIaR23OdB8):**
The troubleshooting labs near the end are scenario walkthroughs. Watch for one
thing specifically: at which methodology step does the presenter start typing?
A good walkthrough gathers info first (step 1); if they jump straight to a fix,
name the skipped steps out loud. Their disk-full and DNS labs will look
familiar — you will have already run harder versions of both.

---

## Book Reference — How Linux Works, 3rd Ed. (Ward)

No new chapters this week — the topic-map is explicit that the book now works
as a reference map, and the lab is built to send you back into it: a fault's
symptom is the question, the chapter is the mechanism underneath.

- Task 2 (disk full, inodes, deleted-open files) → **Ch. 4**: the inode section
  explains why a file with no directory entry still owns blocks.
- Task 1 (unit failure) → **Ch. 6**: unit lifecycle and dependency resolution —
  what daemon-reload actually rebuilds.
- Task 5 (load, D-state, OOM) → **Ch. 8**: process states and resource
  monitoring; the mechanism behind every 5.5 symptom.
- Task 4 (DNS layers) → **Ch. 9**: the resolution order discussion predates
  systemd-resolved's dominance — note where your observed Fedora behavior
  (nss-resolve before dns) diverges from the classic resolv.conf-only story.

---

## Things That Trip People Up

**1. Zombies are already dead — kill the parent**
`kill -9` on a zombie does nothing; there is no process left to kill, only an
exit status waiting for a parent's `wait()`. The exam answer is always: signal
or fix the PARENT (reparenting to init/systemd reaps them automatically).

**2. High load average with an idle CPU is not a CPU problem**
Load counts runnable AND D-state (uninterruptible I/O wait) tasks. Load 12 on
4 cores with `us` near zero means processes are stuck on disk/NFS, not
competing for CPU. vmstat's `b` column and `wa` confirm it. Questions that pair
"high load" with "low CPU utilization" are testing exactly this.

**3. df says full, du disagrees → a deleted file is still open**
Deleting a file removes the name, not the inode — blocks free only when the
last open file descriptor closes. `lsof +L1` lists the ghosts. Classic form:
"we deleted the huge log but the disk is still full" → restart (or signal) the
process holding it. You built this live in lab Task 2c.

**4. "Permission denied" that chmod can't fix**
Two culprits before you blame mode bits: the **mount options** (`noexec` blocks
execution regardless of +x — `findmnt <mountpoint>` reveals it) and **SELinux**
(`ausearch -m AVC`). If `ls -l` looks right, stop staring at it and check the
layer above (mount) or beside (context, ACLs — the `+` in `ls -l` output).

**5. On Fedora, resolv.conf is a symlink — and not every tool reads it**
`/etc/resolv.conf` → `/run/systemd/resolve/stub-resolv.conf` (127.0.0.53).
`dig`/`host`/`nslookup` read resolv.conf directly; `getent`, `curl`, and
everything using glibc walks `/etc/nsswitch.conf`, where `resolve` hands off to
systemd-resolved over D-Bus before `dns` is ever consulted. So a corrupt
resolv.conf can break `dig` while `curl` keeps working. Exam answers assume the
classic model (corrupt resolv.conf = DNS down); know both stories and which
one the question is telling. The isolation move either way: `dig name @1.1.1.1`
— if an explicit server answers, the network is fine and the resolver config
is the fault.

**6. SLO is stricter than SLA — and the SLI is neither**
The SLA is the external contract (breach = penalty), the SLO is the tighter
internal target that keeps you from ever touching the SLA, and the SLI is just
the measured number compared against them. Questions swap the words; anchor on
A = agreement, O = objective (internal), I = indicator (measurement).

---

## Connect to the Homelab

This week is the only one where the homelab has already handed you the exam
answers in writing: `homelab/incidents/` contains two genuine Domain 5
scenarios, worked end-to-end. The Tailscale ACL outage is a 5.3 routing/
firewall case that was cracked by layer-order discipline — DNS ruled out,
firewall ruled out, gateway ruled out, then `ip route show table 52` exposed
the forwarding path — and its writeup is the 7-step methodology in the wild,
through step 7 (documentation). The n8n DNS failure is 5.3's stale-state
variant, and lab Task 4 deliberately built its little sibling on tp-mudd. It
also carries an honest step-6 failure: the `daemon.json` DNS pin recommended in
the writeup was never applied, so the incident is scheduled to recur — worth
resolving after the exam, on its own machine. On the monitoring side, 5.1 is
already your fleet's architecture: Netdata agents on `dell-ubuntu`, `muddpi`,
and `pi-zero` are agent-based monitoring, and n8n on `dell-fedora` is a
webhook consumer — lab Task 6's nc listener was a localhost stand-in for
exactly that endpoint. All of these are conceptual anchors only; every command
this week ran on tp-mudd.
