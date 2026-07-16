# Week 11 — The Last-Mile Sheet
# Domain: ALL | Practice Exam + Gap Analysis | Calendar: Sep 7–13 | Exam: Sep 14
# This is not new material — it is the sprint's highest-yield recall, one line
# each, grouped by domain. Read it twice: BEFORE the practice exam (Session A)
# and again the morning of September 14. If a line doesn't instantly expand
# into the full concept in your head, that line is a gap — mark it, drill it.

---

## Domain 1 — System Management (23%, ~21 questions)

- Boot chain: BIOS/UEFI → GRUB → kernel → initrd → systemd. Failure question = which stage owns the symptom.
- Edit `/etc/default/grub`, then regenerate — never edit grub.cfg directly (`grub2-mkconfig -o /boot/grub2/grub.cfg`).
- `/proc` is virtual — echoes into it don't survive reboot; persistence lives in `/etc/sysctl.d/`.
- `.bash_profile` = login shells (SSH); `.bashrc` = interactive non-login. SSH sessions are login shells.
- `2>&1 >/dev/null` ≠ `>/dev/null 2>&1` — redirections apply left to right; order is the question.
- `modprobe` resolves dependencies; `insmod` does not. `modinfo` describes, `rmmod` removes.
- LVM ladder: `pvcreate` → `vgcreate` → `lvcreate`; grow: `lvextend` THEN `resize2fs`/`xfs_growfs` — two steps, always.
- **xfs grows only — it cannot shrink.** ext4 can do both (offline for shrink).
- `lvcreate -L 10G` = absolute size; `-l 100%FREE` = extents/percentage.
- fstab fields: device, mountpoint, fstype, options, dump, pass. `nofail` = boot proceeds if device is absent.
- "No space left" + `df -h` shows space → `df -i` — inode exhaustion.
- RAID: 0 stripe (fast, fragile), 1 mirror, 5 stripe+parity (n−1 usable), 10 stripe-of-mirrors. `mdadm`, `/proc/mdstat`.
- `ip addr` / `ip route` / `ss -tulpn` — the modern trio; ifconfig/netstat are the deprecated decoys.
- Netplan is Ubuntu (`netplan try` = auto-rollback safety); NetworkManager/`nmcli` is Fedora/RHEL.
- Resolution order comes from `/etc/nsswitch.conf` `hosts:` line — files vs dns order is testable.
- `tar -czvf` create gz / `-xzvf` extract / `-tzvf` list. `-j` bzip2, `-J` xz.
- **rsync trailing slash: `src/` copies contents; `src` copies the directory itself.** `-a` preserves, `--delete` mirrors.
- `dd` progress: `status=progress` (or SIGUSR1). `ddrescue` for failing disks.
- KVM = kernel module, QEMU = emulator, libvirt = API, `virsh` = CLI. `virsh destroy` = power-off (NOT delete); `undefine` = delete config.
- VM networks: NAT (default, outbound only), bridged (peer on the LAN), host-only (isolated). VirtIO = paravirtualized drivers = fast.

## Domain 2 — Services and User Management (20%, ~18 questions)

- Hard link = same inode, same filesystem, survives target deletion. Symlink = pointer, crosses filesystems, dangles.
- `/etc/passwd` — user:x:UID:GID:comment:home:shell; the `x` says "hash is in shadow."
- `/etc/shadow` aging fields: last-changed:min:max:warn:inactive:expire — `chage -l` reads them aloud.
- UID 0 root, 1–999 system, 1000+ humans. The kernel only knows numbers.
- `useradd -m` or no home directory (distro-dependent); `userdel -r` removes home+mail.
- **`passwd -l` locks the password only — SSH keys still work. Full lock = also `usermod -s /sbin/nologin`.**
- `/etc/skel` seeds new home directories.
- Process states: R running, S sleeping, D uninterruptible I/O (unkillable, counts in load), T stopped, Z zombie.
- **Zombie = already dead; kill the PARENT.**
- SIGTERM 15 polite, SIGKILL 9 uncatchable, SIGHUP 1 reload-or-hangup. `kill` PID, `pkill`/`killall` by name.
- `nice -n 10 cmd` start lower; `renice` running; lower number = higher priority; only root goes negative.
- crontab: min hour dom month dow. `*/5` = every 5. `0 2 * * 0` = Sun 02:00. Day-of-month OR day-of-week (either matches).
- `at` = once; cron = recurring; anacron = catches up after downtime.
- apt: `update` refreshes index, `upgrade` applies, `purge` removes config too. dnf: `dnf history undo <n>` = transaction rollback.
- rpm `-qf /path` (owns file), `-ql pkg` (lists files); dpkg `-S` / `-L` are the twins.
- **Unit edits do nothing until `systemctl daemon-reload`.** `edit` makes an override drop-in; `edit --full` replaces.
- stop = now only; disable = no autostart; **mask = symlink to /dev/null, cannot start at all.**
- `journalctl -u unit -b -p err -f --since` — the five flags that answer every journal question.
- Podman = daemonless + rootless by default; Docker = daemon. runC → containerd → CLI is the stack.
- Dockerfile: ENTRYPOINT = fixed command, CMD = default (overridable) args; COPY plain, ADD also fetches/unpacks.
- `-p 8080:80` = host:container. Named volume vs bind mount; `:z`/`:Z` = SELinux relabel on volumes.

