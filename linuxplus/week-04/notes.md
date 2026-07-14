# Week 04 — Reference Notes
# Objectives: 2.1, 2.2 | Calendar: Jul 20–26

---

## Exam Objective Mapping

**2.1 — Given a scenario, manage files and directories on a Linux system**
- Utilities: `ls`, `cp`, `mv`, `rm`, `mkdir`, `rmdir`, `find`, `locate`, `stat`, `lsof`, `ln`, `diff`, `sdiff`, `file`, `touch`, `pwd`, `cd`
- Links: symbolic (soft) vs. hard — when each breaks
- Device types in `/dev`: block, character, special character devices

**2.2 — Given a scenario, perform local account management in a Linux environment**
- User ops: `useradd`, `adduser`, `usermod`, `userdel`, `deluser`
- Group ops: `groupadd`, `groupmod`, `groupdel`
- Password/locking: `passwd`, `chage`, `usermod -L/-U`, `chsh`
- Account files: `/etc/passwd`, `/etc/shadow`, `/etc/group` — every field
- Templates: `/etc/skel`, `/etc/profile`
- Inspection: `id`, `groups`, `who`, `w`, `whoami`, `last`, `lastlog`, `getent passwd`
- UID ranges; UID vs. EUID, GID vs. EGID; user vs. system vs. service accounts

---

## Key Man Pages

`man 5 shadow` — the field reference the exam draws from. Read the paragraph on each aging field once; the lab's `chage -l` output will map onto it exactly. Note what an empty field vs. `0` vs. `-1` means — that nuance shows up in scenarios.

`man 5 passwd` — short. Confirms the seven fields and what an `x` in field 2 delegates to shadow. Section 5 (file format), not section 1 (the command).

`man useradd` — read the `-D` section and the FILES list at the bottom: it names `/etc/default/useradd`, `/etc/login.defs`, and `/etc/skel` as the three sources of defaults, which is the mental model behind "where did this new account's settings come from?"

`man chage` — one page, every flag. Pay attention to `-E` (account expiry, a date) vs `-M` (password max age, a count of days) — the lab's break-it/fix-it turns on that distinction.

`man ln` — the first two paragraphs state the hard-link restrictions (no directories, no cross-filesystem) with the reason. Also see `man 7 inode` if the link-count mechanics don't feel solid after Task 5.

---

## Video Timestamps

**Theory Course (12hr — nGPK6YBbKpg):**
Domain 2 starts here — look for "File Management" (covers 2.1: utilities, links, /dev types) followed by "User and Group Management" (2.2: account files, useradd/usermod, chage). They typically run back-to-back at the start of the Domain 2 block, right after Domain 1's virtualization section from last week.

**Labs Course (7hr — JXIaR23OdB8):**
Look for the user-management lab segment — it walks the create/modify/lock/delete lifecycle live, the same arc as lab Tasks 2–4 and 8. If there's a links/inodes demo, it pairs with Task 5; watch it *after* doing the task yourself, as confirmation rather than preview.

---

## Book Reference — How Linux Works, 3rd Ed. (Ward)

**Ch. 4 — Disks and Filesystems (inode section)**
You read this chapter for Week 2's storage stack; go back for the inode discussion specifically. It explains what an inode actually stores (metadata + block pointers, *not* the filename) and why the filename is just a directory entry. Once that clicks, every row of the hard-vs-symlink table stops being memorization — read it before Session B if links still feel like rules instead of mechanics.

**Ch. 7 — System Configuration (users section)**
Covers `/etc/passwd` and `/etc/shadow` from the system's point of view — how login actually consults these files, where PAM sits in that path (previewing Week 7), and why the password moved out of passwd into shadow historically. Read before Session A.

**Ch. 13 — User Environments**
Already assigned in Week 1 for `.bashrc` vs `.bash_profile`; this week its `/etc/skel` and startup-file material lands again with more context — skim the startup-files section after lab Task 2d, where you diff a fresh home against skel.

---

## Things That Trip People Up

**1. `usermod -G` without `-a` replaces every supplementary group**
The single most-tested flag in this objective. `-G wheel` doesn't *add* wheel — it makes wheel the *entire* supplementary list. Lab Task 2f makes you do the damage and repair it; that memory is the answer to at least one exam question.

**2. A locked account is not a closed door**
`passwd -l` / `usermod -L` prepend `!` to the shadow hash — password auth fails, but SSH public-key auth never reads that hash and sails through. Full lockout = lock the password AND set the shell to `/sbin/nologin` (or use `chage -E` to expire the account outright). On this fleet, where every box is key-auth-only, the "locked" state alone would block nothing — that's not hypothetical for you.

**3. ctime is change time, not creation time**
`stat` shows atime/mtime/ctime. ctime updates on metadata changes (chmod, chown, link count). Classic wrong-answer bait: "use ctime to find when the file was created." Linux doesn't reliably expose creation time at all (some filesystems store a birth time, `stat` calls it `Birth`, but the exam wants the ctime distinction).

**4. `useradd` vs `adduser` is a distro question in disguise**
Fedora: `adduser` is a symlink to `useradd` — identical. Debian/Ubuntu: `adduser` is an interactive wrapper that prompts and applies sane defaults, and `deluser` mirrors it. If a question shows interactive prompts during account creation, the answer is the Debian-family `adduser`.

**5. `userdel` without `-r` leaves a haunted house**
Home directory and mail spool survive, now owned by a raw UID with no name. `find / -nouser` finds them. Worse: if a new user later gets the recycled UID, they silently inherit ownership of the old files. This chain (delete → orphans → UID reuse) is a scenario-question favorite.

**6. `chage -E` vs `chage -M` — two different "expired" states**
`-E` expires the *account* on a calendar date (shadow field 8). `-M` ages the *password* out after N days (field 5). An expired password prompts for a new one; an expired account refuses login entirely. Lab Task 8's fault is `-E` — the fix for one does nothing for the other.

---

## Connect to the Homelab

Everything this week describes the laptop you're sitting at. `tp-mudd`'s own `/etc/passwd` is the study material: one regular account (UID 1000) on top of dozens of package-installed service accounts — `sshd`'s privilege-separation user, `chrony`, `systemd-network` — every one shipped with `/sbin/nologin` and a `*` password field, which is objective 2.2's "user vs. system vs. service accounts" as a live inventory rather than a definition. The SSH-key trap (gotcha #2) is your actual security posture: this fleet is key-auth-only by design, so the difference between "password locked" and "actually unable to log in" is a distinction your own threat model depends on, not trivia. Symlinks are already load-bearing on this machine — `/etc/resolv.conf` pointing into systemd-resolved's runtime directory (Week 3) is the exam's "what happens when a symlink's target changes" question deployed in production. And the audit script earns its keep beyond the exam here: run it after any package install that adds a service account, and the UID-0/duplicate-UID/shell checks become a real security baseline for the machine that administers the rest of your fleet.
