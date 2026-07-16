# Test-Out Question Bank — Weeks 1–10
# FOR THE TEACHING MODEL. Dillon: reading ahead defeats the gate you built.
# Usage (per TEACHING.md): draw ~6 per test-out, add 2–4 fresh same-style
# variants, grade against test-out-answer-key.md. Mix is ~60% scenario.

---

## Week 1 — Fundamentals + Shell (1.1, 1.5)

1. A system powers on, shows the vendor logo, then drops to a `grub>` prompt.
   Which boot stage failed, which completed, and what config would you check
   after booting from rescue media?
2. `ssh` into a server: your aliases from `.bashrc` work. A teammate says
   that proves `.bashrc` runs for login shells. What's actually happening on
   most distros, and which file loads first for an SSH session?
3. Script contains: `backup.sh > /var/log/bk.log 2>&1` vs
   `backup.sh 2>&1 > /var/log/bk.log`. A cron email contains error text in
   one case and not the other. Which, and why?
4. You need every SUID binary under /usr owned by root, without errors from
   unreadable dirs cluttering output. Write the command.
5. `echo 70000 > /proc/sys/fs/file-max` fixes an issue; after reboot it's
   back. Why, and what's the persistent method?
6. A user reports `command not found` for a script that `ls` shows exists in
   their current directory. Two distinct causes — name both and the fix for each.
7. Which directories: host-specific config; variable data like logs and
   spools; essential binaries needed in single-user mode; kernel and
   bootloader files?
8. Your fleet runs Fedora, Ubuntu Server, and Raspberry Pi OS. For each:
   package format and the two package tools (high-level + low-level).

## Week 2 — Hardware + Storage (1.2, 1.3)

1. You ran `lvextend -L +5G /dev/vg0/data` and `df -h` still shows the old
   size. Filesystem is xfs. What was missed, exact command, and what would
   it have been on ext4?
2. Planning storage: one 50GB volume must SHRINK to 30GB next quarter.
   Which filesystem choice does this rule out, and why?
3. An fstab entry for a USB backup disk lacks `nofail`. Describe the failure
   scenario, including what the boot process does.
4. `mkdir: No space left on device` — but `df -h` shows 40% used. Diagnose:
   the command that confirms it and two situations that create it.
5. A NIC needs module `r8169`. Difference between `insmod r8169.ko` and
   `modprobe r8169` — and which one fails in what common situation?
6. Order these into the correct LVM build sequence and name what each layer
   is: `vgcreate`, `mkfs`, `pvcreate`, `lvcreate`, `mount`.
7. RAID: 4×2TB disks. Usable capacity and failure tolerance for RAID 0, 1,
   5, 10.
8. `mount -a` returns nothing but a new fstab entry didn't mount, and
   `findmnt --verify` flags it. Name two distinct fstab mistakes that
   behave this way.

## Week 3 — Networking + Backup + Virtualization (1.4, 1.6, 1.7)

1. `rsync -avz /data/reports /backup/` vs `rsync -avz /data/reports/ /backup/`
   — resulting paths of a file `q3.pdf` under each, and which flag would
   have shown you before it happened?
2. You must archive `/etc` compressed with xz, then verify contents without
   extracting. Both commands.
3. A server "can't reach the internet": `ping 1.1.1.1` works, `ping
   google.com` fails. Next TWO commands, in order, and what each isolates.
4. `ss -tulpn` output shows `127.0.0.1:5678` for a service users need to
   reach remotely. What's wrong and where do you fix it?
5. Which changes hostname resolution ORDER system-wide — /etc/hosts,
   /etc/resolv.conf, or /etc/nsswitch.conf? What do the other two do?
6. `virsh destroy webvm` — a junior says the VM is deleted forever. What
   actually happened, what deletes it, and what state is `webvm` in now?
7. Convert `disk.qcow2` to raw for a hypervisor migration, then confirm the
   result's format. Both commands.
8. KVM vs QEMU vs libvirt vs virsh — one line each, and which piece requires
   CPU virtualization extensions.

## Week 4 — Files + Accounts (2.1, 2.2)

