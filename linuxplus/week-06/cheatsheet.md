# Week 06 — Containers + Firewalls + OS Hardening
# Domain: 2.0 (20%) + 3.0 Security (18%) | Objectives: 2.6, 3.2, 3.3
# Calendar: Aug 3–9 | Session A — 45 min read
# Heaviest week of the sprint (~11% of the exam). Archive weeks 1–4 (XK0-005)
# cover permissions/SSH/sudo — skim them for review; the new ground is below.

---

## Objective 2.6 — Containers

### The Runtime Stack — Who Calls Whom

```
Docker CLI / Podman CLI        ← what you type
        ↓
containerd (daemon runtime)    ← manages container lifecycle (Docker's path)
        ↓
runC                           ← low-level: actually creates the namespaced process
```

- **Docker** — client/server: a root daemon (`dockerd`) does everything. The n8n deployment on `dell-fedora` runs this way (conceptual anchor — you won't touch it).
- **Podman** — **daemonless and rootless**: no background service, containers are ordinary child processes of your user. CLI-compatible with Docker (`alias docker=podman` mostly works). This is what Fedora ships and what you'll use.
- A container is not a VM (Week 3): no kernel of its own — it's a process wearing namespaces (isolated PID/net/mount views) and cgroups (resource limits) on the *host's* kernel.

**Rootless consequences (tested, and daily reality on tp-mudd):**
- Container processes appear in host `ps` as **your user**, not root. A "root" process inside the container maps to your unprivileged UID outside (user namespaces).
- Rootless can't bind host ports **below 1024** — that's why labs publish `-p 8080:80`, not `-p 80:80` (kernel line: `net.ipv4.ip_unprivileged_port_start`).
- **Privileged vs unprivileged:** `--privileged` hands the container all capabilities and device access — a container escape waiting to happen; the exam wants "avoid unless required."

### Image Ops and the Dockerfile

| Directive | Meaning | Trap |
|---|---|---|
| `FROM` | Base image — first line of every Dockerfile | — |
| `RUN` | Execute at **build** time (creates a layer) | — |
| `COPY` / `ADD` | Files into the image | ADD also unpacks archives/fetches URLs — prefer COPY |
| `ENV` | Environment variable baked into the image | Overridable at run: `--env` |
| `EXPOSE` | *Documents* a port | Does NOT publish it — `-p` at run time does |
| `USER` | Run as this user from here on | Hardening: don't stay root |
| `ENTRYPOINT` | The fixed executable | Args passed to `run` are **appended** to it |
| `CMD` | Default arguments (or default command if no ENTRYPOINT) | **Replaced entirely** by any args passed to `run` |

ENTRYPOINT + CMD together: `ENTRYPOINT ["echo"]` + `CMD ["default"]` → `podman run img` prints `default`; `podman run img hello` prints `hello`. CMD is the overridable part; ENTRYPOINT is not (short of `--entrypoint`). Guaranteed question.

Images are **layers** — each Dockerfile instruction stacks a read-only layer; containers add one thin writable layer on top (the **overlay** filesystem). `podman history img` shows the stack. `podman image prune` clears dangling layers.

### Container / Volume / Network Ops

```
podman pull docker.io/library/nginx:alpine
podman run -d --name web -p 8080:80 nginx:alpine     # detached + port map
podman ps  /  podman ps -a                           # running / including exited
podman logs web        podman exec -it web sh        # stdout|stderr / shell inside
podman inspect web     podman stop web && podman rm web
podman run --env MODE=test ...                       # env var at runtime
```

- **Volumes:** named (`podman volume create data` → `-v data:/path`) or **bind mount** (`-v /host/dir:/ctr/dir`). On SELinux systems, bind mounts need a label flag: **`:z`** (shared among containers) or **`:Z`** (private to this one) — it relabels the host files `container_file_t`. Forgetting it = "Permission denied" inside the container *with SELinux enforcing* — a 5.4 crossover scenario.
- **Networks:** `bridge` (default — private subnet, NAT out, like libvirt's virbr0 from Week 3), `host` (no isolation, container shares host's stack — no `-p` needed or possible), `none` (no networking), `macvlan`/`ipvlan` (container gets its own address on the physical LAN), `overlay` (multi-host, Swarm/K8s territory).

---

## Objective 3.2 — Firewalls

### firewalld — Zones, and the Runtime/Permanent Split

Zones are trust levels applied **per interface**: `drop`, `block`, `public` (default), `external`, `home`, `internal`, `work`, `dmz`, `trusted` (allow everything).

```
firewall-cmd --get-default-zone
firewall-cmd --get-active-zones               # which interface is in which zone
firewall-cmd --get-zone-of-interface=tailscale0
firewall-cmd --list-all                       # default zone's full ruleset
firewall-cmd --add-port=8080/tcp              # RUNTIME ONLY — gone at reload/restart
firewall-cmd --permanent --add-port=8080/tcp  # CONFIG ONLY — inert until --reload
firewall-cmd --reload                         # load permanent config, DISCARD runtime
firewall-cmd --runtime-to-permanent           # save what's live into config
```

**The split cuts both ways — the #1 firewalld exam trap:**
1. Runtime change without `--permanent` → works now, **vanishes at reload/reboot**.
2. `--permanent` change without `--reload` → written to disk, **does nothing yet**.

**Ports vs services:** `--add-service=https` references a predefined XML definition (port + protocol + helpers); `--add-port=443/tcp` is raw. Services are self-documenting — `--list-all` showing `services: ssh` beats `ports: 22/tcp`. **Rich rules** handle "from this source, allow that": `firewall-cmd --add-rich-rule='rule family=ipv4 source address=100.64.0.0/10 port port=22 protocol=tcp accept'`.

### The Rest of the Firewall Family

- **UFW** (Ubuntu's frontend — exam knowledge, fleet's other boxes use it): `ufw status numbered`, `ufw allow 22/tcp`, `ufw allow ssh` (same ports-vs-services idea), `ufw delete <n>`, `ufw enable`.
- **iptables** — the legacy interface. **Chain flow to memorize:** packet arrives → `PREROUTING` (DNAT happens here) → routing decision → `INPUT` (destined for this host) *or* `FORWARD` (passing through) → locally generated → `OUTPUT` → `POSTROUTING` (SNAT/masquerade here). Default chain **policy** applies when no rule matches.
- **nftables** — iptables' successor and what actually runs underneath firewalld on Fedora; `nft list ruleset` shows the truth. Modern `iptables` binaries are often a compatibility shim over nft.
- **ipset** — named sets of addresses for rules to match ("block this list of 10,000 IPs" = one rule + one set, not 10,000 rules).
- **NAT vocabulary:** **SNAT** rewrites source (LAN → internet, what your router does; masquerade = SNAT with dynamic IP), **DNAT** rewrites destination (port-forwarding in), **PAT** = many internal hosts sharing one IP differentiated by port (how home NAT actually works).
- **`net.ipv4.ip_forward=1`** — the sysctl (Week 5) that lets a box route between interfaces at all. Every NAT/router/exit-node scenario requires it; `mudd-cloud` as your Tailscale exit node has it set (conceptual anchor).
- **Stateful vs stateless:** stateful filters track connections — "allow established/related back in" means you only write rules for the *initiating* direction. Stateless evaluates every packet in isolation (needs explicit rules both ways). firewalld/UFW/iptables-with-conntrack are stateful.

---

## Objective 3.3 — OS Hardening

### sudo — Done Right

- Edit **only** via `visudo` — it syntax-checks before saving; a typo saved raw can lock everyone out of root. Drop-ins live in `/etc/sudoers.d/` (also edit with `visudo -f`).
- `%wheel ALL=(ALL) ALL` — group grant; your account's admin rights come from wheel membership (`id | grep wheel`).
- **NOPASSWD:** convenience, audit-trail intact but no auth friction — flag it when found. **NOEXEC:** blocks granted commands from shelling out (an editor's `:!sh` escape).
- `sudo -i` vs `su -`: both give a root login shell; `sudo -i` authenticates with **your** password and logs the invocation attributed to you; `su -` wants **root's** password. Zero-trust logic: with `su`, the audit trail ends at "someone knew root's password."
- Audit trail on Fedora: `journalctl _COMM=sudo` (there is **no** `/var/log/auth.log` here — that's Debian/Ubuntu; Fedora's file-equivalent is `/var/log/secure`).

### Permissions Refresh + the Sharp Tools

Archive weeks 1–2 covered chmod/chown/SUID/SGID/sticky in depth — review there. New emphasis:

- **umask** — subtracted from defaults (files 666, dirs 777): umask `022` → 644/755. Set per-shell or in `/etc/login.defs`. Exam math: "umask 027 → new file = 640, new dir = 750."
- **`chattr +i file`** — immutable: not even **root** can modify, delete, or rename until `chattr -i`. Not visible in `ls -l` — only `lsattr` reveals it. Scenario: "root can't delete a file, permissions look fine" → immutable attribute. `+a` = append-only (log protection).
- **ACLs** — per-user/group grants beyond owner/group/other: `setfacl -m u:alice:r file`, read with `getfacl`. The tell: `ls -l` shows a **`+`** at the end of the mode string. `setfacl -x` removes an entry, `-b` wipes all ACLs. Mask entry caps the effective rights of named users/groups.

### SELinux — the Type Is the Policy

Context = `user:role:type:level` — for nearly everything you'll do, **type** is what matters (`sshd_config` is `etc_t`... actually `etc_t`; a web root is `httpd_sys_content_t`; container-mounted files are `container_file_t`).

| Command | Role |
|---|---|
| `getenforce` / `setenforce 0|1` | Show / set mode **until reboot** (Permissive still logs, doesn't block) |
| `/etc/selinux/config` | Persistent mode: enforcing / permissive / disabled |
| `ls -Z`, `ps -Z`, `id -Z` | Show contexts on files / processes / you |
| `chcon -t type_t file` | Change context **temporarily** — survives until a relabel |
| `restorecon -v file` | Reset to what policy says it should be |
| `semanage fcontext -a -t type_t '/srv/web(/.*)?'` then `restorecon -R` | **Permanent** custom rule + apply |
| `getsebool -a` / `setsebool -P bool on` | Feature toggles (`-P` = persistent) |
| `ausearch -m AVC -ts today` / `sealert` | Find denials / explain them |
| `audit2allow` | Generate policy from denials (read it, don't blindly apply) |

**The mv/cp context bug (live in this week's lab):** `cp` creates a new file → inherits the *destination directory's* context (usually right). `mv` preserves the *original* context (usually wrong in the new location). "Service can't read a file I moved into its directory, permissions are fine" → `ls -Z`, then `restorecon`.

### SSH Hardening

Effective config the right way: `sudo sshd -T | grep -Ei 'permitrootlogin|passwordauthentication'` — shows what sshd is *actually* enforcing after all includes, not what one file says.

Key `sshd_config` directives: `PermitRootLogin no` | `PasswordAuthentication no` (this fleet's posture — keys only) | `AllowUsers` / `AllowGroups` (allowlist logins) | `X11Forwarding no` (off unless needed). Plus: **SSH tunneling** (`ssh -L 8080:localhost:80 host` forwards a local port over SSH), **ssh-agent** (holds decrypted keys per-session), **SFTP** (file transfer over SSH — the sanctioned replacement for FTP).

### The Rest of 3.3 — Concept Level

- **chroot** — confine a process to a directory subtree as its `/`. Not a security boundary by itself (root escapes chroots); think build environments and sftp jails.
- **fail2ban** — *reads logs*, then inserts firewall bans for repeat offenders. It is not a firewall; it's a log-watcher that drives one.
- **Banned protocols:** Telnet, FTP, TFTP — cleartext credentials. Replacements: SSH, SFTP/FTPS. A question offering telnet as a diagnostic tool is testing whether you'll take the bait; `nc` does the port check.
- **Disable unused filesystems** (blacklist kernel modules like `cramfs` via `/etc/modprobe.d/*.conf` — Week 2's module system as a hardening lever) and **remove unneeded SUID bits** (Week 1's `find -perm -4000` becomes an action item).
- **Secure Boot / UEFI** — firmware verifies bootloader/kernel signatures; unsigned third-party kernel modules won't load with it on (the Week 2 "tainted kernel" connection). `mokutil --sb-state` checks it.

---

## Quick Recall

Podman — daemonless, rootless; containers are your user's processes
Rootless port floor — can't bind below 1024; hence -p 8080:80
`--privileged` — all capabilities; avoid unless unavoidable
EXPOSE documents; `-p` publishes
ENTRYPOINT fixed, CMD replaceable; run args replace CMD, append to ENTRYPOINT
Bind mount on SELinux — `:z` shared / `:Z` private, labels container_file_t
firewalld runtime change — dies at --reload; --permanent change — inert until --reload
`--runtime-to-permanent` — save live state to config
iptables flow — PREROUTING → INPUT|FORWARD; OUTPUT → POSTROUTING; DNAT pre, SNAT post
`net.ipv4.ip_forward=1` — prerequisite for any routing/NAT role
Stateful — track connections, rule the initiating direction only
visudo — syntax-checked sudoers editing; raw edits risk total lockout
`sudo -i` your password + attributed; `su -` root's password + trail ends
`chattr +i` — even root blocked; only lsattr shows it
`ls -l` trailing `+` — ACLs present; read with getfacl
chcon temporary; semanage fcontext + restorecon permanent
mv keeps SELinux context (bug source); cp inherits destination's
fail2ban — log reader that drives firewall bans, not a firewall
