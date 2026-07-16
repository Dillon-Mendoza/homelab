# Test-Out Answer Key — GRADING USE ONLY
# Dillon: if you're reading this before a test-out, you're grading yourself
# a fake pass. Close it. (Post-test review of missed questions here is fine
# — that's what it's for.)
# Teaching model: grade the REASONING PATH, not keyword match. Half-credit
# where the mechanism is right but a command detail is off; zero where a
# memorized command arrives with wrong reasoning. 8/10 passes.

---

## Week 1

1. Firmware (POST/logo) completed; GRUB loaded but couldn't proceed to a
   kernel — its config/menu stage failed. Check `/boot/grub2/grub.cfg`
   presence + `/etc/default/grub`, regenerate with `grub2-mkconfig`.
2. Most distros' `.bash_profile` explicitly sources `.bashrc` — that's why
   aliases appear. SSH = login shell → `.bash_profile` (or `.profile`)
   loads first; `.bashrc` runs only because it's chained.
3. Error text appears in the SECOND form. Left-to-right: `2>&1` copies
   stderr to the CURRENT stdout (terminal/mail), THEN stdout redirects to
   the file — stderr never follows. First form: stdout→file, then
   stderr→same file.
4. `find /usr -perm -4000 -type f 2>/dev/null` (accept `-perm /4000`;
   `-u+s` also fine. The `2>/dev/null` was asked for — dock if missing.)
5. /proc is a virtual filesystem — runtime kernel state, not stored files.
   Persist via `/etc/sysctl.d/*.conf` (`fs.file-max = 70000`) +
   `sysctl --system` (accept sysctl.conf).
6. (a) `.` is not in PATH → run as `./script`; (b) missing execute bit →
   `chmod +x` (then it can still need ./). Accept shebang/interpreter-
   missing as an alternative second cause with explanation.
7. /etc; /var; /bin (accept /usr/bin note or /sbin discussion); /boot.
8. Fedora: rpm format, dnf + rpm. Ubuntu: deb, apt + dpkg. RPi OS: deb
   (Debian-based), apt + dpkg — the point is RPi OS ≠ its own family.

## Week 2

1. Filesystem resize skipped: `xfs_growfs /mountpoint` (mounted, takes the
   MOUNTPOINT). ext4: `resize2fs /dev/vg0/data`.
2. xfs — it cannot shrink, only grow. ext4 shrinks offline. (btrfs also
   acceptable as the flexible alternative mention.)
3. Disk absent at boot → mount fails → systemd treats fstab mounts as
   required → boot drops to emergency mode. `nofail` lets boot continue.
4. `df -i` shows IUse% 100. Causes: millions of tiny files (mail queues,
   session files, cache spool); a runaway job creating files in a loop.
5. `insmod` loads exactly that file, NO dependency resolution — fails with
   unresolved symbols if the module needs others. `modprobe` resolves deps
   from module directories by name.
6. pvcreate (disk → physical volume) → vgcreate (pool PVs into volume
   group) → lvcreate (carve logical volume) → mkfs (filesystem on LV) →
   mount.
7. RAID0: 8TB, tolerates 0 failures. RAID1 (2×2 mirrors or 4-way—accept
   standard 2-disk-pair reading): 4TB/1 per mirror... grade the classic:
   RAID1 across 4 disks = 2TB usable (all mirrored), tolerates 3;
   RAID5: 6TB, 1; RAID10: 4TB, 1 guaranteed (up to 2 if in different
   mirrors). Accept reasoned variants; the 5 and 10 rows are the graded core.
8. Already-mounted mountpoint (mount -a skips busy targets silently in some
   cases) is weak — prefer: `noauto` option present; wrong/stale UUID;
   typo'd mountpoint dir that verify flags. Accept any two verifiable ones
   (wrong fstype, missing directory, bad UUID).

## Week 3

1. Without slash: `/backup/reports/q3.pdf` (directory itself copied). With
   slash: `/backup/q3.pdf` (contents). `--dry-run` (with -v) previews.
2. `tar -cJvf etc.tar.xz /etc` and `tar -tJvf etc.tar.xz` (accept -t
   without J — tar autodetects on read; J on create is the graded part).
3. `dig google.com` (or nslookup) — isolates DNS resolution; then
   `dig google.com @1.1.1.1` — distinguishes local-resolver failure from
   upstream/zone. Accept `cat /etc/resolv.conf` / `resolvectl status` as
   step 2 with reasoning.
