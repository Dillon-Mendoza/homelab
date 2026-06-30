# CompTIA Linux+ XK0-006 — Exam Curriculum Reference
# Objectives Document Version 4.0 | Exam: XK0-006 V8 | Target: September 14, 2026

---

## Exam Facts

| Detail | Value |
|--------|-------|
| Exam code | XK0-006 |
| Questions | Maximum 90 (multiple-choice + performance-based) |
| Time | 90 minutes |
| Passing score | 720 / 900 |
| Recommended experience | 12 months hands-on Linux server work |

---

## Domain Weights — What the Exam Actually Tests

| # | Domain | Weight | ~Questions |
|---|--------|--------|-----------|
| 1 | System Management | 23% | ~21 |
| 2 | Services and User Management | 20% | ~18 |
| 3 | Security | 18% | ~16 |
| 4 | Automation, Orchestration, and Scripting | 17% | ~15 |
| 5 | Troubleshooting | 22% | ~20 |

Priority order for study time: D1 → D5 → D2 → D3 → D4

---

## What Changed From XK0-005

This is a significant restructure, not a minor update. Know these differences:

- **5 domains** (was 4). "Services and User Management" is now its own domain.
- **Python is tested** (4.3). Not just Bash.
- **Git is tested** (4.4). You already use it — now you need to know the commands cold.
- **Ansible and Puppet** are named explicitly (4.1). Conceptual level.
- **Containers expanded** — Docker, Podman, runC, Kubernetes basics (2.6, 4.1).
- **Cryptography is an objective** (3.5) — GPG, LUKS2, TLS, WireGuard.
- **AI responsible use** is an objective (4.5) — concepts only, not implementation.
- **Compliance and audit** is an objective (3.6) — OpenSCAP, CIS Benchmarks, AIDE.
- **Monitoring concepts** are tested (5.1) — SLA/SLI/SLO, SNMP, log aggregation.

---

## Domain 1: System Management (23%)

### 1.1 — Explain basic Linux concepts

- **Boot process:** bootloader config files, kernel parameters, initrd, PXE
- **FHS:** /, /bin, /boot, /dev, /etc, /home, /lib, /proc, /sbin, /tmp, /usr, /var — know the purpose of each
- **Architectures:** x86, x86_64/AMD64, AArch64, RISC-V
- **Distributions:** RPM-based vs. dpkg-based
- **Software licensing:** open source, free software, proprietary, copyleft

### 1.2 — Summarize Linux device management concepts and tools

- **Kernel modules:** `depmod`, `insmod`, `lsmod`, `modinfo`, `modprobe`, `rmmod`
- **Device inspection:** `dmesg`, `dmidecode`, `lscpu`, `lsmem`, `lspci`, `lsusb`, `lshw`
- **Sensors/IPMI:** `ipmitool`, `lm_sensors`, `nvtop`
- **initrd management:** `dracut`, `mkinitrd`

### 1.3 — Given a scenario, manage storage in a Linux system

- **LVM:** `pvcreate/pvdisplay/pvremove/pvresize`, `vgcreate/vgextend/vgreduce/vgdisplay`, `lvcreate/lvextend/lvresize/lvremove/lvdisplay`, `lvs/vgs/pvs`
- **Partitioning:** `fdisk`, `gdisk`, `parted`, `lsblk`, `blkid`, `growpart`
- **Filesystems:** ext4, xfs, btrfs, tmpfs — `mkfs`, `fsck`, `resize2fs`, `xfs_growfs`, `xfs_repair`
- **RAID:** `mdadm`, `/proc/mdstat`
- **Mounting:** `/etc/fstab`, `/etc/mtab`, `/proc/mounts`, `autofs`, `mount`, `umount`
- **Mount options:** `noatime`, `nodev`, `nodiratime`, `noexec`, `nofail`, `nosuid`, `remount`, `ro`, `rw`
- **Network mounts:** NFS, SMB/Samba
- **Disk utilities:** `df`, `du`, `fio`
- **Inodes** — understand inode exhaustion

### 1.4 — Given a scenario, manage network services and configurations on a Linux server

