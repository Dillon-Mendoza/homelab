# Week 06 — Reference Notes
# Objectives: 2.6, 3.2, 3.3 | Calendar: Aug 3–9

---

## Exam Objective Mapping

**2.6 — Given a scenario, manage applications in a container on a Linux server**
- Runtimes: Docker, Podman, containerd, runC
- Image ops: pull, build (Dockerfile: FROM, ENTRYPOINT, CMD, USER), tag, prune, layers
- Container ops: `run`, `exec`, `start`/`stop`, `inspect`, `logs`, `rm`, `prune`, env vars
- Volume ops: create, bind mount, SELinux context (`:z`/`:Z`), overlay
- Container networks: bridge, host, macvlan, ipvlan, overlay, none; port mapping
- Privileged vs. unprivileged containers

**3.2 — Given a scenario, configure and implement firewalls on a Linux system**
- firewalld: `firewall-cmd`, zones, ports vs. services, rich rules, runtime vs. permanent
- UFW; `iptables`, `nftables`, `ipset`
- NAT, PAT, DNAT, SNAT; `net.ipv4.ip_forward`; stateful vs. stateless

**3.3 — Given a scenario, apply OS hardening techniques on a Linux system**
- sudo: `/etc/sudoers`, `visudo`, NOEXEC, NOPASSWD, `sudoers.d`, `sudo -i` vs `su -`, wheel
- `chattr`/`lsattr`; permissions incl. SUID/SGID/sticky; `umask`; ACLs (`setfacl`/`getfacl`)
- SELinux: full tool list, enforcing/permissive/disabled
- SSH hardening: `sshd_config` directives, tunneling, agent, SFTP
- `chroot`, `fail2ban`; avoid Telnet/FTP/TFTP; disable unused filesystems; remove
  unneeded SUID bits; Secure Boot/UEFI

---

## Key Man Pages

`man firewall-cmd` — the RUNTIME AND PERMANENT section states the split in three sentences; also skim `--runtime-to-permanent`. Zone options are all listed here — faster than any tutorial.

`man podman-run` — search for `--volume`: the paragraph on `:z` vs `:Z` labeling is the canonical statement of lab Task 3, and the `--privileged` entry defines exactly what the exam means by privileged containers.

`man 5 sudoers` — huge; read only the sections on `NOPASSWD`/`NOEXEC` tags and the `#includedir` mechanism that makes `/etc/sudoers.d` work. Section 5, the file format.

`man chattr` — one page. The `i` and `a` attribute descriptions are the exam content; note which attributes only root may set.

`man sshd_config` — look up the four directives from the lab (`PermitRootLogin`, `PasswordAuthentication`, `AllowUsers`, `X11Forwarding`) and read their *default* values — questions test defaults as often as settings.

---

## Video Timestamps

**Theory Course (12hr — nGPK6YBbKpg):**
Three sections: "Containers" (2.6), "Firewalls" (3.2), and "OS Hardening" (3.3) — containers close the Domain 2 block, then the course pivots into Domain 3. The hardening section is long; the permissions half is review for you (archive weeks), so prioritize the SELinux and firewalld segments.

**Labs Course (7hr — JXIaR23OdB8):**
The Docker/container lab maps to Tasks 1–3 — they'll demo Docker; every command translates to podman verbatim, and noticing where rootless behaves differently *is* the learning. The firewalld walkthrough pairs with Task 4 — watch for whether they remember `--reload` after `--permanent`; catching an instructor's mistake is the best retention device there is.

---

## Book Reference — How Linux Works, 3rd Ed. (Ward)

**Ch. 9 — Understanding Your Network (revisit)**
Assigned fully in Week 3; this week you only need the routing/NAT discussion as the substrate under the iptables chain flow — PREROUTING/POSTROUTING make sense only if the routing decision between them is solid. Skim, don't reread.

**Ch. 17 — Virtualization (container section)**
If your copy includes Ch. 17 (the 3rd-edition virtualization chapter), its second half explains containers as namespaces + cgroups on a shared kernel — the mechanism behind lab Task 1e's rootless proof. Ten pages that turn "daemonless" from a marketing word into an architecture. Read before Session B if you can.

**Not covered by the book:** SELinux and firewalld specifics. For those, the primary sources are the man pages above plus Fedora's own docs — the book's job this week is the network and process foundations only.

---

## Things That Trip People Up

**1. The firewalld split bites in both directions**
Runtime-only change → gone at `--reload`/reboot ("the port I opened yesterday is closed again"). `--permanent`-only change → nothing happens now ("I added the rule and it still doesn't work"). Lab Task 4 made you produce *both* failures on purpose. Third path: `--runtime-to-permanent` saves live state when you got runtime right and want to keep it.

**2. Rootless podman can't publish ports below 1024**
`podman run -p 80:80` as a regular user fails with a permission error; `-p 8080:80` works. It's not a podman limitation — it's the kernel's unprivileged-port floor (`net.ipv4.ip_unprivileged_port_start`). Any rootless-container-plus-low-port scenario is testing this.

**3. Run args replace CMD, never ENTRYPOINT**
`podman run img foo` — `foo` replaces CMD entirely and gets appended to ENTRYPOINT. If a question shows unexpected container behavior after passing arguments, work out which directive absorbed them. `--entrypoint` is the only way to displace ENTRYPOINT.

**4. `mv` smuggles SELinux contexts; `cp` doesn't**
`cp` creates a new inode → inherits the destination directory's default context. `mv` keeps the original context (same inode, Week 4). "Moved a config into the web root, service gets EACCES, permissions are 644 root:root and *look* right" → `ls -Z`, then `restorecon`. Task 7b is this exact scenario in miniature.

**5. `chcon` loses to every relabel — `semanage fcontext` is the permanent path**
`chcon` changes the label on disk but not the *policy*. `restorecon`, an autorelabel, or a policy update reverts it silently, sometimes weeks later — a delayed-fuse outage. Permanent = `semanage fcontext -a -t <type> '<path-regex>'` followed by `restorecon -R`. The exam phrases it as "the context change didn't persist."

**6. `chattr +i` produces the spookiest permission error**
Root, mode 777, still `Operation not permitted` on delete — and `ls -l` shows nothing wrong because attributes aren't permissions. `lsattr` is the only window. Scenario: "even root cannot modify the file" → immutable attribute, `chattr -i` to clear. (`+a` append-only is its log-protecting sibling.)

---

## Connect to the Homelab

This week audits the machine you administer everything else from, and the overlaps are direct. The firewalld task interrogates `tp-mudd`'s actual documented policy — no inbound except over `tailscale0` — and the audit script now checks runtime-vs-permanent drift on every run, which is precisely the failure mode that policy could die from silently. SELinux enforcing is this laptop's daily reality, not a lab setting: the `:Z` volume flag in Task 3 is the exact incantation any real containerized service here would need, and the n8n Docker deployment on `dell-fedora` (conceptual anchor) is the daemon-and-root contrast to the rootless podman workflow you now know first-hand — same CLI verbs, fundamentally different privilege model. The sudo audit closes the loop on Week 4's account work: your own wheel membership, a `visudo -c` syntax guarantee, and `journalctl _COMM=sudo` attributing every escalation by name is the zero-trust story of this fleet told in three commands. Worth keeping after the exam: the audit script's SUID baseline and firewall-drift checks are genuinely useful recurring health checks for the box that holds the keys to everything else.
