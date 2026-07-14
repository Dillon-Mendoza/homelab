#!/bin/bash
# Week 04 — File Management + Account Management
# Objectives: 2.1, 2.2
# Run on: tp-mudd only — fully self-contained, no other devices required
# Estimated time: 45–60 min
#
# Creates a disposable user (labuser) and group (labgroup). Task 8 removes
# them completely — run it even if you stop early.

DRY_RUN=true  # Set to false to execute. true echoes commands instead of running them.

run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 04 Lab — File Management + Account Management"
echo "  Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN"
echo "════════════════════════════════════════════════════════"
echo ""

# ── TASK 1: Read the Account Databases Raw ────────────────────────────────────
# Why it matters: Objective 2.2 — the exam shows you passwd/shadow lines and
# asks what a field means. Decode real lines from your own system first.
echo "── TASK 1: passwd / shadow / group, Read by Hand ──"

echo ""
echo "[1a] Your own passwd entry — name each of the 7 fields out loud before moving on:"
run_cmd "getent passwd \$USER"

echo ""
echo "[1b] Your shadow entry (root-only file — note its permissions first):"
run_cmd "ls -l /etc/shadow"
run_cmd "sudo getent shadow \$USER"
echo "  Field 3 is days-since-1970. Sanity-check it: "
run_cmd "echo \$(( \$(date +%s) / 86400 )) '<- today in epoch days'"

echo ""
echo "[1c] How many REGULAR users does this laptop have vs system accounts?"
echo "  PREDICT FIRST, then:"
run_cmd "awk -F: '\$3 >= 1000 && \$3 < 65000 {print \$1, \$3}' /etc/passwd"
run_cmd "awk -F: '\$3 < 1000 {c++} END {print c \" system accounts\"}' /etc/passwd"

echo ""
echo "[1d] How many accounts CANNOT log in interactively (nologin/false shells)?"
run_cmd "awk -F: '\$7 ~ /(nologin|false)/ {c++} END {print c}' /etc/passwd"
echo "  ^ Every one of those is a service account — user vs system vs service in the flesh."

echo ""

# ── TASK 2: Create a Group and User the Exam Way ─────────────────────────────
# Why it matters: Objective 2.2 — useradd flags are tested directly, and
# watching /etc/skel populate a new home makes the template concept concrete.
echo "── TASK 2: Group + User Creation ──"

echo ""
echo "[2a] What will useradd do before you ask it? Read the defaults:"
run_cmd "useradd -D"
run_cmd "grep -E '^(UID_MIN|PASS_MAX_DAYS|PASS_WARN_AGE)' /etc/login.defs"

echo ""
echo "[2b] Create the group, then the user: home dir, comment, shell, supplementary group:"
run_cmd "sudo groupadd labgroup"
run_cmd "sudo useradd -m -c 'Week04 Lab User' -s /bin/bash -G labgroup labuser"
run_cmd "sudo passwd labuser"

echo ""
echo "[2c] Verify all three databases picked it up — find labuser in each:"
run_cmd "getent passwd labuser"
run_cmd "sudo getent shadow labuser"
run_cmd "getent group labgroup"
echo "  ^ Note: labuser appears in labgroup's member list (supplementary), but their"
echo "  PRIMARY group 'labuser' comes from passwd field 4 — it is NOT listed in group's members."

echo ""
echo "[2d] Prove /etc/skel is the template — the new home should mirror it:"
run_cmd "ls -la /etc/skel/"
run_cmd "sudo ls -la /home/labuser/"
run_cmd "sudo diff -r /etc/skel /home/labuser && echo 'IDENTICAL — skel copied verbatim'"

echo ""
echo "[2e] The resolved truth about the new account:"
run_cmd "id labuser"

