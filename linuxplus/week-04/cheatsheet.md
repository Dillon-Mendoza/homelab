# Week 04 — File Management + Account Management
# Domain: 2.0 Services and User Management (20%) | Objectives: 2.1, 2.2
# Calendar: Jul 20–26 | Session A — 45 min read

---

## Objective 2.1 — Files and Directories

### The Core Utilities — Flags That Actually Get Tested

You use most of these daily. The exam tests the flags you *don't* reach for by habit.

| Command | Exam-relevant usage | Detail worth knowing |
|---|---|---|
| `ls` | `ls -lai` | `-i` shows inode numbers — the key to understanding links below |
| `cp` | `cp -a src dst` | `-a` = archive: preserves permissions, ownership, timestamps, recurses. `cp -r` alone does NOT preserve — copies get your umask |
| `mv` | `mv file dir/` | Within one filesystem, `mv` is a rename — same inode, instant. Across filesystems it's copy+delete — new inode |
| `rm` | `rm -rf` | No trash, no undo. `rmdir` only removes *empty* directories — that restriction is the exam distinction vs `rm -r` |
| `mkdir` | `mkdir -p a/b/c` | `-p` creates parents and doesn't error if the path exists |
| `touch` | `touch -t 202607201200 f` | Creates empty file OR updates timestamps of an existing one — both behaviors are tested |
| `file` | `file /usr/bin/ls` | Identifies type by magic bytes, not extension. `file script.jpg` will happily say "Bourne-Again shell script" |
| `stat` | `stat ~/.bashrc` | Full inode detail: three timestamps, link count, inode number, permissions in octal |
| `diff` / `sdiff` | `diff -u old new` | `sdiff` shows side-by-side. `diff` exit code: 0 = identical, 1 = differ — usable in scripts |
| `locate` | `locate sshd_config` | Reads a prebuilt database (`updatedb`), so it's instant but **stale** — a file created today isn't found until the DB updates. `find` walks the live filesystem |
| `lsof` | `lsof /var/log` | Lists open files by process. The killer use: a deleted file still held open shows `(deleted)` — this is why `df` doesn't drop after you `rm` a huge log |

**The three timestamps (stat output) — a reliable exam question:**
- **atime** — last *access* (read). Often lazily updated on SSDs (`relatime` mount option, Week 2).
- **mtime** — last *content modification*. What `ls -l` shows.
- **ctime** — last *metadata change* (permissions, ownership, link count). **NOT creation time** — Linux traditionally doesn't store creation time. Any answer choice reading ctime as "created" is the trap.

Prove it on any file: `cat` bumps atime, editing bumps mtime (and ctime), `chmod` bumps *only* ctime.

---

### Hard Links vs Symbolic Links — Inode Mechanics

This is the heart of 2.1. Reason from the inode and every question answers itself.

A file's data lives at an **inode**. A filename is just a directory entry pointing at an inode number.

```
ln  target  hardlink      # second directory entry → SAME inode
ln -s target symlink      # NEW inode whose content is a PATH string
```

