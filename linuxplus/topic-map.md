# topic-map.md — XK0-006 Linux+ 11-Week Sprint
# Exam: CompTIA Linux+ XK0-006 V8 | Exam Week: September 14, 2026
# Two sessions per week. Both blocks scheduled every Sunday. No exceptions.
# Session A = concept review + cheatsheet (45 min)
# Session B = hands-on lab on homelab hardware (45–60 min)

---

## Progress Tracker

| Week | Domain | Objectives | Calendar | A Done | B Done | Test-Out |
|------|--------|-----------|----------|:------:|:------:|:--------:|
| 1  | D1 | 1.1, 1.5 — Fundamentals + Shell | Jun 29–Jul 5 | ☐ | ☐ | ☐ |
| 2  | D1 | 1.2, 1.3 — Hardware + Storage | Jul 6–12 | ☐ | ☐ | ☐ |
| 3  | D1 | 1.4, 1.6, 1.7 — Networking + Backup + Virt | Jul 13–19 | ☐ | ☐ | ☐ |
| 4  | D2 | 2.1, 2.2 — Files + Account Management | Jul 20–26 | ☐ | ☐ | ☐ |
| 5  | D2 | 2.3, 2.4, 2.5 — Processes + Software + Systemd | Jul 27–Aug 2 | ☐ | ☐ | ☐ |
| 6  | D2/D3 | 2.6, 3.2, 3.3 — Containers + Firewalls + OS Hardening | Aug 3–9 | ☐ | ☐ | ☐ |
| 7  | D3 | 3.1, 3.4, 3.5, 3.6 — Auth + Accounts + Crypto + Compliance | Aug 10–16 | ☐ | ☐ | ☐ |
| 8  | D4 | 4.2, 4.3 — Bash Scripting + Python | Aug 17–23 | ☐ | ☐ | ☐ |
| 9  | D4 | 4.1, 4.4, 4.5 — Automation + Git + AI | Aug 24–30 | ☐ | ☐ | ☐ |
| 10 | D5 | 5.1–5.5 — Full Troubleshooting Sprint | Aug 31–Sep 6 | ☐ | ☐ | ☐ |
| 11 | All | Practice Exam + Gap Analysis | Sep 7–13 | ☐ | ☐ | — |

---

## Week 1 — Linux Fundamentals + Shell Operations
**Calendar:** Jun 29–Jul 5
**Objectives:** 1.1, 1.5
**Domain weight covered:** ~7% of exam
**Reading (HLW):** Ch. 1 *(The Big Picture)*, Ch. 2 *(Basic Commands + FHS)*, Ch. 5 *(How the Kernel Boots)*, Ch. 6 *(How User Space Starts)* — Ch. 5 and 6 before Session A; they turn the boot stage list into a causal chain. Ch. 1 grounds the kernel/user space split every other topic builds on.

**Session A — Concepts (45 min)**
- Boot process: BIOS/UEFI → bootloader (GRUB) → kernel → initrd → init (systemd). Know each stage and what can fail.
- FHS: know the purpose of every top-level directory. `/proc` is not real files. `/dev` is device files. `/etc` is config. `/var` is variable data (logs, spool).
- Distributions: RPM-based (Fedora, RHEL, Rocky) vs. dpkg-based (Debian, Ubuntu). Know which package manager maps to which.
- Shell environment: PATH resolution, how `.bashrc` vs `.bash_profile` vs `.profile` differ and when each loads.
- Redirection: `>` overwrites, `>>` appends. `2>` redirects stderr. `2>&1` merges stderr to stdout. `|` pipes stdout to next command.

**Session B — Lab (45–60 min)**
- On `tp-mudd`: trace the full boot sequence — `systemd-analyze blame`, `journalctl -b`, identify what loaded and how long it took.
- Practice all redirection forms. Write a script that captures stdout and stderr to separate files.
- Use `find` with multiple flags: `-type`, `-name`, `-mtime`, `-perm`, `-exec`. Find all SUID files on the system.
- Verify FHS understanding: `ls -la /` and explain every directory out loud before looking it up.

**Exam gotchas:**
- `/proc` is a virtual filesystem — changes to it don't persist across reboots.
- `.bashrc` loads for interactive non-login shells; `.bash_profile` for login shells. SSH sessions are login shells.
- `SIGTERM` allows graceful shutdown; `SIGKILL` cannot be caught or ignored.