echo ""
echo "[2f] THE flag trap — add a group WITHOUT -a and watch the damage, then fix it:"
run_cmd "sudo groupadd secondgroup"
run_cmd "sudo usermod -G secondgroup labuser"
run_cmd "id labuser"
echo "  ^ labgroup is GONE — -G alone replaced the whole supplementary list."
run_cmd "sudo usermod -aG labgroup labuser"
run_cmd "id labuser"
echo "  ^ -aG appends. Burn this in: it is the most-tested usermod detail."

echo ""
echo "[2g] OPTIONAL — the Debian-family contrast without leaving this laptop:"
echo "  On Fedora, adduser IS useradd:"
run_cmd "ls -l /usr/sbin/adduser"
echo "  On Ubuntu it's an interactive wrapper — see for yourself in a container:"
echo "    podman run --rm -it docker.io/library/ubuntu:24.04 bash"
echo "    apt-get update -qq && apt-get install -y adduser >/dev/null; adduser demo"
echo "  (walks you through prompts — that interactivity is the exam distinction)"

echo ""

# ── TASK 3: Password Aging ────────────────────────────────────────────────────
# Why it matters: Objective 2.2 — chage flags map 1:1 to shadow fields 3–8.
# Setting them and re-reading the raw shadow line closes the loop.
echo "── TASK 3: Password Aging with chage ──"

echo ""
echo "[3a] Baseline aging state, human-readable:"
run_cmd "sudo chage -l labuser"

echo ""
echo "[3b] Policy: max 90 days, min 7, warn 7 — then re-read:"
run_cmd "sudo chage -M 90 -m 7 -W 7 labuser"
run_cmd "sudo chage -l labuser"

echo ""
echo "[3c] Now the raw line — map each number back to a chage -l row:"
run_cmd "sudo getent shadow labuser"
echo "  fields: name:hash:lastchg:MIN(7):MAX(90):WARN(7):inactive:expire:"

echo ""
echo "[3d] Force a password change at next login and see what it did to field 3:"
run_cmd "sudo chage -d 0 labuser"
run_cmd "sudo getent shadow labuser | cut -d: -f1-4"
echo "  ^ last-change = 0 means 'changed on day zero of 1970' — instantly expired."
run_cmd "sudo chage -d now labuser"
echo "  (reset so Task 4's su test isn't blocked by the forced change)"

echo ""

# ── TASK 4: Locking — and the SSH-Key Trap ────────────────────────────────────
# Why it matters: Objective 2.2 + exam gotcha — a locked password does NOT
# block key-based SSH. You'll watch the lock hit the hash, reason about why
# keys bypass it, and apply the real fix (nologin shell).
echo "── TASK 4: Account Locking ──"

echo ""
echo "[4a] Hash before, lock, hash after — watch the ! prefix appear:"
run_cmd "sudo getent shadow labuser | cut -d: -f1-2"
run_cmd "sudo usermod -L labuser"
run_cmd "sudo getent shadow labuser | cut -d: -f1-2"

echo ""
echo "[4b] Password auth is now dead — prove it (expect failure):"
run_cmd "su - labuser -c 'whoami' || echo 'su FAILED — password auth blocked, as expected'"

echo ""
echo "[4c] THINK, don't run: if labuser had a key in ~/.ssh/authorized_keys, would"
echo "     'ssh labuser@localhost' still work right now? Answer before reading on."
echo "  YES — key auth never consults the password hash. The ! only breaks passwords."

echo ""
echo "[4d] The complete lockout — kill the shell too, then watch even root's su bounce:"
run_cmd "sudo usermod -s /sbin/nologin labuser"
run_cmd "sudo su - labuser || true"
echo "  ^ 'This account is currently not available' — nologin runs instead of bash."

echo ""
echo "[4e] Restore both (unlock + shell) for the remaining tasks:"
run_cmd "sudo usermod -U -s /bin/bash labuser"
run_cmd "getent passwd labuser | cut -d: -f1,7"

echo ""

# ── TASK 5: Links and Inodes ──────────────────────────────────────────────────
# Why it matters: Objective 2.1 — the delete-the-original experiment is the
# whole hard-vs-symlink distinction in three commands.
echo "── TASK 5: Hard Links vs Symlinks ──"

