# Week 05 — Reference Notes
# Objectives: 2.3, 2.4, 2.5 | Calendar: Jul 27–Aug 2

---

## Exam Objective Mapping

**2.3 — Given a scenario, manage processes and jobs in a Linux environment**
- Monitoring: `ps`, `top`, `htop`, `atop`, `pstree`, `lsof`, `strace`, `pidstat`, `mpstat`, `/proc/<PID>`
- Process states: running, sleeping, blocked, stopped, zombie
- Signals: `kill`, `killall`, `pkill`; SIGTERM (15), SIGKILL (9), SIGHUP (1)
- Priority: `nice`, `renice`; process limits
- Job control: `&`, `bg`, `fg`, `jobs`, `nohup`, `Ctrl+Z`, `Ctrl+C`, `Ctrl+D`, `exec`
- Scheduling: `crontab`, `at`, `anacron`

**2.4 — Given a scenario, configure and manage software in a Linux environment**
- Package managers: `apt`, `dnf`, `rpm`, `dpkg`; language managers `pip`, `cargo`, `npm`
- Repos: `/etc/apt/sources.list`, `/etc/yum.repos.d/`, third-party repos, GPG signatures
- `update-alternatives`; sandboxed apps (snap, flatpak)
- Basic service configs: DNS, NTP/PTP, DHCP, HTTP (Apache httpd, Nginx), SMTP, IMAP4

**2.5 — Given a scenario, manage Linux using systemd**
- Unit types: service, timer, mount, target
- `systemctl`: start, stop, restart, reload, enable, disable, mask, unmask, status, daemon-reload, edit
- Utilities: `systemd-analyze`, `journalctl`, `hostnamectl`, `timedatectl`, `resolvectl`, `sysctl`

---

## Key Man Pages

`man 5 crontab` — the file-format page (section 5, not 1). Covers the five fields, step values (`*/5`), ranges, and the `@reboot`-style specials. The EXTENSIONS section notes exactly the quirks exams like.

`man systemd.service` — read the `Type=` list (simple/forking/oneshot) and the `ExecStart=` rules. Status code `203/EXEC` from lab Task 7f is documented here — seeing where the answer lives beats memorizing it.

`man systemd.unit` — the `[Unit]` section reference: `After=` vs `Requires=` vs `Wants=` in precise language. Also documents the unit search path and drop-in `.d/` precedence you used in Task 7d.

`man 7 signal` — the signal table with default actions, plus the sentence that settles it: SIGKILL and SIGSTOP cannot be caught, blocked, or ignored.

`man journalctl` — skim MATCHES AND FILTERING: `-u`, `-b`, `-p`, `--since`, and field matches like `_COMM=`. These compose; the exam shows composed queries.

---

## Video Timestamps

**Theory Course (12hr — nGPK6YBbKpg):**
Three sections this week — "Process Management" (2.3), "Software Management" (2.4), and "systemd" (2.5), typically consecutive in the Domain 2 block after user management. If time is short, prioritize systemd: it's the densest new material and feeds directly into Week 10's unit-failure troubleshooting.

**Labs Course (7hr — JXIaR23OdB8):**
Look for the systemd unit-file walkthrough — it builds a custom service like lab Task 7. Watch it *before* Session B if unit files are brand new; *after* if Task 7 goes smoothly. The package-management segment demos apt on screen — your Task 5 is the dnf mirror of it, and Task 6's container is their exact environment.

---

## Book Reference — How Linux Works, 3rd Ed. (Ward)

**Ch. 8 — Processes and Resource Utilization**
The mechanism layer under Task 1–2: what a process actually is, how fork/exec produce the tree `pstree` shows, and what the kernel does with a signal. Its explanation of why a zombie exists (the parent owns the exit status until it collects it) turns the "kill the parent" rule into an obvious consequence. Read before Session B.

**Ch. 6 — How User Space Starts (systemd section)**
Assigned back in Week 1 for boot; reread the systemd half now that you're writing units instead of just watching them boot. Targets, dependency graphs, and unit activation get full treatment — `After=` vs `Requires=` is explained with the reasoning the man page compresses away. Read before Session A.

**Ch. 7 — System Configuration (cron and logging sections)**
Short sections on cron/at and on how syslog/journald fit together. The logging part explains what journald actually stores and why persistence is a directory-existence question (`/var/log/journal`) — which is the audit script's final check.

---

## Things That Trip People Up

**1. `systemctl stop` + `systemctl disable` are BOTH required to kill a service**
Stop ends it now; disable removes the boot symlink. One without the other means it's either back at reboot or still running right now. `enable --now` / `disable --now` do both sides in one command.

**2. mask ≠ disable**
Disable removes autostart; the unit can still be started manually or get pulled in as a dependency of another unit. Mask symlinks the unit name to `/dev/null` — *nothing* can start it. Exam scenario: "service keeps getting started by a dependency" → mask.

**3. `daemon-reload` after every unit-file edit — no exceptions**
systemd caches unit files. Edit + restart without daemon-reload runs the OLD definition, and the failure looks impossible ("I fixed the file, it still fails with the old error"). Lab Task 7f/7g had you feel this pipeline in the right order.

**4. Zombies can't be killed because they're already dead**
`kill -9` on a `Z` process does nothing (Task 1d proved it). The zombie is an exit-status receipt waiting for the parent's `wait()`. Fix the parent, or let it die so systemd reaps the child. A *few* transient zombies are normal; a growing count means a buggy parent.

**5. `apt remove` vs `apt purge` — config files are the difference**
`remove` uninstalls binaries but leaves config in `/etc`; `purge` deletes both. A scenario about "reinstalled the package but the broken config persisted" is pointing at remove-instead-of-purge. dnf has no purge verb — RPM packages mark configs and leave modified ones as `.rpmsave` — a distro-family difference worth one flashcard.

**6. User crontabs and `/etc/crontab` have different field counts**
User crontab: 5 time fields + command. `/etc/crontab` and `/etc/cron.d/*`: 5 time fields + **username** + command. Pasting a system-crontab line into `crontab -e` makes cron try to execute the username as the command — silently broken. Also: `crontab -r` wipes your whole crontab with no prompt, one key away from `-e`.

---

## Connect to the Homelab

This laptop already runs the whole week's material in production miniature. `tailscaled` and `sshd` are the reference units — `systemctl cat` on either shows real-world `[Unit]`/`[Service]`/`[Install]` sections written by upstream maintainers, worth comparing against your toy week05.service. Your NTP stack is objective 2.4's service table live: `chronyd` is running right now (`chronyc tracking` shows your sync state), and `timedatectl` reports it — that's two objectives meeting in one command. The package layer is the machine's daily reality: every `dnf upgrade` you've run is logged in `dnf history` going back months — read it once as an incident-response habit, since "what changed recently" is the first question after any breakage (and Week 10 will ask it). The scheduling section closes a known gap: Week 3's notes flagged that nothing in the homelab does scheduled backups yet, and Task 8's user-level timer is the exact mechanism to fix that — point the timer's service at an `rsync -a --delete ~/homelab/ <backup-dir>/` line and this week's lab graduates into permanent infrastructure on the machine you study on.
