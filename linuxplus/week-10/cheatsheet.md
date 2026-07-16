# Week 10 — Full Troubleshooting Sprint
# Domain: 5.0 Troubleshooting (22%) | Objectives: 5.1, 5.2, 5.3, 5.4, 5.5
# Calendar: Aug 31–Sep 6 | Session A — 45 min read
# This is the highest-value week of the sprint: ~20 questions on exam day.
# Domain 5 tests SYMPTOM → CAUSE mapping, not fixes. Nine weeks of tools are
# already in your hands — this week wires them to symptoms.

---

## The Methodology — Know It Cold, In Order

1. **Identify the problem** — gather info, question users, determine what changed, duplicate if possible
2. **Establish a theory** of probable cause — question the obvious first
3. **Test the theory** — confirmed? proceed. Not confirmed? new theory or escalate
4. **Establish a plan of action** (and identify potential effects)
5. **Implement the solution** — or escalate
6. **Verify full system functionality** — and implement preventive measures
7. **Document** findings, actions, and outcomes

The exam asks "what do you do NEXT" — the answer is almost always the next
step in this list. Jumping from symptom straight to fix skips 2–4; that's the
wrong answer even when the fix is right. Your `incidents/` directory is this
list in practice: the ACL outage writeup is literally steps 1→7 on paper.

---

## 5.1 — Monitoring Concepts

### SLA / SLO / SLI — three letters, one ladder

| Term | What | Example |
|---|---|---|
| **SLA** | The **contract** — external promise, penalty for breach | "99.5% uptime or credits refunded" |
| **SLO** | The **internal target** — stricter than the SLA (your buffer) | "we aim for 99.9%" |
| **SLI** | The **measurement** — the actual metric | "99.94% of requests succeeded" |

Order of strictness: SLO ≥ SLA. The SLI is what you *measure* to know if
you're meeting the SLO. Exam phrasing: "which is the agreement?" → SLA.

### SNMP

- **Agent** runs on the monitored host; **manager** collects centrally.
- **Polling** (manager asks: GET) vs **traps** (agent pushes asynchronously —
  "trap" = device-initiated notification, no polling involved).
- **MIB** — Management Information Base: defines what each **OID** number means.
- v1/v2c authenticate with a plaintext *community string*; **v3 adds auth +
  encryption** — the only version you'd deploy today.

### Agent vs agentless + the config vocabulary

- **Agent-based:** software installed on the target (Netdata on `muddpi` and
  `pi-zero` — your fleet is agent-based monitoring, live).
- **Agentless:** poll from outside — SNMP GET, SSH checks, HTTP health checks.
- **Threshold** → crossing it raises an **event** → event triggers an **alert**
  → alert sends a **notification** (email, page) or fires a **webhook** —
  an HTTP POST to a URL with a payload (this is exactly what n8n consumes;
  the lab makes you catch one on localhost with `nc`).
- **Health check** — scripted "is it alive" probe: `systemctl is-active`,
  `curl -sf http://host/health` — your Week 8 script was one.
- **Log aggregation** — ship logs to one place (central rsyslog, Loki, ELK)
  so you grep one host instead of seven.

---

## 5.2 — Hardware / Storage / OS: Symptom → First Command → Likely Cause

| Symptom | First command(s) | Likely cause |
|---|---|---|
| Kernel panic | console/photo, then `journalctl -b -1 -k` after reboot | bad module, corrupt initrd, failing RAM |
| Filesystem won't mount | `dmesg -T \| tail`, `blkid`, `fsck` (ext4) / `xfs_repair` (xfs) | corruption, wrong UUID in fstab, missing device |
| Filesystem full | `df -h` → `du -xsh /* 2>/dev/null` → `lsof +L1` | big files, logs — or a **deleted file still held open** |
| "No space left" but `df -h` shows space | `df -i` | **inode exhaustion** — millions of tiny files |
| GRUB misconfig / won't boot | rescue media; `/etc/default/grub`, then `grub2-mkconfig -o /boot/grub2/grub.cfg` | edited grub.cfg directly (regenerated = overwritten) |
| systemd unit fails | `systemctl status U` → `journalctl -u U` → `systemd-analyze verify U` | bad ExecStart path (**203/EXEC**), missing dep, edit without `daemon-reload` |
| Device missing / no driver | `lsmod`, `dmesg -T`, `lspci -k`, `modprobe` | module not loaded, blacklisted, or absent |
| Partition not writable | `findmnt /mount` — read the OPTIONS column | mounted `ro`; or remounted ro after fs errors (check dmesg) |
| Script won't run, perms look fine | `findmnt` → `noexec`? `ls -Z` → SELinux? | **noexec mount option** or SELinux context — not chmod |
| Quota exceeded | `quota -u user`, `repquota -a` | user hit block/inode quota |
| Memory leak | `ps aux --sort=-%mem \| head`, watch RSS grow over time | one process growing without bound |
| `command not found` (binary exists) | `echo $PATH`, `type -a cmd` | PATH misconfiguration — often a broken profile edit |
| Process randomly killed | `journalctl -k -g -i oom` | **OOM killer** — kernel chose a victim under memory pressure |
| Process unkillable, state `D` | `ps -eo pid,stat,wchan,cmd \| awk '$2~/D/'` | **uninterruptible sleep** — waiting on I/O (often dead NFS/disk); even `kill -9` waits |
| Segmentation fault | `coredumpctl list` → `coredumpctl info PID` | program bug — bad memory access; you diagnose, dev fixes |
| Zombie (`Z` state) | `ps -eo pid,ppid,stat,cmd \| awk '$3~/Z/'` | parent never called `wait()` — **kill the PARENT**, not the zombie |