SCRATCH="/tmp/week04-links"
run_cmd "mkdir -p $SCRATCH && cd $SCRATCH || exit 1"

echo ""
echo "[5a] One file, one hard link, one symlink — compare inodes and link counts:"
run_cmd "echo 'original content' > $SCRATCH/original.txt"
run_cmd "ln $SCRATCH/original.txt $SCRATCH/hard.txt"
run_cmd "ln -s original.txt $SCRATCH/soft.txt"
run_cmd "ls -li $SCRATCH/"
echo "  ^ original + hard: SAME inode, link count 2. soft: own inode, l type, -> arrow."

echo ""
echo "[5b] Edit through the hard link — the 'other' file changes too (same inode):"
run_cmd "echo 'appended via hard link' >> $SCRATCH/hard.txt"
run_cmd "cat $SCRATCH/original.txt"

echo ""
echo "[5c] PREDICT FIRST: delete original.txt — what happens to each link? Then:"
run_cmd "rm $SCRATCH/original.txt"
run_cmd "cat $SCRATCH/hard.txt && echo '-- hard link: fine (link count dropped 2->1)'"
run_cmd "cat $SCRATCH/soft.txt || echo '-- symlink: DANGLING (its stored path resolves to nothing)'"

echo ""
echo "[5d] Find broken symlinks the exam way:"
run_cmd "find $SCRATCH -xtype l"

echo ""
echo "[5e] Try to hard-link across filesystems (into /tmp if it's tmpfs, else use /boot):"
run_cmd "findmnt -no FSTYPE /tmp /home"
run_cmd "ln /home/tp-mudd/.bashrc $SCRATCH/cross.txt || echo 'FAILED: Invalid cross-device link — inodes are per-filesystem'"
echo "  (If /tmp and /home share a filesystem this succeeds — read the findmnt output"
echo "   above and explain which outcome you got and why. Both are instructive.)"

echo ""

# ── TASK 6: stat, lsof, and the Timestamp Trio ────────────────────────────────
# Why it matters: Objective 2.1 — ctime ≠ creation time, and lsof's (deleted)
# state explains a classic real-world mystery: disk full but nothing to delete.
echo "── TASK 6: File Inspection Deep Dive ──"

echo ""
echo "[6a] Three timestamps — cause each one to change in isolation:"
run_cmd "echo data > $SCRATCH/ts.txt && stat -c 'atime=%x%nmtime=%y%nctime=%z' $SCRATCH/ts.txt"
run_cmd "sleep 1 && cat $SCRATCH/ts.txt > /dev/null && stat -c 'after read:  atime=%x' $SCRATCH/ts.txt"
run_cmd "sleep 1 && echo more >> $SCRATCH/ts.txt && stat -c 'after write: mtime=%y' $SCRATCH/ts.txt"
run_cmd "sleep 1 && chmod 640 $SCRATCH/ts.txt && stat -c 'after chmod: mtime=%y%nafter chmod: ctime=%z' $SCRATCH/ts.txt"
echo "  ^ chmod moved ONLY ctime. ctime = metadata change. Nothing here is 'creation'."

echo ""
echo "[6b] The deleted-but-open file — recreate the 'df is full but I deleted the log' case:"
run_cmd "tail -f $SCRATCH/ts.txt & TAILPID=\$!; sleep 1; rm $SCRATCH/ts.txt; lsof -p \$TAILPID | grep deleted; kill \$TAILPID"
echo "  ^ The file is gone from ls, but lsof shows (deleted) and the space is NOT freed"
echo "  until the process exits. Real fix in production: restart/signal the process."

echo ""
echo "[6c] file inspects magic bytes, not names:"
run_cmd "cp /usr/bin/ls $SCRATCH/notes.txt && file $SCRATCH/notes.txt"