- **Config files:** `/etc/hosts`, `/etc/resolv.conf`, `/etc/nsswitch.conf`
- **NetworkManager:** `nmcli`, `nmconnect`
- **Netplan:** `netplan apply`, `netplan status`, `netplan try`, `/etc/netplan`
- **Tools:** `ip addr/link/route`, `ss`, `nmap`, `ping/ping6`, `dig`, `nslookup`, `traceroute`, `tracepath`, `curl`, `nc`, `tcpdump`, `mtr`, `iperf3`, `ethtool`, `arp`, `hostname`

### 1.5 — Given a scenario, manage a Linux system using common shell operations

- **Env vars:** `PATH`, `HOME`, `SHELL`, `USER`, `PS1`, `DISPLAY`
- **Shell config:** `.bashrc`, `.bash_profile`, `.profile`
- **Paths:** absolute (`~`, `/`), relative (`.`, `..`, `-`)
- **Redirection:** `<`, `>`, `>>`, `<<`, `|`, stdin/stdout/stderr, heredocs `<<<`
- **Core utilities:** `grep`, `awk`, `sed`, `cut`, `sort`, `uniq`, `wc`, `xargs`, `find`, `head`, `tail`, `tee`, `tr`, `printf`, `cat`, `echo`, `alias`, `source`, `bc`
- **Text editors:** `vim`, `nano`

### 1.6 — Given a scenario, perform backup and restore operations for a Linux server

- **Archiving:** `tar`, `cpio`
- **Compression:** `gzip`, `bzip2`, `xz`, `7-Zip`, `unzip`
- **Transfer/clone:** `rsync`, `dd`, `ddrescue`
- **Compressed viewing:** `zcat`, `zgrep`, `zless`

### 1.7 — Summarize virtualization on Linux systems

- **Hypervisors:** QEMU, KVM
- **VM tools:** `virsh`, `virt-manager`, `libvirt`
- **VM operations:** snapshots, cloning, migrations, resource allocation (CPU/RAM/storage/network)
- **Disk image ops:** convert, resize, image properties
- **Network types:** bridged, NAT, host-only/isolated, routed, open
- **Bare metal vs. virtual machines**; paravirtualized drivers (VirtIO); nested virtualization

---

## Domain 2: Services and User Management (20%)

### 2.1 — Given a scenario, manage files and directories on a Linux system

- **Utilities:** `ls`, `cp`, `mv`, `rm`, `mkdir`, `rmdir`, `find`, `locate`, `stat`, `lsof`, `ln`, `diff`, `sdiff`, `file`, `touch`, `pwd`, `cd`
- **Links:** symbolic (soft) vs. hard — know the difference and when each breaks
- **Device types in /dev:** block devices, character devices, special character devices

### 2.2 — Given a scenario, perform local account management in a Linux environment

- **User ops:** `useradd`, `adduser`, `usermod`, `userdel`, `deluser`
- **Group ops:** `groupadd`, `groupmod`, `groupdel`
- **Password/locking:** `passwd`, `chage`, `usermod -L/-U`, `chsh`
- **Account files:** `/etc/passwd`, `/etc/shadow`, `/etc/group` — know every field
- **Templates:** `/etc/skel`, `/etc/profile`
- **Inspection:** `id`, `groups`, `who`, `w`, `whoami`, `last`, `lastlog`, `getent passwd`
- **UID ranges:** root (0), system accounts (1–999), regular users (1000+)
- **UID vs. EUID, GID vs. EGID**
- **User vs. system vs. service accounts**

### 2.3 — Given a scenario, manage processes and jobs in a Linux environment

- **Monitoring:** `ps`, `top`, `htop`, `atop`, `pstree`, `lsof`, `strace`, `pidstat`, `mpstat`, `/proc/<PID>`
- **Process states:** running, sleeping, blocked, stopped, zombie
- **Signals:** `kill`, `killall`, `pkill`; SIGTERM (15), SIGKILL (9), SIGHUP (1)
- **Priority:** `nice`, `renice`
- **Process limits**
- **Job control:** `&`, `bg`, `fg`, `jobs`, `nohup`, `Ctrl+Z`, `Ctrl+C`, `Ctrl+D`, `exec`
- **Scheduling:** `crontab`, `at`, `anacron`; crontab syntax cold

