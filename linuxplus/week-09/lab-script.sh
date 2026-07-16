#!/bin/bash
# Week 09 — Automation Tools + Git + AI
# Objectives: 4.1, 4.4, 4.5
# Run on: tp-mudd only — fully self-contained, no other devices required
# Estimated time: 45–60 min (Task 6 compose is optional)
#
# Git work happens in a SANDBOX repo under /tmp with a local bare "remote" —
# push/pull/fetch are fully real, no network, zero risk to ~/homelab.

DRY_RUN=true  # Set to false to execute. true echoes commands instead of running them.

run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

SCRATCH="/tmp/week09"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 09 Lab — Automation + Git + AI"
echo "  Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN"
echo "════════════════════════════════════════════════════════"
echo ""

run_cmd "mkdir -p $SCRATCH"

# ── TASK 1: Git Sandbox — Three Trees + a Real (Local) Remote ─────────────────
# Why it matters: Objective 4.4 — a bare repo IS what GitHub/Gitea are under
# the hood. Building one demystifies 'remote' permanently.
echo "── TASK 1: Repo, Remote, Three Trees ──"

echo ""
echo "[1a] A bare repo = a remote with no working tree (this is what a server hosts):"
run_cmd "git init --bare $SCRATCH/origin.git 2>&1 | head -1"
run_cmd "ls $SCRATCH/origin.git | head -5"
echo "  ^ no files, just Git's database — HEAD, objects/, refs/. That's a 'remote'."

echo ""
echo "[1b] Clone it, set identity, confirm the remote wiring:"
run_cmd "git clone -q $SCRATCH/origin.git $SCRATCH/work && cd $SCRATCH/work || exit 1"
run_cmd "cd $SCRATCH/work && git config user.name 'Dillon' && git config user.email 'mudd.network@gmail.com'"
run_cmd "cd $SCRATCH/work && git remote -v"

echo ""
echo "[1c] .gitignore FIRST, then watch status respect it:"
run_cmd "cd $SCRATCH/work && printf '*.log\n.venv/\n' > .gitignore && touch app.sh debug.log"
run_cmd "cd $SCRATCH/work && git status --short"
echo "  ^ debug.log is invisible; app.sh and .gitignore are untracked (??)."

echo ""
echo "[1d] The three trees, narrated — watch the status marker change at each hop:"
run_cmd "cd $SCRATCH/work && echo '#!/bin/bash' > app.sh && git add app.sh .gitignore && git status --short"
echo "  ^ A = staged (index). Now modify the WORKING copy of a staged file:"
run_cmd "cd $SCRATCH/work && echo 'echo v1' >> app.sh && git status --short"
echo "  ^ AM = staged version AND newer unstaged edits — two trees, two states."
run_cmd "cd $SCRATCH/work && git diff --staged --stat && git diff --stat"
run_cmd "cd $SCRATCH/work && git add app.sh && git commit -qm 'initial: app.sh + gitignore' && git status --short && echo '  (clean — everything is in the local repo now)'"

echo ""
echo "[1e] Publish — push, and set the upstream while at it:"
run_cmd "cd $SCRATCH/work && git push -qu origin main 2>&1 | tail -1; git log --oneline"

echo ""

# ── TASK 2: Branch, Merge, Rebase, Squash ─────────────────────────────────────
# Why it matters: Objective 4.4 — merge vs rebase vs squash is the tested
# trio, and log --graph makes each strategy's fingerprint visible.
echo "── TASK 2: Branching Strategies ──"

echo ""
echo "[2a] Feature branch with two commits:"
run_cmd "cd $SCRATCH/work && git switch -qc feature/logging"
run_cmd "cd $SCRATCH/work && echo 'echo log1' >> app.sh && git commit -qam 'wip: start logging'"
run_cmd "cd $SCRATCH/work && echo 'echo log2' >> app.sh && git commit -qam 'wip: finish logging'"
run_cmd "cd $SCRATCH/work && git log --oneline --graph --all"

