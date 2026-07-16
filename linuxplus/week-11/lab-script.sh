#!/bin/bash
# Week 11 — Practice Exam + Gap Analysis
# Objectives: ALL (review week — no new material)
# Run on: tp-mudd only — fully self-contained, no other devices required
# Estimated time: Session A is the 90-min practice exam (not this script).
#                 This script supports Session B: gap mapping (~10 min) plus
#                 an optional cross-domain speed sweep (~30-40 min).
#
# HOW THIS WEEK WORKS
#   Session A: sit the Dion practice exam — 90 questions, 90 minutes, closed
#              book, no pauses. Score it. Then run PART A below to file the
#              results and map every weak topic to its week and objective.
#   Session B: drill ONLY the gaps. "Quiz me on objective X.X" per weak topic,
#              max 10 minutes each, repeat to 80%+. The speed sweep in PART B
#              is a confidence pass over all ten weeks — run it if drilling
#              leaves time, or the day before the exam as a warm engine check.

DRY_RUN=true  # Set to false to execute. true echoes commands instead of running them.

run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

SCRATCH="/tmp/week11"
WEEKDIR="$HOME/homelab/linuxplus/week-11"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 11 — Gap Analysis + Speed Sweep"
echo "  Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN | Exam: Sep 14 ($(( ( $(date -d 2026-09-14 +%s) - $(date +%s) ) / 86400 )) days out)"
echo "════════════════════════════════════════════════════════"
echo ""

run_cmd "mkdir -p $SCRATCH"

# ══ PART A — GAP MAPPING (run right after scoring the practice exam) ══════════

# ── TASK A1: File the Results ─────────────────────────────────────────────────
# Why it matters: methodology step 7 — document. An unrecorded practice score
# is a vibe, not data. The decision rule below needs the number.
echo "── TASK A1: Practice Exam Results File ──"

echo ""
if [[ -f "$WEEKDIR/practice-exam-results.md" ]]; then
    echo "[A1] Results file already exists — open and fill it:"
    echo "       $WEEKDIR/practice-exam-results.md"
elif $DRY_RUN; then
    echo "[DRY RUN] write $WEEKDIR/practice-exam-results.md (template: score, domain breakdown, missed topics, decision)"
else
    cat > "$WEEKDIR/practice-exam-results.md" <<'EOF'
# Practice Exam Results — Week 11 Session A

**Date taken:**
**Score:** __ / 90  ( ___ % )
**Time used:** __ / 90 min
**Source:** Dion Training practice exam # __

---

## Domain breakdown (from the score report)

| Domain | Weight | My % | Weak? |
|---|---|---|---|
| 1 System Management | 23% | | |
| 2 Services and User Mgmt | 20% | | |
| 3 Security | 18% | | |
| 4 Automation & Scripting | 17% | | |
| 5 Troubleshooting | 22% | | |

## Topics missed MORE THAN ONCE (these are the gaps — singles are noise)

<!-- topic → objective → week, e.g.:
- SELinux booleans vs contexts → 3.3 → week-06
-->
-
-

## Decision (80% threshold — from topic-map.md)

- [ ] Scored 80%+ → sit the exam Sep 14. Drill the listed gaps anyway.
- [ ] Below 80% → identify the TWO lowest domains above; remaining days go
      to those only. Re-test with the second Dion exam before deciding.

## Session B drill log

<!-- objective | quiz rounds | final % -->
EOF
    echo "[A1] Template created: $WEEKDIR/practice-exam-results.md — fill it now."
fi

echo ""