---

## 5.3 — Networking: Diagnose in Layer Order

**The progression — always:** physical → link → IP → routing → firewall → DNS
→ application. Never start at the top. (The ACL outage writeup walks this
exact ladder — steps 1–5 of its diagnostic process.)

| Symptom | First command(s) | Likely cause |
|---|---|---|
| Link down | `ip link` (state DOWN?), `ethtool eth0` ("Link detected: no") | cable, NIC, or interface administratively down |
| Link negotiation failure | `ethtool eth0` — speed/duplex mismatch | forced speed on one end, auto on the other |
| No IP / DHCP failure | `ip addr` (169.254.x.x = APIPA → no DHCP answer), `journalctl -u NetworkManager`, `nmcli device status` | DHCP server unreachable/exhausted |
| Can't ping server | work the ladder: `ping <gw>` → `ping 1.1.1.1` → `ping name` | wherever it first fails, that layer is broken |
| Gateway misconfigured | `ip route show default` | no default route, or default via wrong hop |
| DNS failure | `dig name` vs `dig name @1.1.1.1` vs `getent hosts name` | resolver down vs upstream vs nsswitch — the trio isolates which |
| IP conflict | `arping -D <ip>`, journal "duplicate address" | two hosts claim one IP — intermittent, ARP-cache dependent |
| MTU mismatch | `ping -M do -s 1472 host` (1472+28=1500) | small pings pass, big transfers hang; fragmentation blocked |
| Dual-stack weirdness | `curl -4` vs `curl -6` the same URL | one address family broken, apps pick the broken one first |
| Firewall blocking | `sudo firewall-cmd --list-all`, `ss -tlnp` on the server | service listening but zone/port not open — connection **refused vs timeout**: refused = host reachable, port closed; timeout = filtered or unroutable |
| Packet loss / drops | `ip -s link` (RX/TX errors, dropped), `mtr host` | bad cable, saturation, buffer drops |

**Fedora-specific layer you must know:** `/etc/resolv.conf` is a **symlink**
to `/run/systemd/resolve/stub-resolv.conf` (nameserver 127.0.0.53 — the local
stub). `dig` reads resolv.conf directly; `getent hosts` walks
`/etc/nsswitch.conf`, where `resolve [!UNAVAIL=return]` hands off to
systemd-resolved over D-Bus *without touching resolv.conf*. Consequence: a
corrupted resolv.conf breaks `dig` but NOT `curl`/`getent`. The lab makes you
watch the two paths diverge. `resolvectl status` shows the real upstream DNS
per interface.

---

## 5.4 — Security: Symptom → First Command → Likely Cause