echo ""
echo "[2b] SQUASH the two wip commits into one clean commit — two ways."
echo "     Way 1 (do this one MANUALLY in your terminal — it's interactive):"
echo "       cd $SCRATCH/work && git rebase -i HEAD~2"
echo "       -> editor opens: leave line 1 as 'pick', change line 2 to 'squash',"
echo "          save; then write the combined message. This is the exam's rebase."
echo "     Way 2 (scripted equivalent so the lab can proceed either way):"
run_cmd "cd $SCRATCH/work && GIT_SEQUENCE_EDITOR=\"sed -i '2s/^pick/squash/'\" GIT_EDITOR=true git rebase -i HEAD~2 2>&1 | tail -1"
run_cmd "cd $SCRATCH/work && git log --oneline"
echo "  ^ two wip commits became one. New hash — rebase REWRITES history, which"
echo "  is why the golden rule says: never do this to pushed commits."

echo ""
echo "[2c] Merge it back — no-ff so the merge commit is visible in the graph:"
run_cmd "cd $SCRATCH/work && git switch -q main && git merge -q --no-ff feature/logging -m 'merge: logging feature'"
run_cmd "cd $SCRATCH/work && git log --oneline --graph"
run_cmd "cd $SCRATCH/work && git push -q && git branch -d feature/logging"

echo ""

# ── TASK 3: stash, tag, and the reset Trilogy ─────────────────────────────────
# Why it matters: Objective 4.4 — reset's three modes are a guaranteed
# question; running all three against real commits beats any table.
echo "── TASK 3: stash + tag + reset ──"

echo ""
echo "[3a] stash — the urgent-interruption workflow:"
run_cmd "cd $SCRATCH/work && echo 'echo unfinished' >> app.sh && git stash && git status --short && echo '  (clean — work is shelved)'"
run_cmd "cd $SCRATCH/work && git stash list && git stash pop && git status --short"
run_cmd "cd $SCRATCH/work && git checkout -q -- app.sh"

echo ""
echo "[3b] Tag the current state (and three sacrificial commits for reset):"
run_cmd "cd $SCRATCH/work && git tag v1.0 && git tag"
run_cmd "cd $SCRATCH/work && for n in 1 2 3; do echo \"echo change\$n\" >> app.sh; git commit -qam \"sacrificial commit \$n\"; done && git log --oneline | head -4"

echo ""
echo "[3c] --soft: HEAD moves back, changes stay STAGED:"
run_cmd "cd $SCRATCH/work && git reset --soft HEAD~1 && git status --short && git log --oneline | head -1"

echo ""
echo "[3d] --mixed (default): HEAD moves, changes kept but UNSTAGED:"
run_cmd "cd $SCRATCH/work && git reset HEAD~1 && git status --short && git log --oneline | head -1"

echo ""
echo "[3e] --hard: HEAD moves, changes GONE. PREDICT the status output first:"
run_cmd "cd $SCRATCH/work && git reset --hard v1.0 && git status --short; git log --oneline | head -1"
echo "  ^ clean tree, back at v1.0 — the two remaining sacrificial commits and all"
echo "  their content are destroyed. --hard is the only mode that eats work."

echo ""

# ── TASK 4: fetch vs pull — Seen From Two Clones ──────────────────────────────
# Why it matters: Objective 4.4 — 'pull = fetch + merge' is memorized by all
# and understood by few. Two clones of the same remote make it obvious.
echo "── TASK 4: fetch vs pull ──"

echo ""
echo "[4a] A second clone plays 'your other machine'; it pushes a change:"
run_cmd "git clone -q $SCRATCH/origin.git $SCRATCH/work2"
run_cmd "cd $SCRATCH/work2 && git config user.name 'Dillon' && git config user.email 'mudd.network@gmail.com' && echo 'echo from-work2' >> app.sh && git commit -qam 'change made elsewhere' && git push -q"

echo ""
echo "[4b] Back in clone #1: FETCH — the remote-tracking ref moves, main does NOT:"
run_cmd "cd $SCRATCH/work && git fetch -q && git log --oneline main..origin/main"
run_cmd "cd $SCRATCH/work && git status | head -2"
echo "  ^ 'behind by 1' — git KNOWS about the commit (fetched) but hasn't touched"
echo "  your branch. That gap is the entire difference between fetch and pull."

echo ""
echo "[4c] Complete the pull (merge the fetched ref), verify convergence:"
run_cmd "cd $SCRATCH/work && git merge -q origin/main && git log --oneline | head -2"

echo ""

