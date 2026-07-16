#!/bin/bash
# Week 08 — Bash Scripting + Python Basics
# Objectives: 4.2, 4.3
# Run on: tp-mudd only — fully self-contained, no other devices required
# Estimated time: 45–60 min (Task 7 port-to-Python is an optional stretch)
#
# THIS WEEK IS DIFFERENT: Tasks 5 and 6 are build exercises. YOU write the
# scripts (spec provided); this lab provides GRADERS that test your work
# against the spec. Reference solutions are written to $SCRATCH/solutions/ —
# do not open them until your version passes.

DRY_RUN=true  # Set to false to execute. true echoes commands instead of running them.

run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

SCRATCH="/tmp/week08"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 08 Lab — Bash Scripting + Python Basics"
echo "  Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN"
echo "════════════════════════════════════════════════════════"
echo ""

run_cmd "mkdir -p $SCRATCH/solutions"

# ── TASK 1: Expansion Drills — Predict Every Line Before You Run It ──────────
# Why it matters: Objective 4.2 — parameter expansion is the densest scoring
# area. Say the output out loud FIRST; the gap between guess and result is
# exactly what to study.
echo "── TASK 1: Expansion + Quoting ──"

echo ""
echo "[1a] Parameter expansion on a real path — PREDICT all four:"
run_cmd "f=/var/log/dnf.log; echo \"basename:  \${f##*/}\"; echo \"dirname:   \${f%/*}\"; echo \"no-ext:    \${f%.*}\"; echo \"length:    \${#f}\""

echo ""
echo "[1b] Defaults — the difference between :- and :=:"
run_cmd "unset X; echo \"with :- -> \${X:-fallback}\"; echo \"X is still: '\${X:-}'\"; echo \"with := -> \${X:=fallback}\"; echo \"X is now:  '\$X'\""

echo ""
echo "[1c] Arithmetic is integer-only — predict both:"
run_cmd "echo \$(( 7 / 2 )); echo \$(( 7 % 2 ))"

echo ""
echo "[1d] Subshell isolation — why does the last pwd say what it says?"
run_cmd "cd /tmp && ( cd /etc && echo \"inside:  \$(pwd)\" ) && echo \"outside: \$(pwd)\""

echo ""
echo "[1e] export inheritance — the child only sees what was exported:"
run_cmd "SECRET=hidden; export SHARED=visible; bash -c 'echo \"child sees SHARED=\$SHARED SECRET=\$SECRET\"'"

echo ""

# ── TASK 2: Tests, Comparisons, Regex — the Traps, Live ──────────────────────
# Why it matters: Objective 4.2 — comparison-operator confusion is the #1
# source of wrong answers in script questions. Produce each trap yourself.
echo "── TASK 2: [[ ]] Drills ──"

echo ""
echo "[2a] THE trap — numeric vs lexicographic. PREDICT both results:"
run_cmd "[[ 10 -gt 9 ]] && echo 'numeric:       10 -gt 9 is TRUE'"
run_cmd "[[ '10' > '9' ]] && echo 'string: TRUE' || echo 'lexicographic: \"10\" > \"9\" is FALSE (1 sorts before 9)'"

echo ""
echo "[2b] Empty-string tests — -z and -n:"
run_cmd "v=''; [[ -z \"\$v\" ]] && echo '-z: empty confirmed'; v=x; [[ -n \"\$v\" ]] && echo '-n: non-empty confirmed'"

echo ""
echo "[2c] File tests against real objects:"
run_cmd "[[ -f /etc/fstab ]] && echo '-f: fstab is a regular file'; [[ -d /etc ]] && echo '-d: /etc is a directory'; [[ -x /usr/bin/bash ]] && echo '-x: bash is executable'"

echo ""
echo "[2d] Regex with capture groups — parse an interface:MTU pair:"
run_cmd "s='tailscale0:1280'; [[ \$s =~ ^(.+):([0-9]+)\$ ]] && echo \"iface=\${BASH_REMATCH[1]} mtu=\${BASH_REMATCH[2]}\""