4. Service bound to loopback only — unreachable remotely by design. Fix in
   the service's own config: listen/bind address → 0.0.0.0 or specific
   interface IP (then firewall). Not a firewall problem — dock if answer
   jumps straight to firewall.
5. nsswitch.conf (`hosts:` line) sets ORDER. /etc/hosts is the `files`
   source's data; /etc/resolv.conf points the `dns` source at servers.
6. destroy = hard power-off; domain still defined, state `shut off`;
   `virsh undefine` (+ `--remove-all-storage` for disks) deletes;
   `virsh start webvm` would boot it again right now.
7. `qemu-img convert -f qcow2 -O raw disk.qcow2 disk.raw` then
   `qemu-img info disk.raw`.
8. KVM: kernel module doing hardware-assisted virtualization — needs
   AMD-V/VT-x. QEMU: userspace machine emulator (uses KVM for speed).
   libvirt: management API/daemon. virsh: libvirt's CLI.

## Week 4

1. Hard links reference an inode; inodes are per-filesystem, so linking
   across mount points is impossible. Symlinks store a PATH string — any
   target, any filesystem, even nonexistent.
2. Hard link: same inode; delete removed one name, link count 2→1, data
   remains reachable. Symlink: stored the dead path → dangling, ENOENT.
3. 7 = min days between password changes; 90 = max age; 14 = warning days
   before expiry; 30 = inactive days after expiry before the account locks.
4. Neither "failed" — `passwd -l` only mangles the password hash (blocks
   password auth; SSH keys don't consult it). `nologin` as shell blocks
   INTERACTIVE shells... but SSH key + no PTY-requiring command? Grade the
   intended point: nologin runs at login and refuses — so if key login
   "succeeded," the shell wasn't actually nologin or auth happened without
   shell (SFTP/forced command). Best answers note: to fully block, need
   both + expire; passwd -l is the one that "failed" for key-based access.
5. Distro defaults differ (CREATE_HOME in /etc/login.defs; Debian's
   useradd defaults to no -m, RHEL-family defaults to yes). `useradd -m`.
6. `userdel -r employee` then `find / -user <UID or name> 2>/dev/null`
   (run find BEFORE userdel, or use the numeric UID after — best answers
   note deleted users leave files owned by a bare UID).
7. 0 = root; 350 = system/service account (1–999); 1247 = regular user.
   A second UID-0 IS root regardless of name — classic backdoor;
   `awk -F: '$3==0' /etc/passwd` audits it.
8. `/etc/skel` — files copied at useradd -m time. Drop `.vimrc` into
   /etc/skel (affects future users only, not existing).

## Week 5

1. Zombie is already dead — only its exit-status entry remains; kill
   targets a process that no longer runs. Fix: signal/restart the PARENT
   (so it reaps via wait()); if the parent dies, systemd/init adopts and
   reaps automatically.
2. `*/15 9-17 * * 1-5 /opt/check.sh` (accept 1–5 vs MON-FRI. 9-17
   includes the 17:00–17:45 runs — bonus if noticed and 9-16 argued.)
3. remove deletes binaries, keeps config; purge deletes config too.
   `apt autoremove` clears orphaned dependencies.
4. `dnf history` to find the transaction ID → `dnf history undo <ID>`.
5. Warning: unit file "changed on disk" / run daemon-reload. systemd caches
   parsed unit files; restart used the cached version.
   `systemctl daemon-reload` then restart.
6. disable: not stopped now; won't autostart; manual start WORKS.
   mask: not stopped now (if running); won't autostart; manual start FAILS
   (unit → /dev/null) until unmask.
7. `journalctl -u sshd -b -p err` (order-free; all three flags graded).
8. `nohup nice -n 19 cmd &` (accept setsid/tmux/systemd-run alternatives
   with explanation; nice 19 + survive-hangup are the graded parts).

## Week 6

1. Default firewall-cmd changes are RUNTIME only; reboot restarts firewalld
   from permanent config. `firewall-cmd --add-port=8080/tcp --permanent`
   then `firewall-cmd --reload` (or repeat the runtime add; accept
   `--runtime-to-permanent`).
2. `python3 app.py`; `python3 other.py` (CMD is the overridable args);
   `bash` alone (entrypoint replaced, CMD... note CMD still appended as
   args to new entrypoint unless overridden — full credit for
   "bash app.py" with that reasoning, or bash if they also override cmd).
   Graded core: ENTRYPOINT fixed, CMD default-and-overridable.
3. Unprivileged users can't bind ports <1024 (kernel privileged-port
   rule; rootless podman has no root anywhere to do it). Fixes: map
   higher host port (`-p 8080:80`), lower
   `net.ipv4.ip_unprivileged_port_start`, or run as root/privileged
   (least preferred). Any two.