| Property | Hard link | Symlink |
|---|---|---|
| Inode | Same as target (see `ls -li`) | Its own — stores the target's *path* |
| Cross filesystems? | **No** — inode numbers are per-filesystem | Yes |
| Link to directories? | **No** (would corrupt the tree) | Yes |
| Delete the original → | Still works. Data survives while link count > 0 | **Dangles** — points at a path that no longer resolves |
| Move the original → | Unaffected (inode didn't move) | Breaks if the stored path no longer matches |
| `ls -l` appearance | Indistinguishable from a normal file; link count column > 1 | `lrwxrwxrwx` and `name -> target` |

- The **link count** is field 2 of `ls -l` and appears in `stat`. A regular file starts at 1; each hard link adds 1; deletion decrements. Data blocks are freed only at 0 — *and* when no process holds it open (the `lsof (deleted)` case above).
- Argument order trips people: `ln -s TARGET LINKNAME` — target first. `ln -s` doesn't validate the target; you can create a dangling symlink freely.
- Find broken symlinks: `find /path -xtype l`
- You've been living with symlinks all along: `/etc/resolv.conf` on `tp-mudd` is one (Week 3), and `ls -l /usr/bin | grep '\->'` shows dozens.

---

### Device Types in /dev

First character of `ls -l` output is the type:

| Char | Type | Behavior | Examples on tp-mudd |
|---|---|---|---|
| `b` | Block device | Buffered, random-access, in fixed-size blocks | `/dev/nvme0n1`, the loop devices you built in Week 2 |
| `c` | Character device | Unbuffered byte stream | `/dev/tty`, `/dev/null`, `/dev/kvm` (Week 3) |
| `l` | Symlink | — | `/dev/disk/by-uuid/*` → partitions |

**Special character devices — know the trio:**
- `/dev/null` — discards writes, returns EOF on read. `cmd 2>/dev/null` from Week 1.
- `/dev/zero` — endless zero bytes. Fed every `dd if=/dev/zero` in Week 2's labs.
- `/dev/random` vs `/dev/urandom` — both CSPRNGs; `/dev/random` may block waiting for entropy, `/dev/urandom` never blocks. Modern guidance: use `urandom`; the exam may still test the blocking distinction.

---

## Objective 2.2 — Local Account Management

### /etc/passwd — Seven Fields, Colon-Separated

```
tp-mudd:x:1000:1000:Dillon:/home/tp-mudd:/bin/bash
```

| # | Field | Meaning |
|---|---|---|
| 1 | Username | — |
| 2 | Password | `x` = real hash lives in `/etc/shadow` |
| 3 | UID | What the kernel actually uses — usernames are for humans |
| 4 | GID | **Primary** group |
| 5 | GECOS | Comment / full name |
| 6 | Home | Set at creation; changing it later doesn't move files |
| 7 | Shell | `/bin/bash`, or `/sbin/nologin` / `/usr/sbin/nologin` to deny interactive login |

**UID ranges:** `0` = root (the UID is what grants power — any UID-0 account is root regardless of name). `1–999` = system/service accounts. `1000+` = regular users. Boundaries are set in `/etc/login.defs` (`UID_MIN`).

Count your own system's split: `awk -F: '$3 >= 1000 && $3 < 65000 {print $1}' /etc/passwd`

### /etc/shadow — Nine Fields, Root-Readable Only

```
labuser:$6$rounds...$hash:20655:7:90:7:14:20800:
```

| # | Field | Meaning |
|---|---|---|
| 1 | Username | — |
| 2 | Hash | `$6$`=SHA-512, `$y$`=yescrypt (Fedora default). `!` or `!!` prefix = **locked**. `*` = no password ever set (typical for service accounts) |
| 3 | Last change | Days since 1970-01-01 (epoch days, not a date) |
| 4 | Min | Days that must pass before the user *may* change the password |
| 5 | Max | Days until the password *must* change |
| 6 | Warn | Days of warning before expiry |
| 7 | Inactive | Grace days after expiry before the account locks |
| 8 | Expire | Account expiration date (epoch days) — account, not password |
| 9 | Reserved | — |

**Read aging without decoding epoch math:** `chage -l username` translates every field to English. Set them: `chage -M 90 -m 7 -W 7 user`. Force a password change at next login: `chage -d 0 user` (sets "last changed" to day 0 — instantly expired).

### /etc/group — Primary vs Supplementary

```
labgroup:x:1001:labuser,tp-mudd
```

Fields: name : password (unused) : GID : comma-separated **members**.
Your *primary* group comes from `/etc/passwd` field 4 and does NOT appear next to your name in `/etc/group`. The member list holds *supplementary* memberships only. `id username` shows both resolved.

---

### User and Group Operations

| Task | Command | Trap |
|---|---|---|
| Create user | `useradd -m -c "Name" -s /bin/bash user` | `-m` creates the home dir — on some distros it is NOT default. Always pass it |
| Create with groups | `useradd -m -G wheel,labgroup user` | `-g` sets primary; `-G` sets supplementary |
| Modify groups | `usermod -aG newgroup user` | **`-G` without `-a` REPLACES the entire supplementary list.** The single most-tested flag trap in this objective |
| Change shell | `usermod -s /sbin/nologin user` or `chsh -s /bin/zsh` | `chsh` lets users change their own (from `/etc/shells`) |
| Lock / unlock | `usermod -L` / `-U`, or `passwd -l` / `-u` | Both prepend `!` to the shadow hash — password auth dies, **SSH key auth still works** (keys never consult the hash). Full lockout needs the shell set to `nologin` too |
| Delete user | `userdel -r user` | Without `-r`, home dir and mail spool survive as orphans (findable later with `find / -nouser`) |
| Groups | `groupadd`, `groupmod -n new old`, `groupdel` | `groupdel` fails if it's someone's *primary* group |

**`useradd` vs `adduser` — a live distro difference:** on Fedora (`tp-mudd`), `adduser` is just a symlink to `useradd`. On Debian/Ubuntu, `adduser` is a friendly interactive Perl wrapper (prompts for password, GECOS, copies skel). The exam expects you to know `adduser`/`deluser` as the Debian-family interactive pair. You can watch the difference without leaving this laptop — Ubuntu container, lab Task 2.

**Where defaults come from:**
- `/etc/default/useradd` (view with `useradd -D`) — default shell, home base, skel path
- `/etc/login.defs` — UID_MIN/UID_MAX, PASS_MAX_DAYS, PASS_WARN_AGE, umask policy
- `/etc/skel/` — every file here is copied into a new user's home when `-m` runs. Your `.bashrc` from Week 1 started life as `/etc/skel/.bashrc`

---

### Inspection Commands — Who Is on This System

| Command | Answers | Source |
|---|---|---|
| `id [user]` | UID, primary GID, all groups — the resolved truth | live NSS lookup |
| `groups [user]` | Just the group list | — |
| `whoami` | Effective username | — |
| `who` | Who is logged in now | `/run/utmp` |
| `w` | Who is logged in AND what they're running, plus load average | — |
| `last` | Login history, newest first, including reboots | `/var/log/wtmp` |
| `lastlog` | Most recent login *per account* — spotting never-used accounts | `/var/log/lastlog` |
| `getent passwd user` | Account entry via the **full NSS chain** (Week 3's `nsswitch.conf` — works even if the account comes from LDAP, not the local file) | NSS |

`getent` vs `grep user /etc/passwd`: on a standalone laptop they match. In an enterprise with LDAP/SSSD (objective 3.1, Week 7), only `getent` sees directory accounts. The exam draws this line.

### UID vs EUID — Why passwd Works

Every process has a **real UID** (who you are) and an **effective UID** (what you can do). Normally equal. A **SUID binary** (Week 1's `find / -perm -4000`) runs with EUID = the binary's *owner*: `/usr/bin/passwd` is SUID root, so when you change your own password, the process's EUID is 0 — that's the only reason it can write `/etc/shadow` (mode 000, root-owned). Same story for GID vs EGID with SGID binaries. Scenario phrasing to expect: "a user runs a program that writes a root-owned file — how?" → SUID/EUID.

---

## Quick Recall

Cover the right side. Answer from the left.

`ls -li` — show inode numbers; hard links to one file share an inode
hard link — same inode, same filesystem only, survives deletion of the original
symlink — own inode storing a path; crosses filesystems; dangles when target moves
ctime — metadata change time, NOT creation time
`lsof | grep deleted` — deleted-but-open files still holding disk space
`locate` — instant but stale (updatedb database); `find` — live but slower
`b` vs `c` in ls -l — block (buffered, random-access) vs character (byte stream) device
/etc/passwd field 7 — login shell; `/sbin/nologin` denies interactive login
`x` in passwd field 2 — hash is in /etc/shadow
shadow field 3 — last password change, in days since epoch
`!` prefix on shadow hash — locked; SSH keys still get in unless shell is nologin
`chage -d 0 user` — force password change at next login
`usermod -aG group user` — append supplementary group; forgetting -a replaces the list
`userdel -r` — also removes home dir and mail spool
UID 0 / 1–999 / 1000+ — root / system accounts / regular users
SUID + EUID — process runs with the file owner's effective UID (how passwd writes shadow)