## Domain 3 — Security (18%, ~16 questions)

- PAM controls: required (fail-but-continue), requisite (fail-now), sufficient (pass-now), optional. Order matters.
- auth vs account vs session vs password module types — "expired password" is *account*, "wrong password" is *auth*.
- `auditctl -l` active rules; `-w /etc/passwd -p wa` watch; `ausearch -f file` / `-m AVC`; `aureport` summarizes.
- firewalld: **runtime unless `--permanent`; `--permanent` inert until `--reload`.** Zones bind to interfaces; default zone = public.
- iptables path: PREROUTING → INPUT (local) / FORWARD (routed) → OUTPUT → POSTROUTING. nftables replaces it; ufw/firewall-cmd are front-ends.
- Exit-node/router boxes need `net.ipv4.ip_forward=1` — the forgotten sysctl behind "forwarding doesn't work."
- SNAT/masquerade = source rewrite on egress; DNAT = destination rewrite on ingress (port forward).
- sudoers only via `visudo` (syntax check); NOPASSWD = no password prompt; wheel group = sudo membership on Fedora.
- Permissions: SUID 4xxx (runs as owner), SGID 2xxx (group; on dirs = inherit group), sticky 1xxx (dirs: only owner deletes — /tmp).
- umask subtracts: 022 → files 644, dirs 755. Find SUID: `find / -perm -4000`.
- `+` at the end of `ls -l` mode = ACLs present → `getfacl`. `setfacl -m u:user:rw file`.
- **`chcon` is temporary (dies at `restorecon`); `semanage fcontext` + `restorecon` is permanent.** Booleans: `getsebool`/`setsebool -P`.
- SELinux triage order: context (`ls -Z`, restorecon) → boolean → policy (`audit2allow`).
- sshd hardening: PasswordAuthentication no, PermitRootLogin no, AllowUsers/AllowGroups; `sshd -t` tests config before restart.
- `chattr +i` = immutable (even root must remove it first); `lsattr` reveals — the "root can't edit a file" answer.
- fail2ban reads logs and inserts firewall bans — it is not a firewall itself.
- Locked ≠ expired ≠ nologin: `passwd -S`, `chage -l`, and the shell field are three different denials.
- GPG: encrypt with THEIR public key; sign with YOUR private key; verify with their public.
- LUKS2: `cryptsetup luksFormat` → `luksOpen` → mkfs/mount; header holds 8 key slots; lose header = lose data.
- TLS: asymmetric handshake exchanges a symmetric session key; HMAC = keyed hash for integrity. Avoid self-signed in production — Let's Encrypt is free.
- Hygiene answers: no Telnet/FTP/TFTP; remove weak ciphers; WireGuard = modern VPN in-kernel.
- OpenSCAP scans against benchmarks (CIS); AIDE = file-integrity database (baseline then compare); rkhunter = rootkits.
- **Backporting: the fix is applied but the version number stays old — why scanners false-positive on patched distros.**
- Secure destruction: `shred` (multi-pass), `badblocks -w`, crypto-erase (destroy the LUKS key). `rm` is none of these.
- Banners: `/etc/issue` pre-login console, `/etc/issue.net` pre-login SSH, `/etc/motd` post-login.

## Domain 4 — Automation and Scripting (17%, ~15 questions)