### 2.4 — Given a scenario, configure and manage software in a Linux environment

- **Package managers:** `apt`, `dnf`, `rpm`, `dpkg`; language managers `pip`, `cargo`, `npm`
- **Repos:** `/etc/apt/sources.list`, `/etc/yum.repos.d/`, enabling/disabling repos, third-party repos, GPG signatures
- **Update alternatives**, sandboxed apps (snap, flatpak)
- **Software configuration**
- **Basic service configs:** DNS, NTP/PTP, DHCP, HTTP (Apache httpd, Nginx), SMTP, IMAP4

### 2.5 — Given a scenario, manage Linux using systemd

- **Unit types:** service, timer, mount, target
- **`systemctl`:** start, stop, restart, reload, enable, disable, mask, unmask, status, daemon-reload, edit
- **Utilities:** `systemd-analyze`, `systemd-blame`, `journalctl`, `hostnamectl`, `timedatectl`, `resolvectl`, `sysctl`

### 2.6 — Given a scenario, manage applications in a container on a Linux server

- **Runtimes:** Docker, Podman, containerd, runC
- **Image ops:** pull, build (Dockerfile: FROM, ENTRYPOINT, CMD, USER), tag, prune, layers
- **Container ops:** `run`, `exec`, `start`/`stop`, `inspect`, `logs`, `rm`, `prune`, env vars
- **Volume ops:** create, bind mount, SELinux context, overlay
- **Container networks:** bridge, host, macvlan, ipvlan, overlay, none; port mapping
- **Privileged vs. unprivileged containers**

---

## Domain 3: Security (18%)

### 3.1 — Summarize authorization, authentication, and accounting methods

- **Auth frameworks:** PAM, Polkit, SSSD/Winbind realm
- **Directory services:** LDAP, Kerberos, Samba
- **Logging:** `rsyslog`, `journalctl`, `logrotate`, `/var/log`
- **System audit:** `auditd`, `audit.rules`

### 3.2 — Given a scenario, configure and implement firewalls on a Linux system

- **firewalld:** `firewall-cmd`, zones, ports vs. services, rich rules, runtime vs. permanent
- **UFW:** ports vs. services
- **`iptables`**, **`nftables`**, **`ipset`**
- **NAT, PAT, DNAT, SNAT**
- **`net.ipv4.ip_forward`** — IP forwarding
- **Stateful vs. stateless filtering**

### 3.3 — Given a scenario, apply OS hardening techniques on a Linux system

- **Sudo:** `/etc/sudoers`, `visudo`, NOEXEC, NOPASSWD implications, `/etc/sudoers.d`, `sudo -i` vs. `su -`, wheel group
- **File attributes:** `chattr`, `lsattr` (immutable, append-only)
- **Permissions:** `chmod` (octal and symbolic), `chown`, `chgrp`; SUID, SGID, sticky bit; `umask`
- **ACLs:** `setfacl`, `getfacl`
- **SELinux:** `getenforce`, `setenforce`, `restorecon`, `chcon`, `semanage`, `ls -Z`, `getsebool`, `setsebool`, `audit2allow`, `sealert`; enforcing/permissive/disabled states
- **SSH hardening:** `sshd_config` options — PasswordAuthentication, PermitRootLogin, AllowUsers, AllowGroups, X11Forwarding; SSH tunneling; SSH agent; SFTP
- **`chroot`**, **`fail2ban`**
- **Avoid:** Telnet, FTP, TFTP
- **Disable** unused filesystems; remove unnecessary SUID permissions
- **Secure boot / UEFI**

### 3.4 — Explain account hardening techniques and best practices

- **Password policy:** complexity, length, expiration, history, reuse
- **MFA** concepts
- **Breach list checking**
- **Restricted shells:** `/sbin/nologin`, `/bin/rbash`
- **`pam_tally2`**
- **Avoid running as root**

### 3.5 — Explain cryptographic concepts and technologies in a Linux environment