4. Temp: `chcon -t httpd_sys_content_t file`. Permanent:
   `semanage fcontext -a -t httpd_sys_content_t '/path(/.*)?'` +
   `restorecon -Rv /path`. chcon changes the label only; restorecon resets
   labels to what POLICY says, and chcon never touched policy.
5. PREROUTING → routing decision → INPUT → local process. FORWARD path
   diverges at the routing decision (never touches INPUT), then
   POSTROUTING.
6. First: fix file context (restorecon) — most denials are mislabels.
   Second: boolean (setsebool) — policy already anticipated the toggle.
   Last: audit2allow custom policy — new policy is a maintenance burden
   and can mask a real misconfig. Reasoning graded over order memorized.
7. journald: `journalctl _COMM=sudo` (accept SYSLOG_IDENTIFIER=sudo or
   `journalctl -t sudo`). Ubuntu: `/var/log/auth.log`.
8. `sudo -i`: YOUR password; each command attributable to your user in
   logs. `su -`: ROOT's password; logs show only that someone became root.
   That's why sudo is policy-preferred.

## Week 7

1. Both mark the stack failed on module failure; `required` CONTINUES
   running later modules (uniform timing/behavior), `requisite` returns
   immediately. Immediate return can reveal WHICH check failed (e.g.,
   timing shows user exists vs not) — information leak.
2. `auditctl -w /etc/shadow -p wa -k shadow-watch` then
   `ausearch -k shadow-watch` (accept -f /etc/shadow).
3. Encrypt with the TEAMMATE'S PUBLIC key (only their private decrypts);
   sign with YOUR PRIVATE key (their copy of your public verifies).
4. LUKS2. `cryptsetup luksFormat /dev/sdX` (then luksOpen, mkfs on the
   mapper device). Key slots: up to 8 independent unlock secrets —
   multiple passphrases/keyfiles, addable/revocable without re-encrypting.
5. Backporting. The distro applied the security fix to the OLD version
   number; scanner matched version string, not the patched behavior.
   Verify via changelog (`rpm -q --changelog openssl | grep CVE-...`).
6. Either AIDE's baseline is stale relative to a legitimate change that
   bypassed the package manager — or the binary was replaced maliciously
   (rootkit-class). Immediate: verify against the package DB
   (`rpm -V openssh-server`) and treat as potential compromise until
   proven benign; do NOT just re-baseline.
7. passwd -l blocks password auth only → key-based SSH still works
   (scenario: must block console password login, keep automation keys).
   chage -E 0 expires the ACCOUNT → blocks all auth including keys.
   nologin allows auth but no shell (scenario: SFTP-only or service
   account that must authenticate but never get a shell).
