# topic-map.md — Mudd Labs Linux+ Curriculum
# Target: CompTIA Linux+ XK0-005 | Test Week: September 14, 2026
# Session A = Cheatsheet + flashcard review (45 min)
# Session B = Lab script hands-on (45–60 min)
# Two sessions per study week. Schedule dynamically each Sunday.

---

## Progress Tracker

| Week | Topic | Content Generated | Session A Done | Session B Done | Tested |
|------|-------|:-----------------:|:--------------:|:--------------:|:------:|
| 1  | File Permissions & Ownership Pt 1     | ☑ | ☐ | ☐ | ☐ |
| 2  | File Permissions & Ownership Pt 2     | ☑ | ☐ | ☐ | ☐ |
| 3  | User & Group Management Pt 1          | ☑ | ☐ | ☐ | ☐ |
| 4  | User & Group Management Pt 2          | ☑ | ☐ | ☐ | ☐ |
| 5  | SSH Key Authentication Pt 1           | ☐ | ☐ | ☐ | ☐ |
| 6  | SSH Key Authentication Pt 2           | ☐ | ☐ | ☐ | ☐ |
| 7  | Systemd & Services Pt 1               | ☐ | ☐ | ☐ | ☐ |
| 8  | Systemd & Services Pt 2               | ☐ | ☐ | ☐ | ☐ |
| 9  | Networking Fundamentals               | ☐ | ☐ | ☐ | ☐ |
| 10 | Firewall Rules & Security             | ☐ | ☐ | ☐ | ☐ |
| 11 | Centralized Logging Pt 1              | ☐ | ☐ | ☐ | ☐ |
| 12 | Centralized Logging Pt 2              | ☐ | ☐ | ☐ | ☐ |
| 13 | Bash Scripting Pt 1                   | ☐ | ☐ | ☐ | ☐ |
| 14 | Bash Scripting Pt 2                   | ☐ | ☐ | ☐ | ☐ |
| 15 | Package Management Pt 1 (apt)         | ☐ | ☐ | ☐ | ☐ |
| 16 | Package Management Pt 2 (dnf/rpm)     | ☐ | ☐ | ☐ | ☐ |
| 17 | Security & Vulnerability Scanning     | ☐ | ☐ | ☐ | ☐ |
| 18 | SELinux & Security Modules            | ☐ | ☐ | ☐ | ☐ |
| 19 | Practice Exam + Gap Analysis          | ☐ | ☐ | ☐ | ☐ |

---

## Phase 1 — Foundation Revisit
*Two calendar weeks per study week. Don't rush this. These are the building blocks everything else stands on.*

### Week 1 — File Permissions & Ownership Pt 1
**Calendar window:** May 4–17
**Session A goal:** Read cheatsheet, review chmod/chown/ls -l flashcards. Understand rwx in symbolic and octal. Know what each bit means for files vs directories.
**Session B goal:** Run lab script — create `~/permission-practice/` directory tree, apply chmod 755/644/600/400, verify with `ls -l`, test access with a second user account.
**Exam objectives:** 2.1 — Given a scenario, manage files and directories

---

### Week 2 — File Permissions & Ownership Pt 2
**Calendar window:** May 18–31
**Session A goal:** Cheatsheet — SUID, SGID, sticky bit, umask. Know what each does, when each is dangerous, how to find them in the wild.
**Session B goal:** Lab script — set special permissions on test files/dirs, configure umask in ~/.bashrc, use `find` to locate SUID files on the system.
**Exam objectives:** 2.1 — File permissions including special bits

---

### Week 3 — User & Group Management Pt 1
**Calendar window:** Jun 1–14
**Session A goal:** Cheatsheet — /etc/passwd, /etc/shadow, /etc/group structure. UID/GID ranges. useradd, usermod, userdel, groupadd. Know what each field in passwd/shadow means.
**Session B goal:** Lab script — create users and groups on ThinkPad, test su switching, verify /etc/passwd entries, set password aging with chage.
**Exam objectives:** 2.2 — Given a scenario, manage users and groups

---