---

## Week 2 — Hardware Management + Storage
**Calendar:** Jul 6–12
**Objectives:** 1.2, 1.3
**Domain weight covered:** ~7% of exam
**Reading (HLW):** Ch. 3 *(Devices)*, Ch. 4 *(Disks and Filesystems)* — Ch. 3 explains kernel modules, udev, and device files from the inside; Ch. 4 covers the full storage stack: partitioning, filesystem types, LVM, and fstab.

**Session A — Concepts (45 min)**
- Kernel modules: `lsmod` lists loaded modules. `modprobe` loads with dependencies. `rmmod` removes. `modinfo` shows module details. `insmod` loads without dependency resolution (lower level).
- LVM stack: physical volume → volume group → logical volume. Know the create/display/remove commands for each layer.
- Filesystem types: ext4 (journaling, widely supported), xfs (high performance, default on RHEL/Fedora), btrfs (copy-on-write, snapshots). Know when to use each.
- `/etc/fstab` fields: device, mountpoint, fstype, options, dump, pass. Know what `nofail` does and why it matters.
- RAID levels conceptually: 0 (stripe), 1 (mirror), 5 (stripe+parity), 10 (stripe of mirrors).

**Session B — Lab (45–60 min)**
- On `tp-mudd`: run `lsmod`, `lspci`, `lsblk`, `lscpu`, `lsmem`. Document what you find.
- On `dell-ubuntu`: inspect current LVM setup — `pvdisplay`, `vgdisplay`, `lvdisplay`. Map the full storage layout.
- Practice mount/umount with a loop device or USB drive. Add a test entry to `/etc/fstab`, verify with `mount -a`, then remove it cleanly.
- Run `df -h` and `du -sh /var/log/*` to understand space usage.

**Exam gotchas:**
- `lvcreate -L 10G` uses absolute size; `lvcreate -l 100%FREE` uses remaining space.
- After resizing a logical volume with `lvextend`, you still need to resize the filesystem with `resize2fs` (ext4) or `xfs_growfs` (xfs).
- `xfs` filesystems cannot be shrunk — only grown.

---

## Week 3 — Networking + Backup + Virtualization
**Calendar:** Jul 13–19
**Objectives:** 1.4, 1.6, 1.7
**Domain weight covered:** ~9% of exam
**Reading (HLW):** Ch. 9 *(Understanding Your Network)*, Ch. 12 *(Moving Files Across the Network)* — Ch. 9 explains how the kernel handles networking, the `ip` command, and routing; Ch. 12 covers rsync and scp in depth. KVM/virtualization is not covered in the book.

**Session A — Concepts (45 min)**
- `ip addr` vs. `ifconfig` (deprecated). `ip route` shows routing table. `ss -tulpn` shows listening ports with process names.
- NetworkManager: `nmcli connection show`, `nmcli device status`. Netplan is Ubuntu-specific.
- `tar` flags: `-c` create, `-x` extract, `-v` verbose, `-z` gzip, `-j` bzip2, `-J` xz, `-f` filename. Know: `tar -czvf archive.tar.gz /path`.
- `rsync` flags: `-a` archive (preserves permissions), `-v` verbose, `-z` compress, `--delete` mirror. `rsync -avz src/ dest/`.
- KVM/QEMU: KVM is the kernel module, QEMU is the emulator. `libvirt` is the API layer. `virsh` is the CLI.

**Session B — Lab (45–60 min)**
- On `tp-mudd`: document the full network topology using only CLI tools — `ip addr`, `ip route`, `ss -tulpn`, `nmap` scan of Tailscale subnet.
- Practice `tar`: create an archive of `/etc`, verify contents with `tar -tvf`, extract to `/tmp`.
- Practice `rsync`: sync a directory between `tp-mudd` and `dell-ubuntu` over Tailscale. Verify with `diff`.
- On `dell-ubuntu`: inspect the running KVM VM with `virsh list --all`, `virsh dominfo dell-fedora`.

**Exam gotchas:**
- `rsync` trailing slash matters: `rsync src/ dest/` copies contents of src; `rsync src dest/` copies src directory itself.
- `dd` reads and writes in blocks. `bs=4M` sets block size. If `dd` hangs, `Ctrl+T` (or send `SIGUSR1`) shows progress.
- Nested virtualization requires `kvm_intel` or `kvm_amd` module with `nested=1`.