echo ""
echo "[6d] locate vs find freshness — a file created seconds ago:"
run_cmd "touch $SCRATCH/brand-new-file-week04"
run_cmd "locate brand-new-file-week04 || echo 'locate: NOT FOUND (database is stale until updatedb runs)'"
run_cmd "find /tmp -name brand-new-file-week04 2>/dev/null"

echo ""

# ── TASK 7: Ownership Sweeps ──────────────────────────────────────────────────
# Why it matters: Objectives 2.1 + 2.2 meet — find by owner is how you audit
# what an account left behind, and the -nouser case previews userdel cleanup.
echo "── TASK 7: Files by Owner ──"

echo ""
echo "[7a] Have labuser create some files (sudo -u runs a command AS another user):"
run_cmd "sudo -u labuser touch /home/labuser/notes-a.txt /home/labuser/notes-b.txt"
run_cmd "sudo -u labuser whoami"

echo ""
echo "[7b] Sweep the filesystem for everything labuser owns:"
run_cmd "sudo find /home /tmp -user labuser 2>/dev/null"

echo ""
echo "[7c] Inode-level detail on one of them:"
run_cmd "sudo stat /home/labuser/notes-a.txt"

echo ""

# ── TASK 8: Diagnose a Broken Login, Then Full Cleanup ────────────────────────
# Why it matters: This is 2.2 in troubleshooting form (previews 5.4's "account
# access failures"). One fault gets injected; you find it with inspection
# tools, not guesses.
echo "── TASK 8: Break-It / Fix-It + Cleanup ──"

echo ""
echo "[8a] Inject the fault (don't reason about it yet — run it, then investigate):"
run_cmd "sudo chage -E \$(date -d yesterday +%Y-%m-%d) labuser"

echo ""
echo "[8b] Symptom: 'labuser cannot log in.' Your toolbox: chage -l, getent shadow,"
echo "     getent passwd. Work the evidence BEFORE reading 8c. What's wrong?"
run_cmd "sudo chage -l labuser"

echo ""
echo "[8c] The tell: 'Account expires' is in the past — field 8, ACCOUNT expiry,"
echo "     not password expiry. Password fields are fine. Fix and verify:"
run_cmd "sudo chage -E -1 labuser"
run_cmd "sudo chage -l labuser | grep -i 'account expires'"
echo "  ^ -E -1 removes the expiration. Distinguish: chage -E = account dies on a"
echo "  DATE. chage -M = password ages out after N days. Different fields, both 'expired'."

echo ""
echo "[8d] Full teardown — user, home, groups, scratch. Verify each removal:"
run_cmd "sudo userdel -r labuser"
run_cmd "sudo groupdel labgroup && sudo groupdel secondgroup"
run_cmd "getent passwd labuser || echo 'labuser gone from passwd'"
run_cmd "getent group labgroup || echo 'labgroup gone'"
run_cmd "sudo ls /home/labuser 2>&1 | head -1"
run_cmd "rm -rf $SCRATCH"

echo ""
echo "[8e] What would userdel WITHOUT -r have left? Prove there are no orphans now:"
run_cmd "sudo find /home -nouser 2>/dev/null || echo 'no orphaned files'"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 04 Lab Complete"
echo ""
echo "  Practiced (all on tp-mudd):"
echo "  ✓ passwd/shadow/group read raw and decoded field by field"
echo "  ✓ Full account lifecycle: groupadd, useradd -m -G, skel verification, userdel -r"
echo "  ✓ The usermod -G vs -aG trap, performed and repaired"
echo "  ✓ chage aging policy + forced change; account-expiry vs password-expiry"
echo "  ✓ Lock semantics: ! prefix, why SSH keys bypass it, nologin as the real fix"
echo "  ✓ Hard link vs symlink inode mechanics; dangling links; cross-fs failure"
echo "  ✓ atime/mtime/ctime isolated; lsof (deleted); file magic bytes; locate staleness"
echo "  ✓ Fault diagnosis with chage -l — evidence before action"
echo ""
echo "  Objectives covered: 2.1, 2.2"
echo "════════════════════════════════════════════════════════"