echo ""
echo "[2e] Now QUOTE the regex and watch it break (this is gotcha material):"
run_cmd "s='tailscale0:1280'; [[ \$s =~ \"^(.+):([0-9]+)\$\" ]] && echo 'matched' || echo 'NO MATCH — quoting made the regex a literal string'"

echo ""

# ── TASK 3: Loops, case, IFS ──────────────────────────────────────────────────
# Why it matters: Objective 4.2 — the while-read idiom and IFS parsing appear
# in nearly every real script, including the ones already in your repo.
echo "── TASK 3: Iteration + Parsing ──"

echo ""
echo "[3a] Array + for — the pattern Task 5's extension will need:"
run_cmd "svcs=(sshd chronyd tailscaled); for s in \"\${svcs[@]}\"; do echo \"would check: \$s\"; done; echo \"count: \${#svcs[@]}\""

echo ""
echo "[3b] while read — count human users from a REAL file (Week 4 crossover):"
run_cmd "count=0; while IFS=: read -r user _ uid _; do [[ \$uid -ge 1000 && \$uid -lt 65000 ]] && { echo \"  human: \$user (\$uid)\"; ((count++)); }; done < /etc/passwd; echo \"total: \$count\""

echo ""
echo "[3c] case — glob patterns, not regex:"
run_cmd "for arg in start stop status bogus; do case \$arg in start|restart) echo \"\$arg -> restarting\";; st*) echo \"\$arg -> showing status\";; *) echo \"\$arg -> usage error\";; esac; done"
echo "  ^ note 'stop' hit st* — order matters, first match wins."

echo ""
echo "[3d] until — loop while FALSE (the waiting-for-a-service idiom):"
run_cmd "n=0; until [[ \$n -ge 3 ]]; do echo \"  attempt \$((++n))\"; done"

echo ""

# ── TASK 4: trap, set -e, set -x — Safety Rails ───────────────────────────────
# Why it matters: Objective 4.2 — these three lines separate scripts that
# clean up after themselves from scripts that leave wreckage.
echo "── TASK 4: Safety Rails ──"

echo ""
echo "[4a] trap EXIT fires even when the script dies mid-run:"
if $DRY_RUN; then
    echo "[DRY RUN] write + run $SCRATCH/trapdemo.sh (traps EXIT, then hits a fatal error)"
else
    cat > "$SCRATCH/trapdemo.sh" <<'EOF'
#!/bin/bash
set -e
TMPFILE=$(mktemp)
trap 'echo "  trap: cleaning up $TMPFILE"; rm -f "$TMPFILE"' EXIT
echo "  working... created $TMPFILE"
false                       # simulated failure — set -e kills the script HERE
echo "  never reached"
EOF
    chmod +x "$SCRATCH/trapdemo.sh"
fi
run_cmd "bash $SCRATCH/trapdemo.sh; echo \"exit code: \$?\""
echo "  ^ 'never reached' didn't print (set -e), but the trap STILL ran. That"
echo "  pairing — set -e for failure, trap EXIT for cleanup — is the skeleton."

echo ""
echo "[4b] set -x — watch expansion happen (the debugging superpower):"
run_cmd "bash -xc 'svc=chronyd; systemctl is-active \$svc' 2>&1 | sed 's/^/  /'"
echo "  ^ the + lines show each command AFTER expansion — you see what bash saw."

echo ""

# ── TASK 5: BUILD — Service Health Check (you write it) ──────────────────────
# Why it matters: This is the topic-map's core exercise, and it is exactly
# the shape of an exam performance-based question.
echo "── TASK 5: Build check-service.sh ──"