---

## Week 4 — File Management + Account Management
**Calendar:** Jul 20–26
**Objectives:** 2.1, 2.2
**Domain weight covered:** ~7% of exam
**Reading (HLW):** Ch. 4 *(inode + link mechanics)*, Ch. 7 *(System Configuration — users section)*, Ch. 13 *(User Environments)* — Ch. 4's inode section explains hard links vs. symlinks at the filesystem level, not just the behavior; Ch. 7 covers `/etc/passwd`, `/etc/shadow`, and password aging.

**Session A — Concepts (45 min)**
- Hard links vs. symbolic links: hard links share the same inode (same filesystem only, no directories). Symlinks are pointers (cross-filesystem, can point to directories, break if target moves).
- `/etc/passwd` fields: username:x:UID:GID:comment:home:shell. The `x` means password is in `/etc/shadow`.
- `/etc/shadow` fields: username:hashed_pw:last_changed:min:max:warn:inactive:expire. Know what each aging field controls.
- `chage -l username` — inspect password aging. `chage -M 90` sets max password age.
- UID ranges: 0 = root, 1–999 = system/service accounts, 1000+ = regular users. UIDs are what the kernel cares about — not usernames.

**Session B — Lab (45–60 min)**
- Create a structured test environment: new user, new group, home directory with skeleton files. Verify `/etc/passwd` and `/etc/shadow` entries by hand.
- Set password aging on the test user: max age 90 days, 7-day warning. Verify with `chage -l`.
- Create hard link and symbolic link to the same file. Delete the original. Observe what happens to each link.
- Use `find` to locate all files owned by a specific user. Use `stat` to inspect inode information.

**Exam gotchas:**
- `useradd` does NOT create a home directory by default on all distros — use `-m` flag to ensure it.
- `userdel` vs `userdel -r`: `-r` removes the home directory and mail spool.
- A locked account (`passwd -l`) still allows SSH key-based login unless the shell is also set to `/sbin/nologin`.

---

## Week 5 — Processes + Software + Systemd
**Calendar:** Jul 27–Aug 2
**Objectives:** 2.3, 2.4, 2.5
**Domain weight covered:** ~9% of exam
**Reading (HLW):** Ch. 6 *(How User Space Starts — systemd)*, Ch. 7 *(Cron, logging)*, Ch. 8 *(Processes and Utilities)* — Ch. 8 covers process states and signals with the mechanism behind them; Ch. 6's systemd section directly supports unit file anatomy and target dependencies.