# ── TASK A2: The Gap Map — Objective → Week → Where to Reopen ─────────────────
# Why it matters: a missed topic is only drillable once it has an address.
# Every objective on the score report maps to exactly one week folder.
echo "── TASK A2: Objective → Week Map ──"
cat <<'EOF'

  Objective(s)              Week     Reopen
  1.1, 1.5  Fundamentals    week-01  cheatsheet + redirection tasks
  1.2, 1.3  Hardware/Storage week-02  cheatsheet + LVM/loop-device lab
  1.4, 1.6, 1.7  Net/Bkp/Virt week-03  cheatsheet + localhost net lab
  2.1, 2.2  Files/Accounts  week-04  cheatsheet + links/aging lab
  2.3, 2.4, 2.5  Proc/SW/systemd week-05  cheatsheet + unit-override lab
  2.6, 3.2, 3.3  Containers/FW/Hardening week-06  cheatsheet + SELinux tasks
  3.1, 3.4, 3.5, 3.6  Auth/Crypto/Compliance week-07  cheatsheet + GPG/auditd lab
  4.2, 4.3  Bash/Python     week-08  cheatsheet + health-check script
  4.1, 4.4, 4.5  Autom/Git/AI week-09  cheatsheet + git sandbox lab
  5.1–5.5   Troubleshooting  week-10  cheatsheet + fault stations

  Per weak topic, in order (max 10 min each — topic-map.md rule):
    1. Reread that week's cheatsheet SECTION (not the whole file)
    2. If it was hands-on: rerun the single relevant lab task
    3. "Quiz me on objective X.X" — repeat until 80%+
    4. Log the rounds in practice-exam-results.md
EOF

echo ""

# ══ PART B — SPEED SWEEP (optional): one rep per week, predict THEN run ═══════
# Why it matters: retrieval practice across all ten weeks in ~35 minutes.
# RULE: say your prediction OUT LOUD before each run_cmd. A wrong prediction
# is a gap — add it to the results file. A slow right answer is fine.

echo "══ PART B: Ten-Week Speed Sweep ══"
echo ""

# ── SWEEP 1 (wk 1): Redirection Order ─────────────────────────────────────────
echo "── SWEEP 1 (wk1): predict what wc counts — and why the order matters:"
run_cmd "ls /nope 2>&1 >/dev/null | wc -l"
echo "  ^ 1: at the moment 2>&1 ran, stdout WAS the pipe — stderr joined it;"
echo "    then >/dev/null moved only stdout. Reverse the two and wc sees 0."

echo ""

# ── SWEEP 2 (wk 2): Storage Reads ─────────────────────────────────────────────
echo "── SWEEP 2 (wk2): name every fstab field of this line before reading on:"
run_cmd "grep -v '^#' /etc/fstab | head -2"
echo "  (device | mountpoint | fstype | options | dump | pass)"
echo "  Then say the two-step growth rule out loud: lvextend, THEN...?"
run_cmd "df -i / | tail -1"
echo "  ^ and say what problem that IUse% column catches."

echo ""

# ── SWEEP 3 (wk 3): tar + rsync Slash ─────────────────────────────────────────
echo "── SWEEP 3 (wk3): archive roundtrip + THE slash question:"
run_cmd "tar -czf $SCRATCH/hosts.tar.gz /etc/hosts 2>/dev/null && tar -tzvf $SCRATCH/hosts.tar.gz | head -1"
run_cmd "mkdir -p $SCRATCH/src $SCRATCH/d1 $SCRATCH/d2 && touch $SCRATCH/src/f"
echo "  PREDICT where 'f' lands in each before running:"
run_cmd "rsync -a $SCRATCH/src/ $SCRATCH/d1/ && rsync -a $SCRATCH/src $SCRATCH/d2/ && find $SCRATCH/d1 $SCRATCH/d2 -name f"
echo "  ^ d1/f (contents) vs d2/src/f (the dir itself). Trailing slash."

echo ""

# ── SWEEP 4 (wk 4): Links After Deletion ──────────────────────────────────────
echo "── SWEEP 4 (wk4): PREDICT what each link does after the original dies:"
run_cmd "echo data > $SCRATCH/orig && ln $SCRATCH/orig $SCRATCH/hard && ln -s $SCRATCH/orig $SCRATCH/soft && rm $SCRATCH/orig"
run_cmd "cat $SCRATCH/hard 2>&1; cat $SCRATCH/soft 2>&1"
echo "  ^ hard link still reads (same inode, link count was 2); symlink dangles."

echo ""