- **Data at rest:** GPG file encryption, LUKS2 filesystem encryption, Argon2
- **Data in transit:** OpenSSL, WireGuard, LibreSSL, TLS protocol versions
- **Hashing:** SHA-256, HMAC
- **Certificate management:** trusted root CAs (Let's Encrypt = no-cost, commercial), avoiding self-signed certs
- **Remove weak algorithms**

### 3.6 — Explain the importance of compliance and audit procedures

- **Threat detection:** anti-malware, indicators of compromise (IoC)
- **Vulnerability scanning:** CVE, CVSS, backporting patches, service misconfiguration, port scanners, protocol analyzers
- **Compliance standards:** OpenSCAP, CIS Benchmarks
- **File integrity:** AIDE, rkhunter, signed package verification
- **Secure data destruction:** `shred`, `badblocks -w`, `dd if=/dev/urandom`, cryptographic destruction
- **Software supply chain**
- **Security banners:** `/etc/issue`, `/etc/issue.net`, `/etc/motd`

---

## Domain 4: Automation, Orchestration, and Scripting (17%)

### 4.1 — Summarize use cases and techniques of automation and orchestration

- **Ansible:** playbooks, inventory, modules, ad hoc commands, agentless, collections, facts
- **Puppet:** classes, modules, certificates, facts, agent/agentless
- **OpenTofu (Terraform fork):** provider, resource
- **Unattended deployment:** Kickstart, cloud-init
- **CI/CD:** version control integration, pipelines, GitOps, DevSecOps, shift left testing
- **Kubernetes:** pods, deployments, services, ConfigMaps, volumes, secrets
- **Docker Swarm:** services, nodes, tasks, networks, scale
- **Docker/Podman Compose:** compose file, up/down, logs

### 4.2 — Given a scenario, perform automated tasks using shell scripting

- **Variables:** environmental, positional (`$1`, `$2`), assignments (`export`, `local`, `alias`, `set`, `unset`, `unalias`)
- **Expansion:** parameter `${var}`, command substitution `$(cmd)` / backtick, subshell `(cmd)`
- **IFS/OFS**
- **Conditionals:** `if/then/else/fi`, `case`
- **Loops:** `for`, `while`, `until`
- **Functions**
- **Comparisons:** numeric (`-eq`, `-lt`, `-gt`, `-le`, `-ge`, `-ne`), string (`=`, `!=`, `<`, `>`, `==`, `=~`, `<=`, `>=`)
- **Test operators:** `-f`, `-d`, `-z`, `-n`, `-!`
- **Regular expressions:** `[[ $foo =~ regex ]]`
- **Return codes:** `$?`
- **Interpreter directive:** `#!/bin/bash`

### 4.3 — Summarize Python basics used for Linux system administration

- **Virtual environments:** `python3 -m venv`
- **Installing dependencies:** `pip install`
- **Data types:** boolean, integer, float, string, list, dictionary
- **Fundamentals:** indentation, current versions (3.x), extensible with modules
- **Built-in modules** relevant to sysadmin work
- **PEP 8** style conventions

### 4.4 — Given a scenario, implement version control using Git

- **Setup:** `git init`, `git config`, `.gitignore`
- **Daily workflow:** `git add`, `git commit`, `git status`, `git diff`
- **Branching:** `git branch`, `git checkout`, `git merge` (squash), `git rebase`
- **Remote:** `git clone`, `git fetch`, `git pull`, `git push`, `git remote`
- **Advanced:** `git log`, `git stash`, `git tag`, `git reset`

### 4.5 — Summarize best practices and responsible uses of AI

- **Use cases:** code generation, IaC generation, documentation, security review, compliance recommendations, regex generation, code linting
- **Best practices:** always review output, do not copy/paste without QA, verify output
- **Data governance:** LLM training data risks, human review, local vs. cloud models, corporate policy
- **Prompt engineering** basics

---

## Domain 5: Troubleshooting (22%)

### 5.1 — Summarize monitoring concepts and configurations in a Linux system

- **Service monitoring:** SLA (agreement), SLI (indicator), SLO (objective) — know the definitions
- **Data acquisition:** SNMP traps, MIBs, agent vs. agentless monitoring
- **Configs:** thresholds, alerts, events, notifications, webhooks, health checks, log aggregation

### 5.2 — Given a scenario, analyze and troubleshoot hardware, storage, and Linux OS issues

Symptom catalog to know cold:
- Kernel panic, kernel/data corruption
- Filesystem won't mount, OS filesystem full, inode exhaustion
- GRUB misconfiguration
- Systemd unit failures
- Missing/disabled drivers, device failure
- Partition not writable, quota issues, memory leaks
- PATH misconfiguration, killed processes, unresponsive processes
- Segmentation fault, server inaccessible, server won't power on

### 5.3 — Given a scenario, analyze and troubleshoot networking issues on a Linux system

Symptom catalog to know cold:
- Misconfigured firewalls
- DHCP failures, DNS failures
- Interface misconfiguration: MTU mismatch, bonding, MAC spoofing
- Routing issues (gateway misconfigured)
- Server unreachable, IP conflicts
- IPv4/IPv6 dual stack issues
- Link down, link negotiation failures, cannot ping server

### 5.4 — Given a scenario, analyze and troubleshoot security issues on a Linux system

Symptom catalog to know cold:
- SELinux denials: policy, context, boolean misconfigurations
- File/directory permission and ACL denials
- Account access failures
- Unpatched/vulnerable systems, exposed or misconfigured services
- Remote access issues, certificate issues
- Insecure protocols in use, cipher negotiation failures
- Misconfigured package repositories

### 5.5 — Given a scenario, analyze and troubleshoot performance issues

Symptom catalog to know cold:
- OOM, swapping
- High CPU usage, high load average, high context switching
- High I/O wait, high disk latency, low throughput
- Packet drops, jitter, high latency, random disconnects/timeouts
- Slow startup, sluggish terminal, blocked processes
- CPU bottleneck, slow remote storage response

---

## Homelab Coverage Map

| Objective | Where You Already Have This |
|-----------|----------------------------|
| 1.3 Storage | LVM on `dell-ubuntu`; VM disk ops on `dell-fedora` |
| 1.4 Networking | Full Tailscale mesh; `/etc/hosts`; `ss`, `nmap`, `ip` across all nodes |
| 1.7 Virtualization | KVM/QEMU on `dell-ubuntu` running `dell-fedora` VM |
| 2.4 Software | `apt` on Ubuntu/Pi nodes; `dnf` on Fedora nodes |
| 2.5 Systemd | Gitea service, n8n Docker service, all devices |
| 2.6 Containers | n8n Docker on `dell-fedora` |
| 3.2 Firewalls | UFW on `dell-ubuntu`, `muddpi`, `pi-zero`; firewalld on `tp-mudd`, `dell-fedora` |
| 3.3 OS Hardening | SELinux on `tp-mudd`/`dell-fedora`; sudo config on all devices |
| 4.2 Scripting | network-monitor and health-check scripts already in repo |
| 4.4 Git | This homelab repo — dual remote push, branching, commits |
| 5.3 Network troubleshooting | Tailscale mesh; past DNS and ACL outage incidents documented |

---

## Study Resources

Free resources only — pay for the exam, nothing else.

| Resource | Cost | Type | When to Use |
|----------|------|------|-------------|
| XK0-006 Complete Theory Course (12 hr, YouTube) | Free | Video | Session A supplement throughout |
| XK0-006 Labs Course (7 hr, YouTube) | Free | Video | Session B context — watch alongside lab-script.sh |
| LearnLinuxTV | Free | Video | Additional hands-on demos |
| Your homelab | Free | Lab | Every Session B — use this first |
| Dion Training Practice Exams (Udemy) | ~$15 on sale | Practice exams | Week 11 only — buy during a Udemy sale (they run constantly) |

**Not in the plan:**
- CompTIA Linux+ Study Guide (Sybex) — useful but not required. Professor Messer covers the same objectives for free.
- CompTIA CertMaster Practice — overpriced for what it is. Dion Training is equivalent and cheaper.

The one paid item worth buying before exam day is a practice exam set. You need to sit a real 90-question, 90-minute session and see your score before committing to the test date. Buy Dion Training during Week 9 or 10 when you're ready to use it.
| Your homelab | Hands-on lab | Session B — use first |
