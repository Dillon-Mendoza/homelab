# Week 05 — Processes + Software + Systemd
# Domain: 2.0 Services and User Management (20%) | Objectives: 2.3, 2.4, 2.5
# Calendar: Jul 27–Aug 2 | Session A — 45 min read

---

## Objective 2.3 — Processes and Jobs

### Process States — Read Them From ps

The `STAT` column of `ps aux` is the exam's favorite output to hand you:

| Code | State | Meaning |
|---|---|---|
| `R` | Running | On a CPU or in the run queue |
| `S` | Sleeping (interruptible) | Waiting for an event — most processes, most of the time |
| `D` | Uninterruptible sleep | Waiting on I/O, **cannot be signaled** — a pileup of D states means a storage problem (Week 10's high-I/O-wait symptom) |
| `T` | Stopped | SIGSTOP/SIGTSTP (Ctrl+Z) — resumable with SIGCONT |
| `Z` | **Zombie** | Exited, but parent hasn't called `wait()`. Uses no CPU/RAM — just a process-table entry |

**The zombie rule:** you cannot kill a zombie — it's already dead. `kill -9` does nothing. The fix is to signal (or fix) the *parent* so it reaps the child; if the parent dies, systemd adopts and reaps the zombie automatically. Suffixes you'll also see: `s` = session leader, `+` = foreground, `<` = high priority, `N` = niced.

### The Monitoring Toolbox

| Tool | What it answers | Detail |
|---|---|---|
| `ps aux` / `ps -ef` | Everything running | BSD vs SysV flag styles — both appear on the exam. `ps -o pid,ppid,stat,ni,comm` picks columns |
| `pstree -p` | Who spawned whom | Instantly shows parent/child — the zombie-diagnosis view |
| `top` | Live sorted view | Keys: `M` sort by memory, `P` by CPU, `k` kill, `r` renice, `1` per-core |
| `htop` | top, but usable | F5 tree view, F6 sort |
| `atop` | Historical resource logging | Records to `/var/log/atop/` — replay past incidents |
| `lsof -p PID` | Files a process holds open | Week 4's `(deleted)` case; `lsof -i :8080` = who owns that port |
| `strace -p PID` | Live syscalls | "What is this hung process actually doing" — attach, watch, Ctrl+C |
| `pidstat 2 5` / `mpstat 2 5` | Per-process / per-CPU stats over time | From the `sysstat` package; interval + count arguments |
| `/proc/PID/` | Kernel's raw view | `cmdline`, `status` (state, UIDs), `fd/` (open file descriptors), `environ` |

### Signals

`kill` sends signals — SIGKILL is just one of them, and the exam tests the numbers:

| # | Signal | Effect | Catchable? |
|---|---|---|---|
| 1 | SIGHUP | Historically "terminal closed"; daemons repurpose it as **reload config** | Yes |
| 9 | SIGKILL | Immediate termination by the kernel | **No — cannot be caught, blocked, or ignored** |
| 15 | SIGTERM | Polite termination request — **the default** for `kill` | Yes (graceful cleanup) |
| 18/19 | SIGCONT / SIGSTOP | Resume / freeze | SIGSTOP: no |

Escalation etiquette: `kill PID` (TERM, lets it clean up) → wait → `kill -9 PID` only if it won't die. A process stuck in `D` state ignores even SIGKILL until the I/O returns.

- `kill 1234` — by PID. `kill -HUP 1234` or `kill -1 1234` — same thing twice.
- `killall sleep` — by exact process *name*, all matches.
- `pkill -f 'http.server 8080'` — by pattern; `-f` matches the full command line (you used this in Week 3). `pgrep` is the look-don't-touch version.

### Priority — nice and renice

Niceness runs **-20 (highest priority) to +19 (lowest)**; default 0. Higher nice = "nicer" to others = less CPU.

```
nice -n 10 tar -czf big.tar.gz /data     # start lowered
renice -n 5 -p 1234                      # change a running process
```

**Only root can lower niceness** (raise priority) — a regular user can make a process nicer but never less nice, even back to where it started. That asymmetry is a tested detail. See it in `ps aux` as `N`/`<` or `ps -o ni`.

### Job Control

| Action | Command | Note |
|---|---|---|
| Background at launch | `cmd &` | Shell prints `[1] PID` |
| Suspend foreground job | `Ctrl+Z` | Sends SIGTSTP → state `T` |
| List jobs | `jobs` | `%1` refers to job 1 |
| Resume in background / foreground | `bg %1` / `fg %1` | — |
| Survive the terminal closing | `nohup cmd &` | Immune to the SIGHUP sent when the terminal dies; output → `nohup.out` |
| Replace the shell entirely | `exec cmd` | No new process — the shell *becomes* cmd. `exec bash` reloads your shell in place |

`Ctrl+C` = SIGINT (interrupt), `Ctrl+D` = EOF (not a signal — closes stdin, which is why it logs you out of a shell).

### Scheduling — cron, at, anacron, timers

**Crontab syntax — know cold:** `minute hour day-of-month month day-of-week command`

```
*/5 *  *  *  *   date >> /tmp/heartbeat.log      # every 5 minutes
0   2  *  *  0   /usr/local/bin/backup.sh        # 02:00 every Sunday
30  8  1  *  *   report.sh                       # 08:30 on the 1st of each month
```

Specials: `@reboot`, `@daily`, `@hourly`. Editing: `crontab -e` (edit), `-l` (list), **`-r` (removes your ENTIRE crontab, instantly, no confirmation — one keystroke from `-e`)**.

- User crontabs (`crontab -e`): five time fields + command. **`/etc/crontab` and `/etc/cron.d/` files have a sixth field: the username to run as.** Mixing these formats up breaks the job silently — tested.
- `at now + 5 minutes` — one-shot job (needs `atd` running). `atq` lists, `atrm N` cancels.
- `anacron` — for machines that aren't always on: runs daily/weekly/monthly jobs it *missed* while powered off. On a laptop like `tp-mudd`, `/etc/cron.daily` actually fires via anacron — plain cron would silently skip every job scheduled for an hour the lid was closed.
- **systemd timers** — the modern alternative: a `.timer` unit (with `OnCalendar=`) activates a matching `.service` unit. `systemctl list-timers` shows every scheduled job with next/last run — something `crontab -l` can't tell you. Timers get `Persistent=true` for anacron-like catch-up.

---

## Objective 2.4 — Software Management

### Two Layers, Two Families (Week 2's modprobe/insmod pattern again)

High-level tools resolve dependencies from repos; low-level tools operate on single package files and the local database:

| | RPM family (tp-mudd) | dpkg family (Ubuntu container) |
|---|---|---|
| High-level | `dnf` | `apt` |
| Low-level | `rpm` | `dpkg` |
| Package file | `.rpm` | `.deb` |
| Repo config | `/etc/yum.repos.d/*.repo` | `/etc/apt/sources.list`, `sources.list.d/` |

**dnf verbs:** `install`, `remove`, `search`, `info`, `check-update` (refresh + list available), `upgrade`, `autoremove`, `provides /usr/bin/htop` (which package owns a file I don't have). **`dnf history`** lists transactions; `dnf history info <ID>` shows one; **`dnf history undo <ID>` reverses it** — the rollback answer on the exam.

**rpm queries (installed database):** `rpm -qa` (all), `rpm -qi pkg` (info), `rpm -ql pkg` (files it installed), `rpm -qf /path` (which package owns this file), `rpm -V pkg` (verify — files changed since install, previews Week 7's integrity checking).

**apt verbs:** `apt update` (refresh index — changes nothing installed), `apt upgrade` (apply), `apt install/remove`, **`apt purge` (remove + delete config files — the remove/purge split is tested)**, `apt autoremove`. **dpkg queries:** `dpkg -l`, `dpkg -L pkg` (files), `dpkg -S /path` (owner) — same trio as rpm, different letters.

**GPG signing:** repos publish packages signed with their key; `gpgcheck=1` in a `.repo` file makes dnf verify every package against the imported key (`rpm -q gpg-pubkey`). On the apt side, keys live in `/etc/apt/keyrings/` (referenced per-repo via `signed-by=`). A "package cannot be verified" error means a missing/wrong key, not necessarily a malicious package — but that's the mechanism that would catch one.

Anatomy of a `.repo` file — every field is fair game:
```
[fedora]
name=Fedora $releasever
baseurl=https://...          (or metalink/mirrorlist)
enabled=1                    (dnf --enablerepo/--disablerepo override per-run)
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/...
```

### The Rest of 2.4

- **Language package managers:** `pip install` (Python — inside a venv, Week 8), `cargo install` (Rust), `npm install` (Node). Same idea as dnf, different ecosystems, no distro dependency resolution.
- **`update-alternatives`** — manages symlink chains for competing providers of one command (`/usr/bin/python` → which python). Fedora calls it `alternatives`; `alternatives --list` shows the table. Exam phrasing: "multiple versions installed, system default wrong" → alternatives.
- **Sandboxed apps:** `flatpak` (Fedora's default — you likely have some: `flatpak list`) and `snap` (Ubuntu's). Self-contained, sandboxed, distro-agnostic, updated independently of dnf/apt.
- **Basic service configs — know what each daemon is and its port:**

| Service | Daemon(s) | Port | On this fleet |
|---|---|---|---|
| DNS | bind/named, unbound | 53 | Pi-hole (conceptual anchor) |
| NTP | **chrony** (chronyd), ntpd | 123/udp | Live on tp-mudd right now: `chronyc tracking` |
| DHCP | dhcpd, dnsmasq | 67/68/udp | Your router; `nmcli` shows the lease |
| HTTP | Apache `httpd`, `nginx` | 80/443 | Week 3's python http.server was the toy version |
| SMTP | postfix, sendmail | 25 | — |
| IMAP4 | dovecot | 143/993 | — |

---

## Objective 2.5 — systemd

### Unit File Anatomy — Memorize This Skeleton

```ini
[Unit]
Description=Week 05 lab service
After=network.target          # ordering: start after (no dependency implied)
Requires=foo.service          # hard dependency: foo must start, failure cascades
Wants=bar.service             # soft dependency: try bar, don't care if it fails

[Service]
Type=simple                   # process IS the service (vs forking, oneshot)
ExecStart=/usr/bin/sleep infinity
Restart=on-failure
User=labuser                  # run as (Week 4's service-account concept)
Nice=10                       # 2.3's niceness, set declaratively

[Install]
WantedBy=multi-user.target    # what 'enable' hooks this unit into
```

`After` vs `Requires` is a classic question: `After` is *ordering only*; `Requires` is *dependency*. You usually want both.

**Unit types on the objective list:** `.service` (a daemon), `.timer` (activates a service on schedule), `.mount` (a filesystem — systemd actually converts your fstab into these at boot), `.target` (a named grouping — `multi-user.target` ≈ old runlevel 3, `graphical.target` ≈ 5).

### systemctl Verbs

| Verb | Effect | Trap |
|---|---|---|
| `start` / `stop` | Now, this boot only | — |
| `enable` / `disable` | Autostart at boot (creates/removes the WantedBy symlink) | **Doesn't start it now** — `enable --now` does both |
| `restart` / `reload` | Full restart vs re-read config (SIGHUP, no downtime) | `reload` only works if the unit defines ExecReload |
| `status` / `is-active` / `is-enabled` | Human view / script-friendly one-worders | — |
| `mask` | Symlinks the unit to **/dev/null** — cannot be started, even manually, even by another unit | `disable` prevents autostart; `mask` prevents *any* start. `unmask` reverses |
| `daemon-reload` | Re-read unit files from disk | **Required after every unit-file edit** — forgetting it means testing the old file |
| `edit` | Creates an override drop-in at `/etc/systemd/system/UNIT.d/override.conf` | `edit --full` copies the whole unit instead; `systemctl cat` shows unit + all drop-ins merged |
| `reset-failed` | Clears the "failed" state after you've fixed a unit | — |

Fully deactivate a service = `stop` + `disable` (both — a stopped-but-enabled unit returns at reboot; a disabled-but-running one keeps running).

**Where units live (precedence, low → high):** `/usr/lib/systemd/system` (package-installed — never edit) → `/etc/systemd/system` (yours) → drop-in `.d/` directories override individual settings. Same edit-the-right-file discipline as GRUB in Week 1.

### journalctl — the Query Flags

`-u sshd` (one unit) | `-b` (this boot; `-b -1` previous boot) | `-f` (follow) | `-p err` (priority err and worse) | `--since "1 hour ago"` / `--since 09:00 --until 09:30` | `-n 50` (last 50) | `_COMM=sudo` (by command) | `--disk-usage` | `-k` (kernel messages only, ≈ dmesg). Combine freely: `journalctl -u week05 -b -p warning`.

Journal persistence: if `/var/log/journal/` exists, logs survive reboots; otherwise they live in `/run` and vanish. Controlled by `Storage=` in `/etc/systemd/journald.conf` — a 5.x troubleshooting angle ("logs from before the crash are gone — why?").

### The One-Word Utilities

- `hostnamectl` — view/set hostname (persistent, no file editing)
- `timedatectl` — time, timezone, NTP sync status (`set-ntp true` hands timekeeping to chrony)
- `resolvectl status` — per-interface DNS truth (Week 3)
- `systemd-analyze` / `blame` / `critical-chain` — boot timing (Week 1)
- `sysctl` — kernel parameters live: `sysctl vm.swappiness` reads, `sysctl -w vm.swappiness=10` sets **until reboot** (it's writing Week 1's `/proc/sys/`). Persistent = a file in `/etc/sysctl.d/`. Runtime-vs-permanent, the third time this pattern appears (nmcli, firewall-cmd, now sysctl).

---

## Quick Recall

Zombie (`Z`) — already dead; kill the PARENT or let it be reaped; `kill -9` does nothing
`D` state — uninterruptible I/O sleep; a cluster of them = storage problem
SIGTERM 15 default and catchable; SIGKILL 9 uncatchable; SIGHUP 1 = reload for daemons
`pkill -f pattern` — kill by full command line; `killall name` — by exact name
nice range — -20 (highest prio) to +19; only root can lower niceness
`nohup cmd &` — survives terminal close (immune to SIGHUP)
`crontab -r` — deletes your whole crontab, no confirmation
`/etc/crontab` has a sixth field (user); user crontabs don't
anacron — catches up jobs missed while powered off; what laptops need
`systemctl list-timers` — every timer with next/last run times
`dnf history undo <ID>` — roll back a package transaction
`apt purge` — remove package AND its config files; `remove` keeps them
`rpm -qf /path` / `dpkg -S /path` — which package owns this file
`enable` ≠ `start` — boot symlink vs running now; `enable --now` = both
`mask` — symlink to /dev/null; cannot start until unmasked
`daemon-reload` — mandatory after editing any unit file
`sysctl -w` — runtime only; persistent lives in /etc/sysctl.d/