# ── TASK 5: Ansible Against a Localhost Inventory ─────────────────────────────
# Why it matters: Objective 4.1 — inventory format, ad-hoc syntax, facts, a
# real playbook, and the idempotency proof (changed=1 then changed=0).
echo "── TASK 5: Ansible ──"

echo ""
echo "[5a] Install (ansible-core is enough) and confirm:"
run_cmd "rpm -q ansible-core 2>/dev/null || sudo dnf install -y ansible-core >/dev/null; ansible --version | head -1"

echo ""
echo "[5b] An inventory with two 'hosts' and groups — document the format in your head:"
if $DRY_RUN; then
    echo "[DRY RUN] write $SCRATCH/inv.ini ([web] web01, [db] db01, both connection=local)"
else
    cat > "$SCRATCH/inv.ini" <<'EOF'
[web]
web01 ansible_host=127.0.0.1 ansible_connection=local

[db]
db01 ansible_host=127.0.0.1 ansible_connection=local

[fleet:children]
web
db
EOF
fi
run_cmd "ansible-inventory -i $SCRATCH/inv.ini --graph"

echo ""
echo "[5c] Ad-hoc commands — module + args, one line each:"
run_cmd "ansible -i $SCRATCH/inv.ini all -m ping"
run_cmd "ansible -i $SCRATCH/inv.ini web01 -m setup -a 'filter=ansible_distribution*' 2>/dev/null | head -8"
echo "  ^ facts: ansible gathered the OS identity itself — usable as variables."

echo ""
echo "[5d] A playbook — desired state, not commands:"
if $DRY_RUN; then
    echo "[DRY RUN] write $SCRATCH/site.yml (copy module -> /tmp/week09-managed + debug fact)"
else
    cat > "$SCRATCH/site.yml" <<'EOF'
---
- name: Week 09 — manage a marker file
  hosts: fleet
  tasks:
    - name: marker file exists with expected content
      ansible.builtin.copy:
        dest: /tmp/week09-managed
        content: "managed by ansible\n"
        mode: "0644"

    - name: report the distribution fact
      ansible.builtin.debug:
        msg: "{{ inventory_hostname }} runs {{ ansible_distribution }} {{ ansible_distribution_version }}"
EOF
fi

echo ""
echo "[5e] THE IDEMPOTENCY PROOF — run it twice, read the changed= counts:"
run_cmd "ansible-playbook -i $SCRATCH/inv.ini $SCRATCH/site.yml 2>/dev/null | grep -E 'changed=|ok='"
run_cmd "ansible-playbook -i $SCRATCH/inv.ini $SCRATCH/site.yml 2>/dev/null | grep -E 'changed=|ok='"
echo "  ^ run 1: changed=1 (file created). run 2: changed=0 — state already matched,"
echo "  so the module did NOTHING. That is idempotency, the exam's favorite word."
run_cmd "rm -f /tmp/week09-managed"

echo ""

# ── TASK 6 (OPTIONAL): Compose — One File, One Stack ──────────────────────────
# Why it matters: Objective 4.1 lists compose file/up/down/logs; Week 6's
# nginx container becomes declarative.
echo "── TASK 6 (OPTIONAL): podman-compose ──"

echo ""
echo "[6a] Install podman-compose, write the stack file:"
run_cmd "rpm -q podman-compose 2>/dev/null || sudo dnf install -y podman-compose >/dev/null; podman-compose --version 2>&1 | head -1"
if $DRY_RUN; then
    echo "[DRY RUN] write $SCRATCH/compose.yaml (one nginx service, port 8080)"
else
    cat > "$SCRATCH/compose.yaml" <<'EOF'
services:
  web:
    image: docker.io/library/nginx:alpine
    ports:
      - "8080:80"
EOF
fi

echo ""
echo "[6b] up / verify / logs / down — the full compose verb set:"
run_cmd "cd $SCRATCH && podman-compose up -d 2>&1 | tail -2"
run_cmd "curl -sI http://127.0.0.1:8080 | head -1"
run_cmd "cd $SCRATCH && podman-compose logs 2>/dev/null | tail -2"
run_cmd "cd $SCRATCH && podman-compose down 2>&1 | tail -1"

echo ""