1. `ln /data/file /backup/file` fails with "Invalid cross-device link" but
   `ln -s` succeeds. Explain both behaviors.
2. Original file deleted. The hard link still shows content; the symlink
   errors. Explain via inodes and link count.
3. Read this shadow line: `svc1:$6$...:19900:7:90:14:30::` — what do 7, 90,
   14, and 30 control?
4. New account can't log in interactively; `/etc/passwd` shows shell
   `/sbin/nologin` and `passwd -S` says `LK`. SSH key login still succeeds.
   Which of the two settings failed at its job, and what does each actually
   block?
5. `useradd batch1` on one distro created a home dir; the same command on
   another didn't. Why, and the flag that removes the ambiguity?
6. A departed employee: remove the account AND home dir AND find every file
   they owned elsewhere on the system. Commands.
7. UID 0, UID 350, UID 1247 — classify each, and explain why a second UID-0
   account is a red flag worth auditing for.
8. Where do the default files in a new user's home come from, and how would
   you make every future user get a default `.vimrc`?

## Week 5 — Processes + Software + systemd (2.3, 2.4, 2.5)

1. `ps` shows a process in state `Z` for days. A teammate runs `kill -9` on
   it repeatedly. Why does nothing happen, and what's the actual fix?
2. Write the crontab line: every 15 minutes during business hours (9–17),
   weekdays only, run `/opt/check.sh`.
3. `apt remove nginx` vs `apt purge nginx` — difference, and which followup
   removes the no-longer-needed dependencies?
4. A bad `dnf` transaction pulled in 40 packages an hour ago. Undo it
   without listing packages manually.
5. You edited `/etc/systemd/system/app.service` and ran
   `systemctl restart app` — the old ExecStart still runs, and `status`
   shows a warning. What warning, why, and the missing step?
6. `systemctl disable nginx` — is it stopped now? Will it start on boot?
   Will `systemctl start nginx` work? Same three answers for `mask`.
7. Show only error-and-worse messages from the sshd unit since the last
   boot, one command.
8. A process must survive your SSH session ending AND run at lowest
   scheduling priority. One command line.

## Week 6 — Containers + Firewalls + Hardening (2.6, 3.2, 3.3)

1. `firewall-cmd --add-port=8080/tcp` works; after a server reboot the port
   is closed. Why, and the two-command sequence that makes it stick without
   waiting for a reload window?
2. In a Dockerfile, `ENTRYPOINT ["python3"]` and `CMD ["app.py"]`. What runs
   with `docker run img`? With `docker run img other.py`? With
   `--entrypoint bash`?
3. A rootless Podman container can't bind port 80. Why (mechanism, not just
   "permissions"), and two distinct resolutions.
4. `ls -Z` on a web file shows `user_home_t` instead of `httpd_sys_content_t`;
   Apache 403s despite mode 644. Fix it temporarily; fix it permanently.
   Why does the temporary fix not survive a `restorecon`?
5. Packet arrives destined for the local machine. Order the iptables chains
   it traverses. Where would a FORWARDed packet diverge?
6. SELinux is blocking a legitimate app behavior. Order these responses from
   first-resort to last: write custom policy with audit2allow, toggle a
   boolean, fix the file context. Justify the order.
7. On Fedora there's no `/var/log/auth.log`. Where do sudo events go, and
   the command to see them? Where WOULD they be on Ubuntu?
8. Compare `sudo -i` and `su -` in exactly two dimensions: whose password,
   and what gets logged.

## Week 7 — Auth + Hardening + Crypto + Compliance (3.1, 3.4, 3.5, 3.6)

1. In a PAM stack, difference between `required` and `requisite` when a
   module FAILS — and why might `requisite` leak information to an attacker?
2. Watch all writes and attribute changes to `/etc/shadow` with auditd; then
   find resulting events. Both commands.
3. You must encrypt `report.pdf` so ONLY a teammate can read it, and they
   must be able to prove it came from you. Which keys are used for which
   operation?
4. A laptop needs full-disk-style encryption on a data partition. Name the
   technology, the format command, and what "key slots" let you do.