### Week 4 — User & Group Management Pt 2
**Calendar window:** Jun 15–28
**Session A goal:** Cheatsheet — sudo, visudo, /etc/sudoers syntax. su vs sudo. Privilege escalation paths. Know how to grant and restrict sudo access safely.
**Session B goal:** Lab script — edit sudoers with visudo, create command-specific sudo rules, enable sudo logging, test privilege escalation on homelab devices.
**Exam objectives:** 2.2 — Privilege escalation and sudo configuration

---

## Phase 2 — Core Skills Pipeline
*Material is already processed by Gemini CLI. Execute the pipeline. Show up and do the work.*

### Week 5 — SSH Key Authentication Pt 1
**Calendar window:** Jun 29–Jul 5
**Session A goal:** Cheatsheet — ssh-keygen algorithms (ed25519 preferred), authorized_keys, known_hosts, ssh-agent. Understand the full key exchange flow.
**Session B goal:** Lab script — generate ed25519 keypair, deploy to Dell Server (t1) via ssh-copy-id, verify passwordless login, check authorized_keys permissions (must be 600).
**Exam objectives:** 3.2 — Given a scenario, implement SSH security

---

### Week 6 — SSH Key Authentication Pt 2
**Calendar window:** Jul 6–12
**Session A goal:** Cheatsheet — sshd_config hardening options: PasswordAuthentication, PermitRootLogin, AllowUsers, MaxAuthTries, ClientAliveInterval. Know what each does and why.
**Session B goal:** Lab script — harden sshd_config on Dell Server, disable password auth, create ~/.ssh/config on ThinkPad for clean host aliases across Tailscale mesh.
**Exam objectives:** 3.2 — SSH hardening and configuration

---

### Week 7 — Systemd & Services Pt 1
**Calendar window:** Jul 13–19
**Session A goal:** Cheatsheet — unit types (service, socket, timer, target), systemctl verbs (start/stop/enable/disable/status/mask), journalctl flags. Understand how targets replace runlevels.
**Session B goal:** Lab script — audit all running services on ThinkPad and Dell Server, identify and disable unnecessary services, verify Gitea and n8n service status, check journalctl for recent errors.
**Exam objectives:** 1.3 — Given a scenario, manage services

---

### Week 8 — Systemd & Services Pt 2
**Calendar window:** Jul 20–26
**Session A goal:** Cheatsheet — unit file anatomy: [Unit], [Service], [Install] sections. Key directives: ExecStart, Restart, RestartSec, After, WantedBy. How daemon-reload works.
**Session B goal:** Lab script — write a custom .service unit file from scratch, place it in /etc/systemd/system/, daemon-reload, enable and start it, verify with journalctl -u.
**Exam objectives:** 1.3 — Systemd unit file creation and management

---

### Week 9 — Networking Fundamentals
**Calendar window:** Jul 27–Aug 2
**Session A goal:** Cheatsheet — ip addr, ip route, ss -tulpn, ping, traceroute, /etc/hosts, /etc/resolv.conf. OSI model basics. TCP vs UDP. Know what each command reveals and when to use it.
**Session B goal:** Lab script — document full network topology from ThinkPad: all device IPs, Tailscale addresses, open ports per device using ss and nmap. Output to a topology notes file.
**Exam objectives:** 1.4 — Given a scenario, configure and troubleshoot networking

---

### Week 10 — Firewall Rules & Security
**Calendar window:** Aug 3–9
**Session A goal:** Cheatsheet — iptables chains (INPUT/OUTPUT/FORWARD), default policies, ufw commands, firewalld zones. Know how to read existing rules and what each chain controls.
**Session B goal:** Lab script — review and document all active firewall rules across homelab devices (UFW on Ubuntu/Pi, FirewallD on Fedora). Cross-reference against the firewall docs in the homelab repo.
**Exam objectives:** 3.1 — Given a scenario, implement security best practices

---

### Week 11 — Centralized Logging Pt 1
**Calendar window:** Aug 10–16
**Session A goal:** Cheatsheet — rsyslog vs journald, log forwarding config, facility/severity levels, /var/log structure. Know the difference between persistent and volatile journal storage.
**Session B goal:** Lab script — configure rsyslog on Dell Server to accept remote logs, configure log forwarding from Pi4 to Dell Server, test with `logger` command, verify receipt.
**Exam objectives:** 4.2 — Given a scenario, analyze and troubleshoot logs