echo "
  SPEC — write $SCRATCH/check-service.sh yourself, in your editor:
    1. Takes ONE argument: a service name.
    2. No argument given      -> print usage to stderr, exit 2
    3. Service active         -> print '<name> is active',   exit 0
    4. Service inactive/missing -> print '<name> is NOT active', exit 1
    5. Use: shebang, [[ ]], systemctl is-active -q, exit codes. ~10 lines.

  Write it now. Then run the grader below. Do not peek at solutions/ first."

echo ""
echo "[5a] The grader (write + run):"
if $DRY_RUN; then
    echo "[DRY RUN] write $SCRATCH/grade-bash.sh (tests the 3 spec cases against your script)"
else
    cat > "$SCRATCH/grade-bash.sh" <<'EOF'
#!/bin/bash
# Grades a health-check script against the Week 08 spec.
TARGET=${1:?usage: grade-bash.sh /path/to/check-service.sh}
pass=0; fail=0
check() {  # check <desc> <expected-rc> [args...]
    local desc=$1 want=$2; shift 2
    bash "$TARGET" "$@" >/dev/null 2>&1
    local got=$?
    if [[ $got -eq $want ]]; then
        echo "  PASS: $desc (exit $got)"; ((pass++))
    else
        echo "  FAIL: $desc — expected exit $want, got $got"; ((fail++))
    fi
}
check "no argument -> usage error"        2
check "active service (journald) -> ok"   0  systemd-journald
check "nonexistent service -> not active" 1  no-such-service-xyz
echo "  ---- $pass passed, $fail failed ----"
[[ $fail -eq 0 ]] && echo "  GRADE: PASS — now do the extension" || echo "  GRADE: revise and re-run"
EOF
    chmod +x "$SCRATCH/grade-bash.sh"
fi
run_cmd "bash $SCRATCH/grade-bash.sh $SCRATCH/check-service.sh"

echo ""
echo "[5b] EXTENSION SPEC — upgrade your script (or a copy, check-fleet.sh):"
echo "
    1. A check_service() function does the actual test (use 'local').
    2. With NO args: loop over an array of defaults (sshd chronyd tailscaled).
    3. With args: loop over \"\$@\" instead.
    4. Every result also appended to $SCRATCH/health.log with a timestamp:
         2026-08-17T10:15:02 chronyd active
    5. Exit 0 only if ALL services were active, else exit 1."

echo ""
echo "[5c] Extension grader:"
if $DRY_RUN; then
    echo "[DRY RUN] write $SCRATCH/grade-ext.sh (multi-service + logfile checks)"
else
    cat > "$SCRATCH/grade-ext.sh" <<'EOF'
#!/bin/bash
TARGET=${1:?usage: grade-ext.sh /path/to/check-fleet.sh}
pass=0; fail=0
rm -f /tmp/week08/health.log
bash "$TARGET" systemd-journald no-such-service-xyz >/dev/null 2>&1
rc=$?
[[ $rc -eq 1 ]] && { echo "  PASS: mixed fleet -> exit 1"; ((pass++)); } || { echo "  FAIL: mixed fleet expected exit 1, got $rc"; ((fail++)); }
bash "$TARGET" systemd-journald >/dev/null 2>&1
rc=$?
[[ $rc -eq 0 ]] && { echo "  PASS: all-healthy -> exit 0"; ((pass++)); } || { echo "  FAIL: all-healthy expected exit 0, got $rc"; ((fail++)); }
if [[ -f /tmp/week08/health.log ]] && grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}' /tmp/week08/health.log; then
    echo "  PASS: timestamped log entries present"; ((pass++))
else
    echo "  FAIL: /tmp/week08/health.log missing or lines lack ISO timestamps"; ((fail++))
fi
echo "  ---- $pass passed, $fail failed ----"
EOF
    chmod +x "$SCRATCH/grade-ext.sh"
fi
run_cmd "bash $SCRATCH/grade-ext.sh $SCRATCH/check-fleet.sh"