| Symptom | First command(s) | Likely cause |
|---|---|---|
| Service fails, perms "look right" | `sudo ausearch -m AVC -ts recent`, `sealert -a /var/log/audit/audit.log` | SELinux: **context** (→ `restorecon`), **boolean** (→ `setsebool`), or **policy** (→ `audit2allow`) |
| Permission denied on file | `ls -l` then `getfacl` — the `+` after mode bits means ACLs exist | ACL denies even though mode bits allow |
| User can't log in | `passwd -S user` (locked?), `chage -l user` (expired?), `faillock --user user` | locked account, aged-out password, pam_faillock lockout |
| Login works, SSH key doesn't | `ls -ld ~/.ssh ~/.ssh/authorized_keys` | perms too open — sshd refuses (700 dir / 600 file) |
| TLS/cert errors | `openssl s_client -connect host:443`, `openssl x509 -in cert -noout -enddate` | expired cert, self-signed, hostname mismatch |
| Cipher negotiation failure | `openssl s_client` output; server/client config | one side only offers algorithms the other has removed |
| `dnf`/`apt` repo errors | GPG key mismatch, 404 on baseurl; `dnf clean all` then retry | misconfigured/stale repo file, missing signing key |
| Insecure protocol in use | `ss -tlnp` — look for :23 (telnet), :21 (ftp), :69 (tftp) | legacy service still enabled — disable it |
| "Unpatched system" scenario | `dnf updateinfo list security`, CVE/CVSS vocabulary | patching gap; **backporting** = fix applied to old version number (scanner sees "old" version but hole is closed) |

---

## 5.5 — Performance: Read the Numbers Like Sentences

### Load average — the most misread metric

Load = average count of tasks **running + runnable + uninterruptible (D-state)**.
Compare against `nproc`. Three numbers = 1, 5, 15-minute windows (trend!).

- Load 8 on 8 cores, CPU 100% → CPU-bound. Add capacity or nice it.
- **Load 8, CPU nearly idle → processes stuck in D-state: I/O or memory
  bottleneck.** This is the exam's favorite trap.
- 1-min > 15-min → getting worse; 1-min < 15-min → recovering.

### vmstat 1 5 — column decoder (first line is boot-average; ignore it)

| Column | Meaning | Red flag |
|---|---|---|
| `r` | runnable queue | consistently > nproc → CPU bottleneck |
| `b` | blocked (D-state) | > 0 sustained → I/O bottleneck |
| `si` / `so` | swap in/out per sec | **nonzero sustained = swapping — RAM exhausted** |
| `wa` | % CPU idle *waiting on I/O* | high wa = disk is the wall, not CPU |
| `cs` | context switches/sec | huge spikes → too many chatty processes/interrupts |
| `us` / `sy` / `id` | user / kernel / idle CPU | high `sy` alone → kernel/driver churn |

### The rest of the toolkit

- `free -h` — read the **available** column, not "free" (buffers/cache are
  reclaimable; low "free" alone is healthy Linux, not a problem).
- **OOM** — kernel kills the biggest offender under pressure:
  `journalctl -k -g -i oom`. Symptom: process vanished, no crash log of its own.
- **PSI** (pressure stall info): `/proc/pressure/{cpu,memory,io}` — "some"
  = fraction of time ≥1 task stalled on that resource. Modern, per-resource,
  no interpretation debate. `avg10` climbing = pressure right now.
- `iostat -x 1` (sysstat): `%util` near 100 + `await` climbing = disk saturated.
- `sar` (sysstat) — the same metrics, *historically*: yesterday's spike is
  still readable. `sar -u`, `sar -r`, `sar -b`.
- `pidstat 1` — per-process CPU/IO/memory — *which* process, not just "the system".
- Network perf: drops → `ip -s link`; latency/jitter path → `mtr`;
  throughput → `iperf3` (server one terminal, `-c 127.0.0.1` in another).
- Slow startup → `systemd-analyze blame` + `systemd-analyze critical-chain`.
- Sluggish shell/terminal → usually a hung PATH dir (dead NFS), a full
  filesystem, or DNS timing out in a prompt hook — not "the CPU".

---

## Quick Recall

methodology step 3 — test the theory BEFORE planning the fix
SLA contract / SLO internal target (stricter) / SLI the measurement
SNMP trap — agent pushes async; MIB defines OIDs; v3 = auth + encryption
webhook — HTTP POST fired at a URL when an event triggers
`df -h` full but `du` disagrees — deleted-but-open file → `lsof +L1`
"No space left" with free blocks — `df -i`, inode exhaustion
203/EXEC in systemctl status — ExecStart path wrong/not executable
unit edits do nothing until `systemctl daemon-reload`
zombie — already dead; kill the PARENT
D-state — uninterruptible I/O wait; ignores SIGKILL; counts toward load
high load + idle CPU = I/O or memory, not CPU
vmstat si/so nonzero sustained = swapping = RAM exhausted
connection refused = port closed; timeout = filtered/unroutable
`ping -M do -s 1472` — MTU/fragmentation test for a 1500 link
dig reads resolv.conf; getent walks nsswitch (resolved via D-Bus) — they can disagree
perms look right but "Permission denied" — check `noexec` mount, then `ls -Z`