# ── SWEEP 5 (wk 5): Units + cron ──────────────────────────────────────────────
echo "── SWEEP 5 (wk5): name the three unit-file sections and one key per each:"
run_cmd "systemctl cat sshd 2>/dev/null | grep -E '^\[' "
echo "  Then translate BEFORE reading on:   */15 2 * * 1"
echo "  ^ every 15 min DURING the 2am hour, Mondays — not 'every 15 minutes'."
echo "  And the deactivation ladder: stop / disable / mask — say what each survives."

echo ""

# ── SWEEP 6 (wk 6): Firewall + SELinux Reads ──────────────────────────────────
echo "── SWEEP 6 (wk6): read your own firewall state; say what --permanent adds:"
run_cmd "sudo firewall-cmd --get-default-zone && sudo firewall-cmd --list-all | head -6"
run_cmd "ls -Z /etc/ssh/sshd_config"
echo "  ^ name the four context fields, and which ONE policies actually enforce."

echo ""

# ── SWEEP 7 (wk 7): Aging + Crypto Roles ──────────────────────────────────────
echo "── SWEEP 7 (wk7): read your own aging policy; map each line to shadow fields:"
run_cmd "chage -l $USER | head -4"
echo "  GPG check, no keyboard needed — whose key encrypts, whose key signs?"
echo "  (encrypt: THEIR public. sign: YOUR private. verify: their public.)"
run_cmd "gpg --list-keys 2>/dev/null | head -4 || echo '  (no keyring — week-07 keypair was cleaned up; the roles still stand)'"

echo ""

# ── SWEEP 8 (wk 8): The Comparison Trap, Live ─────────────────────────────────
echo "── SWEEP 8 (wk8): PREDICT both exit codes before running:"
run_cmd "[[ '42' =~ ^[0-9]+\$ ]]; echo \"regex says: \$?\""
run_cmd "cd $SCRATCH && [ 3 > 2 ]; echo \"test says: \$?\"; ls -l 2 2>/dev/null && echo '  ^ and THERE is the file named 2 — > redirected inside [ ]'"
echo "  ^ the second is 'true' for the wrong reason. -gt or [[ ]] fixes it."

echo ""

# ── SWEEP 9 (wk 9): reset Trilogy Micro-Rep ───────────────────────────────────
echo "── SWEEP 9 (wk9): PREDICT git status output after the reset, then run:"
run_cmd "rm -rf $SCRATCH/repo && git init -q $SCRATCH/repo && cd $SCRATCH/repo && git config user.email x@x && git config user.name x && echo a>f && git add f && git commit -qm one && echo b>>f && git commit -qam two"
run_cmd "cd $SCRATCH/repo && git reset --soft HEAD~1 && git status --short && git log --oneline"
echo "  ^ 'M ' staged — soft keeps everything, staged. Say what --mixed and"
echo "    --hard would have shown instead. Then: pull = fetch + ____?"

echo ""

# ── SWEEP 10 (wk 10): Read the Live System ────────────────────────────────────
echo "── SWEEP 10 (wk10): interpret each number out loud as you read it:"
run_cmd "uptime && vmstat 1 2 | tail -1"
echo "  ^ r vs nproc? b? si/so? wa? — one sentence per column, from memory."
run_cmd "journalctl -b -p err -q --no-pager | wc -l"
echo "  ^ triage habit: how many are (a) actionable, (b) noise, (c) research?"

echo ""

# ── CLEANUP + CLOSE ───────────────────────────────────────────────────────────
echo "── Cleanup ──"
run_cmd "rm -rf $SCRATCH"
echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 11 — Sweep Complete"
echo ""
echo "  Every wrong PREDICTION above goes into practice-exam-results.md as a"
echo "  gap — then: 'Quiz me on objective X.X', 10 minutes, 80%+, next gap."
echo ""
echo "  Decision rule (topic-map.md): 80%+ on the practice exam → sit Sep 14."
echo "  Below 80% → the two lowest domains own every remaining day."
echo ""
echo "  Night before: reread week-11/cheatsheet.md once. Then stop. Sleep is"
echo "  higher-yield than a fourth pass."
echo "════════════════════════════════════════════════════════"