echo ""
echo "[5d] Reference solutions (written now, read ONLY after passing):"
if $DRY_RUN; then
    echo "[DRY RUN] write $SCRATCH/solutions/check-service.sh and check-fleet.sh"
else
    cat > "$SCRATCH/solutions/check-service.sh" <<'EOF'
#!/bin/bash
# Week 08 reference — minimal spec-compliant version.
if [[ -z "$1" ]]; then
    echo "usage: $0 <service-name>" >&2
    exit 2
fi
if systemctl is-active -q "$1"; then
    echo "$1 is active"
    exit 0
else
    echo "$1 is NOT active"
    exit 1
fi
EOF
    cat > "$SCRATCH/solutions/check-fleet.sh" <<'EOF'
#!/bin/bash
# Week 08 reference — extension version.
LOG=/tmp/week08/health.log
DEFAULTS=(sshd chronyd tailscaled)

check_service() {
    local svc="$1" state
    if systemctl is-active -q "$svc"; then state="active"; else state="NOT-active"; fi
    echo "$(date +%Y-%m-%dT%H:%M:%S) $svc $state" | tee -a "$LOG"
    [[ "$state" == "active" ]]
}

targets=("${@}")
[[ ${#targets[@]} -eq 0 ]] && targets=("${DEFAULTS[@]}")

rc=0
for svc in "${targets[@]}"; do
    check_service "$svc" || rc=1
done
exit $rc
EOF
    chmod +x "$SCRATCH"/solutions/*.sh
fi
echo "  After passing: diff your version against the reference. Different is fine;"
echo "  understand WHY each difference exists. That comparison is the lesson."

echo ""

# ── TASK 6: BUILD — Python loadavg Monitor in a venv ─────────────────────────
# Why it matters: Objective 4.3 — venv workflow + the data types + a real
# /proc parser, graded the same way.
echo "── TASK 6: Python — venv + loadavg.py ──"

echo ""
echo "[6a] Create and inspect the venv — pip installs stay INSIDE it:"
run_cmd "python3 -m venv $SCRATCH/.venv"
run_cmd "( source $SCRATCH/.venv/bin/activate && which python3 && pip install -q requests && pip list | grep -i requests )"
run_cmd "pip list 2>/dev/null | grep -i requests || echo '  system python: requests NOT here — the venv contained it'"

echo ""
echo "  SPEC — write $SCRATCH/loadavg.py yourself:
    1. Read /proc/loadavg (pathlib or open()).
    2. Parse the 1-minute load into a float; fields are space-separated (str.split
       -> list; float() conversion — two data types, on purpose).
    3. Optional argv[1] = threshold (float, default 4.0).
    4. Print like:  load 0.52 (threshold 4.0) OK
    5. Exit 0 if load < threshold, exit 1 with WARNING text if >=.
    6. PEP 8: 4-space indents, snake_case. ~15 lines."

echo ""
echo "[6b] The grader:"
if $DRY_RUN; then
    echo "[DRY RUN] write $SCRATCH/grade-py.sh (normal + forced-warning + parse checks)"
else
    cat > "$SCRATCH/grade-py.sh" <<'EOF'
#!/bin/bash
TARGET=${1:?usage: grade-py.sh /path/to/loadavg.py}
pass=0; fail=0
python3 "$TARGET" >/dev/null 2>&1
rc=$?
[[ $rc -eq 0 ]] && { echo "  PASS: default threshold -> exit 0 (assuming idle-ish laptop)"; ((pass++)); } || { echo "  FAIL: default run expected 0, got $rc"; ((fail++)); }
python3 "$TARGET" 0.0 >/dev/null 2>&1
rc=$?
[[ $rc -eq 1 ]] && { echo "  PASS: threshold 0.0 -> exit 1 (warning path)"; ((pass++)); } || { echo "  FAIL: threshold 0.0 expected 1, got $rc"; ((fail++)); }
OUT=$(python3 "$TARGET" 99 2>/dev/null)
[[ "$OUT" =~ [0-9]+\.[0-9]+ ]] && { echo "  PASS: output contains a parsed float"; ((pass++)); } || { echo "  FAIL: no float in output: '$OUT'"; ((fail++)); }
python3 -m py_compile "$TARGET" 2>/dev/null && { echo "  PASS: compiles clean (no syntax/indentation errors)"; ((pass++)); } || { echo "  FAIL: py_compile rejects it"; ((fail++)); }
echo "  ---- $pass passed, $fail failed ----"
EOF
    chmod +x "$SCRATCH/grade-py.sh"
fi
run_cmd "bash $SCRATCH/grade-py.sh $SCRATCH/loadavg.py"

echo ""
echo "[6c] Reference solution (after passing only):"
if $DRY_RUN; then
    echo "[DRY RUN] write $SCRATCH/solutions/loadavg.py"
else
    cat > "$SCRATCH/solutions/loadavg.py" <<'EOF'
#!/usr/bin/env python3
"""Week 08 reference — warn when the 1-minute load exceeds a threshold."""
import sys
from pathlib import Path

DEFAULT_THRESHOLD = 4.0


def read_load() -> float:
    fields = Path("/proc/loadavg").read_text().split()   # str -> list of str
    return float(fields[0])                              # str -> float


def main() -> int:
    threshold = float(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_THRESHOLD
    load = read_load()
    if load >= threshold:
        print(f"WARNING: load {load} (threshold {threshold})")
        return 1
    print(f"load {load} (threshold {threshold}) OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
EOF
fi

echo ""

# ── TASK 7 (OPTIONAL): Port the Health Check to Python ────────────────────────
# Why it matters: The same problem in both languages exposes the seam the
# exam probes: bash exit codes (0=true) read from Python (0=falsy).
echo "── TASK 7 (OPTIONAL): The Same Tool, Twice ──"

echo "
  Port check-service.sh to $SCRATCH/check_service.py:
    - subprocess.run(['systemctl', 'is-active', '-q', name]) -> .returncode
    - Same exit-code contract (0/1/2). argparse or sys.argv — your call.
    - Grade it with the SAME bash grader:
        bash $SCRATCH/grade-bash.sh <(echo 'python3 /tmp/week08/check_service.py \"\$@\"')
      ...or simpler: wrap it in a one-line bash shim and grade that.
    - Then answer in one sentence, out loud: in Python, why is
      'if result.returncode:' the FAILURE branch, when in bash
      'if systemctl is-active ...' is the SUCCESS branch?"

echo ""

# ── CLEANUP CHECK ─────────────────────────────────────────────────────────────
echo "── Cleanup Check ──"
echo "  Your scripts + solutions live in $SCRATCH — consider keeping the good"
echo "  ones: check-fleet.sh belongs in ~/homelab/scripts/ with a git commit,"
echo "  not in /tmp. That promotion IS this week's homelab payoff."
echo "  Otherwise: rm -rf $SCRATCH"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 08 Lab Complete"
echo ""
echo "  Practiced (all on tp-mudd):"
echo "  ✓ Parameter expansion, subshell isolation, export inheritance — predicted first"
echo "  ✓ Numeric-vs-lexicographic trap, -z/-n, file tests, =~ with BASH_REMATCH"
echo "  ✓ Arrays, while-read over /etc/passwd, case fall-through order, until"
echo "  ✓ set -e + trap EXIT pairing; bash -x tracing"
echo "  ✓ WROTE check-service.sh to spec — machine-graded, then extended with"
echo "    function/array/logfile and graded again"
echo "  ✓ venv containment proven; WROTE loadavg.py — graded incl. py_compile"
echo "  ✓ (optional) same tool in both languages; exit-code truthiness seam"
echo ""
echo "  Objectives covered: 4.2, 4.3"
echo "════════════════════════════════════════════════════════"