- `#!/bin/bash`, `set -e` die-on-error, `set -x` trace, `trap 'cleanup' EXIT`.
- `$?` last exit code (0 = success); positional `$1..`, `$#` count, `$@` all args.
- **Numeric tests: `-eq -ne -lt -gt -le -ge`. String: `=` `!=`. Inside `[ ]`, `>` is a REDIRECT — the file named '5' trap.**
- `[[ ]]` > `[ ]`: regex `=~` (pattern unquoted, on the right), unescaped `&&`/`||`.
- File tests: `-f` file, `-d` dir, `-z` empty string, `-n` non-empty.
- `$(cmd)` nests; backticks don't — same job, use `$()`.
- `local` scopes function variables; `export` pushes into child environments; IFS=, to parse CSV.
- Loops: `for x in list`, `while read -r line`, `until`. `while` runs while true; `until` runs while false.
- Python: venv → activate → pip; `list` mutable/ordered, `tuple` immutable, `dict` key:value, `set` unique.
- **Python indentation is syntax, not style.** PEP 8 is the convention answer.
- Ansible agentless/push/SSH/YAML; Puppet agent/pull/catalog/30-min. Facts = gathered host data; inventory = hosts+groups.
- **Idempotent = second run reports changed=0.** A playbook that always "changes" is the buggy option.
- OpenTofu/Terraform: provider (talks to platform) + resource (declared thing). Kickstart = installer answers; cloud-init = first boot.
- K8s ladder: cluster → node → pod → container. Deployment keeps replicas; Service = stable front door; ConfigMap/Secret = config.
- Git three trees: working → `add` → index → `commit` → local → `push` → remote. **pull = fetch + merge; fetch alone is always safe.**
- reset: --soft keep-staged / --mixed keep-unstaged / --hard destroy. Never rebase pushed history.
- `.gitignore` won't untrack tracked files — `git rm --cached`. stash/pop = shelve dirty work.
- AI (4.5): review like an untrusted PR; never paste secrets; local vs cloud models = data-governance tradeoff.

## Domain 5 — Troubleshooting (22%, ~20 questions)

- Methodology: identify → theory → test → plan → implement → verify(+prevent) → document. "What NEXT" = next step, always.
- SLA contract / SLO internal target (stricter) / SLI measurement. A=agreement, O=objective, I=indicator.
- SNMP: trap = agent pushes async; MIB defines OIDs; v3 = auth+encryption. Webhook = HTTP POST on event.
- 203/EXEC = ExecStart path wrong/not executable. `systemd-analyze verify` names it.
- df/du disagree → deleted-but-open file → `lsof +L1` → restart the holder.
- **High load + idle CPU = I/O or memory (D-state), not CPU.** Load counts runnable AND uninterruptible.
- vmstat: r>nproc CPU-bound; b>0 blocked on I/O; **si/so sustained = swapping = RAM gone**; wa high = disk is the wall.
- `free -h`: read *available*, not free. OOM victims confess only in `journalctl -k -g -i oom`.
- Network layer order: physical → link → IP → routing → firewall → DNS → app. Never start at the top.
- **Refused = reachable, port closed. Timeout = filtered or unroutable.**
- 169.254.x.x = APIPA = DHCP never answered. `ethtool` link+negotiation; `ip -s link` errors/drops.
- MTU test: `ping -M do -s 1472` (1472+28=1500). Small pings pass, big transfers hang = fragmentation blocked.
- DNS isolation: `dig name` vs `dig name @1.1.1.1` — explicit server works = local resolver config is the fault.
- Perms look right but denied → mount options (`noexec` via findmnt) → SELinux (`ausearch -m AVC`) → ACL (`getfacl`).
- Cert triage: `openssl s_client -connect host:443`; expiry via `openssl x509 -noout -enddate`.
- Slow boot → `systemd-analyze blame` / `critical-chain`. Historic metrics → `sar` (sysstat). Per-process blame → `pidstat`.

---

## Quick Recall — the 15 the exam loves most

xfs cannot shrink
lvextend then resize2fs/xfs_growfs — two steps
rsync trailing slash — src/ = contents, src = the dir
passwd -l still allows key login; add /sbin/nologin
mask = cannot start at all; disable = no autostart
daemon-reload after every unit edit
firewall-cmd --permanent needs --reload; without --permanent dies on restart
chcon temporary, semanage fcontext permanent
inside [ ], > creates a file — use -gt
pull = fetch + merge; reset --hard destroys
changed=0 on run two = idempotent = correct
zombie → kill the parent
high load + idle CPU = I/O, not CPU
df -h full but du disagrees → lsof +L1
refused = closed port; timeout = filtered