5. A scanner reports OpenSSL as vulnerable-by-version on a fully patched
   RHEL system. Explain the likely false positive in one word plus two
   sentences.
6. AIDE ran clean yesterday; today it flags `/usr/bin/sshd` checksum changed
   with no package update in dnf history. Interpretation, and immediate
   next step?
7. Difference between an account locked via `passwd -l`, expired via
   `chage -E 0`, and shell-restricted via `nologin` — one scenario each
   where only that one blocks access.
8. Media disposal: why is `rm -rf` insufficient, and name two acceptable
   approaches (one overwrite-based, one crypto-based).

## Week 8 — Bash + Python (4.2, 4.3)

1. `if [ $COUNT > 5 ]` behaves as always-true and a file appears in the
   CWD. Explain both symptoms and write the two correct forms.
2. A script must exit 2 when no argument is given, 1 when the service is
   inactive, 0 when active. Sketch it in ≤8 lines.
3. Difference between `VAR=x cmd`, `export VAR=x`, and `local VAR=x` —
   scope of each.
4. `[[ "$input" =~ ^[A-Z]{3}-[0-9]{4}$ ]]` — what matches, and what breaks
   if you quote the regex?
5. Why does `for f in $(ls *.log)` break on filenames with spaces, and
   what's the robust loop?
6. venv workflow: create, activate, prove which python/pip are active,
   leave. Four commands.
7. Python: you need an ordered collection you'll append to; a lookup by
   hostname; a constant set of valid states. Pick types and justify.
8. A Python script dies with `IndentationError` after a teammate's edit
   "that only added a print." What likely happened, and why is this a
   syntax error in Python when it wouldn't be in bash?

## Week 9 — Automation + Git + AI (4.1, 4.4, 4.5)

1. `git status` shows `nothing to commit`, but a teammate says your fix
   isn't on the remote. Reconstruct what you forgot, and the command that
   shows commits you have that origin/main doesn't.
2. Three commits of WIP need to become one clean commit before pushing the
   branch. Two different command paths.
3. You rebased a branch someone else had already pulled. Describe what they
   experience and state the rule that was broken.
4. `git reset --soft HEAD~1` vs `--mixed` vs `--hard`: after each, where are
   the changes from the undone commit?
5. `.gitignore` contains `*.env` yet `prod.env` still shows in `git status`
   as modified. Why, and the fix that keeps the local file?
6. Ansible ran a playbook twice; second run shows `changed=3`. Is this a
   problem? What does it suggest about those three tasks?
7. Ansible vs Puppet on three axes: agent model, transport/direction,
   language. Which fits an environment where installing agents is
   prohibited?
8. An AI-generated script "works on the happy path." Per objective 4.5,
   name three concrete review steps before it touches production, and one
   data-governance rule for using the AI at all.

## Week 10 — Troubleshooting (5.1–5.5)

1. Users report intermittent app failures. You have a hunch it's DNS. Per
   the methodology, what must happen between "hunch" and "change a config"
   — name the steps and one concrete test for this case.
2. Contract guarantees 99.5% uptime with penalties; team targets 99.9%;
   dashboard shows 99.93% this month. Label each number and state which
   direction the buffer runs.
3. `systemctl status app` → `Active: failed ... status=203/EXEC`. What
   class of problem is certain, and the two-command diagnosis path?
4. Disk 100% full per df; deleted 8GB of logs; df unchanged. Mechanism,
   detection command, and two ways to actually free the space.
5. Load average 14 on a 4-core box; `vmstat` shows `us` 3%, `id` 90%,
   `b` 6, `wa` 40%. Diagnose. What would OPPOSITE numbers (us≈95, wa≈0)
   have meant?
6. `curl https://svc:8443` → instant "connection refused" from one client;
   from another network it hangs then times out. What does each result
   prove about the path and the service?
7. Small pings to a peer succeed; scp of a large file stalls at 0%. Suspect
   layer, the diagnostic ping invocation, and why 1472.
8. A process vanished overnight; no app logs. Where's the evidence if the
   kernel killed it, what triggered it, and which metric would have warned
   you (name the vmstat columns or the PSI file)?