8. rm removes directory entries; blocks remain recoverable. Overwrite:
   `shred` (or badblocks -w / dd from urandom for whole devices — note
   shred's limits on journaling/SSDs if mentioned, bonus). Crypto:
   encrypt-then-destroy-key (LUKS: wipe the header/keyslots).

## Week 8

1. Inside `[ ]`, `>` is shell REDIRECTION: creates a file named `5`,
   test collapses to `[ $COUNT ]` = true if non-empty. Correct:
   `[ "$COUNT" -gt 5 ]` or `[[ $COUNT -gt 5 ]]`.
2. Shape:
   ```bash
   #!/bin/bash
   [[ -z "$1" ]] && { echo "usage: $0 <service>"; exit 2; }
   if systemctl is-active --quiet "$1"; then exit 0; else exit 1; fi
   ```
   Grade: arg check exits 2 BEFORE use; quiet check; explicit codes.
3. `VAR=x cmd`: exists only in that command's environment. `export`:
   this shell + all future children. `local`: this function only.
4. Matches exactly ABC-1234 shape (3 uppercase, dash, 4 digits, anchored
   both ends). Quoting the regex makes it a LITERAL string match — regex
   metacharacters stop working.
5. Unquoted expansion word-splits on IFS — spaces in names become separate
   items (and globbing re-expands). Robust: `for f in *.log` (glob,
   quoted "$f" inside) or `while IFS= read -r f` from find -print0.
6. `python3 -m venv .venv` / `source .venv/bin/activate` /
   `which python pip` (or `pip -V`) / `deactivate`.
7. list (ordered, append cheap); dict (hostname → data, O(1) lookup);
   tuple or frozenset for constant valid states — accept set with
   "shouldn't change" caveat; best answer names immutability as the
   reason for tuple/frozenset.
8. The print landed at a different indent level (or mixed tabs/spaces),
   changing block structure. Python's blocks ARE indentation — there are
   no braces/keywords to disambiguate, so wrong indent = syntax error,
   not style.

## Week 9

1. Committed locally but never pushed (or committed on another branch).
   `git log origin/main..HEAD --oneline` (accept `git status` showing
   "ahead by N" after fetch).
2. `git rebase -i HEAD~3` marking two as squash; or
   `git reset --soft HEAD~3 && git commit` (accept `git merge --squash`
   onto a clean branch).
3. Their history diverged from rewritten upstream: pull produces
   conflicts/duplicate commits; force-push made their base vanish. Rule:
   never rebase published/shared history.
4. soft: staged. mixed: in working tree, unstaged. hard: gone.
5. The file was already TRACKED before the ignore rule; .gitignore only
   hides untracked files. `git rm --cached prod.env` then commit (file
   stays on disk).
6. Not necessarily an error, but a smell: those three tasks aren't
   idempotent — likely `command`/`shell` modules doing imperative work.
   Investigate; use state-declaring modules or add changed_when/creates.
7. Ansible: agentless, push over SSH, YAML. Puppet: agent, pull from
   server (catalog), Ruby DSL. Agent-prohibited environment → Ansible.
8. Any three: read every line and explain it; test in a sandbox/DRY_RUN;
   check inputs/edge cases (unset vars, spaces, failures); lint
   (shellcheck); verify commands/flags exist against man pages.
   Governance: no secrets/proprietary data into external prompts (accept
   corporate-policy/local-model points).

## Week 10

1. Test the theory BEFORE planning/implementing: establish theory (DNS) →
   TEST it — e.g., `dig app-host` vs `dig app-host @1.1.1.1` vs `getent
   hosts app-host` during a failure window; only after confirmation:
   plan, implement, verify, document. Grade: they must name testing as a
   distinct gate, not jump hunch→fix.
2. 99.5% = SLA (contract, penalties); 99.9% = SLO (internal target);
   99.93% = SLI (measured indicator). Buffer: SLO stricter than SLA, and
   currently SLI ≥ SLO ≥ SLA — healthy.
3. ExecStart cannot be executed — wrong path/missing binary/no exec
   permission (203/EXEC is systemd's exec-failure code, not the app's).
   `systemctl cat app` (read ExecStart) → `systemd-analyze verify
   app.service` (accept journalctl -u app as one of the two).
4. Deleted files with open file descriptors keep their blocks until the
   holder closes/exits. Detect: `lsof +L1`. Free: restart/signal the
   holding process; or truncate in place (`: > /proc/<pid>/fd/<n>` or
   truncate the file BEFORE rm next time — logrotate copytruncate).
5. I/O-bound system: processes in D-state inflate load while CPU idles;
   wa 40% + b 6 = disk is the bottleneck. Opposite (us 95, wa 0) =
   genuinely CPU-bound — more/faster cores or nice, not disk work.
6. Refused instantly = host reachable, nothing listening on 8443 (or RST
   from a rejecting firewall) — service/bind problem. Timeout from
   elsewhere = packets dropped in path — filtering firewall or routing;
   the service may be fine. Together: check bind address + intermediate
   firewall, not just the daemon.
7. MTU/fragmentation (link layer between them — tunnels/VPN are classic).
   `ping -M do -s 1472 <peer>`: don't-fragment flag with payload sized so
   1472+28 (IP+ICMP headers) = 1500; failure at that size with success
   smaller localizes the MTU ceiling.
8. Kernel log: `journalctl -k -g -i 'out of memory'` (OOM killer chose
   it under memory pressure — score = badness heuristic). Early warning:
   vmstat si/so sustained nonzero (swapping) or /proc/pressure/memory
   some avg10 climbing; `free` available shrinking.