---

### Week 12 — Centralized Logging Pt 2
**Calendar window:** Aug 17–23
**Session A goal:** Cheatsheet — logrotate config syntax, grep/awk/sed patterns for log analysis, journalctl filtering flags (--since, --until, -u, -p). Know how to find what you're looking for fast.
**Session B goal:** Lab script — write a logrotate config for a custom log, parse auth.log for failed SSH attempts using awk, pipe output to a findings file. This directly feeds ClearMudd groundwork.
**Exam objectives:** 4.2 — Log management and analysis

---

### Week 13 — Bash Scripting Pt 1
**Calendar window:** Aug 24–30
**Session A goal:** Cheatsheet — shebang, exit codes ($?), if/then/else, for loops, while loops, positional parameters ($1 $2), command substitution, test operators (-f, -d, -z, -eq, etc.).
**Session B goal:** Lab script — write a service-checker script from scratch: takes a service name as argument, checks status, returns clean output with exit code. Must handle missing argument gracefully.
**Exam objectives:** 1.6 — Given a scenario, write a script

---

### Week 14 — Bash Scripting Pt 2
**Calendar window:** Aug 31–Sep 6
**Session A goal:** Cheatsheet — functions, arrays, set -e/set -x, trap, heredocs, crontab syntax (minute/hour/dom/month/dow). Know how to write robust, error-aware scripts.
**Session B goal:** Lab script — write a cron-based backup script with functions, array of target directories, trap for cleanup on failure, and a logfile. Schedule it in crontab on ThinkPad.
**Exam objectives:** 1.6 — Advanced scripting patterns

---

## Phase 3 — Exam Prep

### Week 15 — Package Management Pt 1 (apt/dpkg)
**Session A goal:** Cheatsheet — apt update/upgrade/install/remove/purge/search/show, apt-cache, dpkg -l/-i/-r, /etc/apt/sources.list, GPG key management. Know the full apt workflow cold.
**Session B goal:** Lab script — full apt workflow on Dell Server and Pi4: update, upgrade, search for a package, inspect dependencies, install, verify, remove cleanly.
**Exam objectives:** 1.7 — Given a scenario, manage software

---

### Week 16 — Package Management Pt 2 (dnf/rpm)
**Session A goal:** Cheatsheet — dnf update/install/remove/search/info/history, rpm -qa/-ivh/-e/-V, EPEL repo setup, comparing apt vs dnf workflows side by side.
**Session B goal:** Lab script — full dnf workflow on ThinkPad (Fedora) and Fedora VM on Dell Server. Use rpm to inspect an installed package. Document key differences from apt workflow.
**Exam objectives:** 1.7 — RPM-based package management

---

### Week 17 — Security & Vulnerability Scanning
**Session A goal:** Cheatsheet — nmap scan types (-sV, -sS, -p, -A), lynis audit categories, fail2ban basics, CVE/CVSS concepts, principle of least privilege applied to services.
**Session B goal:** Lab script — run nmap scan against homelab subnet, run lynis audit on ThinkPad, capture findings to a file. Review against known-good state. This directly informs ClearMudd.
**Exam objectives:** 3.3 — Given a scenario, implement security controls

---

### Week 18 — SELinux & Security Modules
**Session A goal:** Cheatsheet — getenforce/setenforce/sestatus, security contexts (ls -Z), chcon, restorecon, booleans (getsebool/setsebool), ausearch -m avc. Know enforcing vs permissive vs disabled.
**Session B goal:** Lab script — run ausearch on Fedora ThinkPad and Fedora VM for recent AVC denials, review contexts on key directories, document any booleans currently set non-default.
**Exam objectives:** 3.1 — SELinux and mandatory access control

---

### Week 19 — Practice Exam + Gap Analysis
**Session A goal:** Take a full-length practice exam (Dion Training or CompTIA CertMaster). Score it. Write down every topic under 70%.
**Session B goal:** For each weak topic: open the relevant week's cheatsheet, run the relevant lab script, ask Claude "Quiz me on [topic]." Targeted drilling only — no re-reading everything.
**Target:** 80%+ on practice exam before scheduling the real test.
**Exam date:** Week of September 14, 2026

---

*Rooted in craft. Reaching past the last mark.*