# ── TASK 7: Review the AI's Work (4.5, Practiced) ─────────────────────────────
# Why it matters: Objective 4.5 says 'always review output' — so here is an
# 'AI-generated' script with FOUR planted bugs. Find them BEFORE reading the
# answer key. This is the objective as an exercise instead of a slogan.
echo "── TASK 7: AI Output Review ──"

echo ""
echo "[7a] The 'AI-generated' script (it claims to archive a log directory):"
if $DRY_RUN; then
    echo "[DRY RUN] write $SCRATCH/ai-archiver.sh (4 planted bugs) + answers in solutions file"
else
    cat > "$SCRATCH/ai-archiver.sh" <<'EOF'
#!/bin/bash
# Archive a log directory. (Generated by AI — review before use!)
DIR=$1
if [ $DIR = "" ]; then
    echo "usage: $0 <dir>"; exit 1
fi
tar -czf /tmp/logs-$(date +%s).tar.gz $DIR
COUNT=`ls $DIR | wc -l`
if [ $COUNT > 5 ]; then
    echo "archived $COUNT files (large directory)"
fi
echo "done"
EOF
    cat > "$SCRATCH/ai-archiver.ANSWERS.txt" <<'EOF'
Week 09 Task 7 — the four planted bugs:

1. [ $DIR = "" ]  — unquoted. With NO argument this expands to [ = "" ]:
   a syntax error, so the usage check never fires. Fix: [[ -z "$1" ]].
2. tar ... $DIR   — unquoted again: a directory name with spaces becomes
   multiple arguments. Fix: "$DIR". (Week 8 Task 2 material.)
3. COUNT=`ls $DIR | wc -l` — backticks (legacy), and parsing ls output is
   fragile (filenames with newlines). Fix: COUNT=$(find "$DIR" -maxdepth 1 | wc -l)
4. [ $COUNT > 5 ] — inside [ ], > is a REDIRECT: this creates a file named
   '5' in the current directory and the test always succeeds. Fix:
   [[ $COUNT -gt 5 ]]. (THE Week 8 comparison trap, in the wild.)

The meta-lesson: every bug is plausible, the script LOOKS fine, and it even
prints 'done' successfully. Confident, wrong, and runnable — that is exactly
why 4.5 says review AI output like an untrusted PR.
EOF
fi
run_cmd "cat $SCRATCH/ai-archiver.sh"

echo ""
echo "[7b] YOUR REVIEW — before running anything, list every bug you can find."
echo "     Hints: Week 8's comparison traps, quoting rules, and legacy constructs"
echo "     are all represented. Write your list down. Aim for four."

echo ""
echo "[7c] Test your findings empirically (safe here — scratch dir):"
run_cmd "cd $SCRATCH && bash ai-archiver.sh 2>&1 | head -2; ls -l 5 2>/dev/null && echo '  ^ a file named 5 appeared — did you catch WHY?'"

echo ""
echo "[7d] Check against the answer key, then fix the script and re-verify:"
echo "     cat $SCRATCH/ai-archiver.ANSWERS.txt"

echo ""

# ── CLEANUP CHECK ─────────────────────────────────────────────────────────────
echo "── Cleanup Check ──"
echo "  Everything lives in $SCRATCH — rm -rf when done."
echo "  Worth doing on the REAL repo before you leave (read-only):"
echo "    cd ~/homelab && git log --oneline --graph | head -10"
echo "    git remote -v      # your dual-remote push (Gitea + GitHub) — GitOps seed"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 09 Lab Complete"
echo ""
echo "  Practiced (all on tp-mudd):"
echo "  ✓ Bare repo built by hand — 'remote' demystified; three trees narrated via status"
echo "  ✓ Squash via rebase -i (manual + scripted); --no-ff merge; graph fingerprints"
echo "  ✓ stash cycle; tag; reset --soft/--mixed/--hard against sacrificial commits"
echo "  ✓ fetch vs pull proven with two clones of one remote"
echo "  ✓ Ansible: inventory graph, ad-hoc ping/setup/facts, playbook run twice —"
echo "    idempotency shown as changed=1 then changed=0"
echo "  ✓ (optional) compose up/logs/down on a declarative one-service stack"
echo "  ✓ 4.5 practiced: four planted bugs in 'AI' code found by review, one proven live"
echo ""
echo "  Objectives covered: 4.1, 4.4, 4.5"
echo "════════════════════════════════════════════════════════"