**Session A — Concepts (45 min)**
- Process states: running (on CPU), sleeping (waiting for event), blocked (waiting for I/O), stopped (SIGSTOP), zombie (finished but parent hasn't called wait()).
- Crontab syntax: `minute hour day-of-month month day-of-week command`. `*` = every. `*/5` = every 5. `0 2 * * 0` = 2am every Sunday.
- `apt` workflow: `update` (refresh index), `upgrade` (apply updates), `install`, `remove`, `purge` (includes config), `autoremove`. GPG keys authenticate repos.
- Systemd unit file anatomy: `[Unit]` (Description, After, Requires), `[Service]` (ExecStart, Restart, User), `[Install]` (WantedBy). `daemon-reload` required after editing unit files.
- `journalctl` flags: `-u servicename`, `-b` (current boot), `-f` (follow), `--since`, `--until`, `-p err` (priority).

**Session B — Lab (45–60 min)**
- Inspect all running processes: `ps aux`, `top`, `htop`. Find the PID of `gitea` or `n8n`. Send SIGHUP and observe behavior.
- Write a crontab entry that logs the date to a file every 5 minutes. Verify it runs. Remove it.
- On `dell-ubuntu`: run full `apt` workflow — update index, list upgradable packages, install `htop` if not present, verify, remove cleanly.
- Inspect the Gitea service unit file with `systemctl cat gitea`. Modify a `[Service]` parameter in an override, `daemon-reload`, verify change with `systemctl status`.

**Exam gotchas:**
- `systemctl stop` is temporary. `systemctl disable` prevents autostart on boot. Both together are needed to fully deactivate a service.
- `mask` creates a symlink to `/dev/null` — the service cannot be started even manually until unmasked.
- `dnf history` lets you undo package transactions — useful for rollbacks.

---

## Week 6 — Containers + Firewalls + OS Hardening
**Calendar:** Aug 3–9
**Objectives:** 2.6, 3.2, 3.3
**Domain weight covered:** ~11% of exam
**Reading (HLW):** Ch. 9 *(Network Configuration)* — limited book coverage this week. Containers and SELinux are not covered. Ch. 9 gives the TCP/IP and routing foundation that iptables chain flow sits on top of.

**Session A — Concepts (45 min)**
- Container runtime stack: runC (low level) → containerd (runtime) → Docker/Podman (CLI/API). Podman is daemonless and rootless.
- Dockerfile core directives: `FROM` (base image), `RUN` (build-time command), `COPY`/`ADD` (files), `ENTRYPOINT` (fixed command), `CMD` (default args), `USER` (run as this user), `EXPOSE`, `ENV`.
- firewalld zones: drop, block, public, external, home, internal, work, dmz, trusted. Default is `public`. Zones are applied per-interface.
- iptables chain flow: packet arrives → PREROUTING → INPUT (if local) or FORWARD (if routing). Output: OUTPUT → POSTROUTING. Default policy applies if no rule matches.
- SELinux contexts: `user:role:type:level`. The `type` field is what most policies enforce. `ls -Z` shows context. `restorecon` resets to policy default.

**Session B — Lab (45–60 min)**
- On `dell-fedora`: inspect the n8n Docker container — `docker ps`, `docker inspect`, `docker logs`. Pull a new image, run it detached, exec into it, stop and remove it.
- On `dell-ubuntu`: review all current UFW rules (`ufw status numbered`). Cross-reference against `firewall/ubuntu-server.md` in the homelab repo. Add a test rule, verify, then delete it.
- On `tp-mudd`: run `ausearch -m AVC -ts today` to review SELinux denials. Run `getenforce`. Check context on `/etc/ssh/sshd_config` with `ls -Z`.
- Practice `sudo` audit: `grep sudo /var/log/auth.log` or `journalctl _COMM=sudo`. Confirm all sudo activity is logged.

**Exam gotchas:**
- Podman is rootless by default — container volumes and network behavior differ from Docker when run as non-root.
- `firewall-cmd` changes are runtime only unless you add `--permanent`. Runtime changes survive until next `firewalld` restart.
- SELinux `chcon` changes don't survive `restorecon` — use `semanage fcontext` to make permanent label changes.

---

## Week 7 — Auth/Accounting + Account Hardening + Crypto + Compliance
**Calendar:** Aug 10–16
**Objectives:** 3.1, 3.4, 3.5, 3.6
**Domain weight covered:** ~7% of exam (conceptual-heavy week)
**Reading (HLW):** Ch. 7 *(System Configuration — user accounts, PAM overview)* — limited coverage this week. Crypto, LUKS, and auditd are not covered in depth. Use the book for PAM conceptual grounding only; the exam objectives go well beyond what the book covers here.

**Session A — Concepts (45 min)**
- PAM stack: authentication, account, session, password modules. `/etc/pam.d/` contains per-service configs. Stacking order matters: `required`, `requisite`, `sufficient`, `optional`.
- `auditd`: `audit.rules` defines what to watch. `auditctl -l` lists active rules. `ausearch` queries logs. `aureport` generates summaries.
- LUKS2: `cryptsetup luksFormat` to encrypt, `luksOpen` to mount, `luksClose` to unmount. Passphrase or keyfile. Header stores key slots.
- GPG: `gpg --gen-key`, `gpg --encrypt`, `gpg --decrypt`, `gpg --sign`, `gpg --verify`. Understand public/private key roles.
- OpenSCAP: `oscap xccdf eval` runs a scan against a benchmark. CIS Benchmarks define hardening standards. AIDE builds a database of file hashes and detects changes.

**Session B — Lab (45–60 min)**
- Generate a GPG keypair. Encrypt a test file to yourself. Decrypt it. Sign a file and verify the signature.
- On `tp-mudd`: run `auditctl -l` to see active audit rules. Add a rule watching `/etc/passwd` for writes. Modify `/etc/passwd` (via `chage`, not directly). Check `ausearch -f /etc/passwd`.
- On `dell-fedora` (SELinux enforcing): deliberately trigger an AVC denial. Use `audit2allow` to generate a policy module. Do not apply it — just read the output.
- Review password aging policy on all devices. Verify `/etc/login.defs` settings for PASS_MAX_DAYS, PASS_MIN_DAYS, PASS_WARN_AGE.

**Exam gotchas:**
- LDAP and Kerberos are commonly tested conceptually, not operationally — know what each does and when each is used.
- `fail2ban` reads log files and issues `iptables`/`firewalld` bans — it's not a firewall itself.
- SHA-256 is a hash (one-way). HMAC is a hash with a secret key (authentication). TLS uses both — asymmetric to exchange symmetric key, then symmetric + HMAC for data integrity.

---

## Week 8 — Bash Scripting + Python Basics
**Calendar:** Aug 17–23
**Objectives:** 4.2, 4.3
**Domain weight covered:** ~10% of exam (performance-based questions likely here)
**Reading (HLW):** Ch. 11 *(Introduction to Shell Scripting)*, Ch. 13 *(User Environments)* — Ch. 11 covers scripting mechanics that Session B builds on directly: variables, conditionals, loops, and functions. Read it before Session B, not Session A.

**Session A — Concepts (45 min)**
- Script structure: shebang (`#!/bin/bash`), `set -e` (exit on error), `set -x` (debug trace), `trap` (cleanup on exit).
- Functions: `myfunc() { local var="val"; echo "$var"; }`. `local` scopes variables to the function.
- IFS: Internal Field Separator — default is space/tab/newline. Change it to parse CSV: `IFS=,`.
- Regex in bash: `[[ "$str" =~ ^[0-9]+$ ]]` — the regex goes on the right, unquoted.
- Python venv: `python3 -m venv .venv`, `source .venv/bin/activate`, `pip install <pkg>`, `deactivate`.
- Python data types: know `list` (ordered, mutable), `dict` (key-value, mutable), `tuple` (ordered, immutable), `set` (unordered, unique).

**Session B — Lab (45–60 min)**
- Write a service-health-check script from scratch: takes a service name as argument, validates argument is provided, checks status with `systemctl is-active`, returns exit code 0 for active, 1 for inactive, 2 for missing argument. Must handle all three cases cleanly.
- Extend it: add a function, a loop over multiple services from an array, output to a logfile with timestamp.
- Set up a Python venv on `tp-mudd`. Write a Python script that reads `/proc/loadavg`, parses the 1-minute load, and prints a warning if over a threshold. Run it.

**Exam gotchas:**
- `$()` and backticks do the same thing (command substitution) but `$()` nests cleanly. Use `$()`.
- `[ ]` is `test`. `[[ ]]` is a bash builtin with more features (regex, `&&`, `||` without escaping). Prefer `[[ ]]` in scripts.
- Python indentation is not style — it is syntax. A wrong indent is a `IndentationError`.

---

## Week 9 — Automation Tools + Git + AI
**Calendar:** Aug 24–30
**Objectives:** 4.1, 4.4, 4.5
**Domain weight covered:** ~7% of exam
**Reading (HLW):** Ch. 9 *(Network Configuration)* — minimal book coverage this week. Ansible, Puppet, Kubernetes, and Git internals are not covered. Ch. 9 is background only — it explains the SSH transport Ansible relies on.

**Session A — Concepts (45 min)**
- Ansible: agentless (uses SSH), YAML playbooks, inventory defines hosts/groups, modules do the work (`apt`, `copy`, `service`, `command`, `shell`), facts are auto-collected host info.
- Puppet: agent-based (pull model), Ruby DSL, agent polls master every 30 min by default, catalog describes desired state.
- Kubernetes: cluster → node → pod → container. `ConfigMap` stores config data. `Service` exposes pods. `Deployment` manages replica sets.
- Git internals: working directory → staging area (index) → local repo → remote. `git add` moves to staging. `git commit` moves to local repo.
- Git merge vs. rebase: merge preserves history with a merge commit. Rebase rewrites history to appear linear. `squash` combines multiple commits into one.

**Session B — Lab (45–60 min)**
- In the homelab repo: create a practice branch, make changes across two commits, squash them into one with `git rebase -i HEAD~2`, push the branch.
- Practice `git stash`: make a change, stash it, switch branches, pop the stash.
- Write a minimal Ansible ad-hoc command: ping all Tailscale-accessible hosts. If Ansible isn't installed, install it. Document the inventory file format.
- Review the homelab repo commit history with `git log --oneline --graph`. Practice `git diff HEAD~3 HEAD`.

**Exam gotchas:**
- Ansible playbooks are idempotent — running them twice should not change state the second time if state is already correct.
- `git reset --soft HEAD~1` undoes the commit but keeps changes staged. `--mixed` unstages but keeps changes. `--hard` destroys changes.
- 4.5 AI questions are lightweight — know the vocabulary (prompt engineering, hallucination risk, data governance, verify output).

---

## Week 10 — Full Troubleshooting Sprint
**Calendar:** Aug 31–Sep 6
**Objectives:** 5.1–5.5
**Domain weight covered:** 22% of exam — this week is high value
**Reading (HLW):** No new chapters — use the book as a reference map. When a fault-injection symptom doesn't make sense, trace it back: storage issues → Ch. 4, kernel/device issues → Ch. 3, process behavior → Ch. 8, network → Ch. 9. The book is the mechanism layer under the troubleshooting methodology.

**Session A — Concepts (45 min)**
- Troubleshooting methodology: identify problem → establish theory → test theory → establish plan → implement solution → verify → document. Know this cold.
- SLA vs SLI vs SLO: SLA is the contract (penalty for breach), SLO is the internal target (99.9% uptime), SLI is the actual measurement (requests succeeding). SLOs are stricter than SLAs.
- SNMP: agent runs on monitored host, manager collects data. Traps are async notifications (device pushes to manager). MIBs define what OIDs mean.
- Performance symptoms: swapping = RAM exhausted, system using disk. High I/O wait = CPU idle, waiting on disk. High load without high CPU = I/O or memory bottleneck.
- Network troubleshooting progression: physical → link → IP → routing → firewall → DNS → application.

**Session B — Lab (45–60 min)**
- Deliberate fault injection: on `tp-mudd`, temporarily misconfigure something known — break a systemd unit (wrong ExecStart path), break DNS resolution (corrupt `/etc/resolv.conf`), fill a filesystem (sparse file with `dd`). Diagnose and fix each using only proper tools (no guessing).
- Run `sar` or `vmstat 1 10` and interpret output. Identify swapping, I/O wait, CPU steal.
- Pull up the past incidents from `homelab/incidents/` — `Dns-failure.md` and `tailscale-acl-outage.md`. Walk through each with the 5.3 and 5.4 objective in mind. What commands would the exam expect you to use?
- Practice reading `journalctl -b -p err` output and identifying actionable items.

**Exam gotchas:**
- Performance-based questions will ask you to identify the cause from symptoms, not fix it. Know the symptom → cause mappings.
- Zombie processes cannot be killed — you kill the parent. A zombie is already dead; it's just waiting for its parent to call `wait()`.
- `dmesg -T` shows kernel ring buffer with human-readable timestamps. Always check here for hardware issues.

---

## Week 11 — Practice Exam + Gap Analysis
**Calendar:** Sep 7–13
**Exam week:** Sep 14
**Reading (HLW):** None this week — review mode only. If a gap topic traces back to a mechanism you don't fully own, pull the relevant chapter then. Don't read ahead of the gap analysis.

**Session A — Practice Exam (90 min)**
- Take one full-length practice exam under real conditions: 90 questions, 90 minutes, no pauses, no looking things up.
- Use Dion Training (Udemy) or CompTIA CertMaster Practice.
- Score it. Write down every topic where you missed more than 1 question.

**Session B — Gap Drilling (45–60 min)**
- For each weak topic from Session A: open `curriculum.md` to the relevant objective. Spend no more than 10 minutes per topic.
- Ask Claude: "Quiz me on [objective X.X]" — 5 questions, timed. Repeat until you hit 80%+ on that objective.
- Do not re-read everything. Targeted drilling only.

**Pass threshold before scheduling the real exam:** 80%+ on the practice exam.
**If below 80%:** identify the lowest two domains, spend the remaining days on those only.

---

## Archive Note

Previous content generated for the XK0-005 curriculum (weeks 1–4) is preserved in `archive/`. File permissions (→ 3.3), user management (→ 2.2), SSH hardening (→ 3.3), and sudo config (→ 3.3) content remains applicable to XK0-006 objectives. Reference it for Session A review during weeks 4 and 6.
