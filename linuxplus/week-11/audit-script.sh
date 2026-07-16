#!/bin/bash
# Week 11 Audit — Exam Readiness (the study system itself)
# Re-run anytime during exam week. Audits the sprint, not the OS: progress
# tracker state, test-out completion, study artifacts, the practice-exam
# gate, and whether the work is safely committed. The system under test
# this week is you.
# Run on: tp-mudd (Fedora 44) only. Read-only — changes nothing.

PASS=0
WARN=0
INFO=0

pass() { echo "[PASS] $*"; ((PASS++)); }
warn() { echo "[WARN] $*"; ((WARN++)); }
info() { echo "[INFO] $*"; ((INFO++)); }

LPDIR="$HOME/homelab/linuxplus"
TOPICMAP="$LPDIR/topic-map.md"
RESULTS="$LPDIR/week-11/practice-exam-results.md"
EXAM_DATE="2026-09-14"

echo ""
echo "══════════════════════════════════════════════════════"
echo "  AUDIT: Exam Readiness — XK0-006"
echo "  $(date)"
echo "══════════════════════════════════════════════════════"
echo ""

# ── Countdown ─────────────────────────────────────────────────────────────────
echo "── Countdown ──"

DAYS_LEFT=$(( ( $(date -d "$EXAM_DATE" +%s) - $(date +%s) ) / 86400 ))
if [[ "$DAYS_LEFT" -gt 7 ]]; then
    info "$DAYS_LEFT days until exam week ($EXAM_DATE) — this audit matters most inside the final 7"
elif [[ "$DAYS_LEFT" -ge 0 ]]; then
    info "$DAYS_LEFT day(s) to exam ($EXAM_DATE) — everything below should be green"
else
    info "Exam date has passed — if you sat it, this file's job is done either way"
fi

echo ""

# ── Progress Tracker (topic-map.md) ───────────────────────────────────────────
echo "── Progress Tracker: Weeks 1–10 ──"

if [[ ! -f "$TOPICMAP" ]]; then
    warn "topic-map.md not found at $TOPICMAP — cannot audit the tracker"
else
    A_OPEN=""; B_OPEN=""; T_OPEN=""
    while IFS='|' read -r _ wk _ _ _ a b t _; do
        wk=$(echo "$wk" | tr -d ' ')
        [[ "$wk" =~ ^([1-9]|10)$ ]] || continue
        [[ "$a" == *"☐"* ]] && A_OPEN+=" $wk"
        [[ "$b" == *"☐"* ]] && B_OPEN+=" $wk"
        [[ "$t" == *"☐"* ]] && T_OPEN+=" $wk"
    done < "$TOPICMAP"

    if [[ -z "$A_OPEN" ]]; then
        pass "All ten Session A blocks marked complete"
    else
        warn "Session A incomplete for week(s):$A_OPEN"
    fi

    if [[ -z "$B_OPEN" ]]; then
        pass "All ten Session B labs marked complete"
    else
        warn "Session B incomplete for week(s):$B_OPEN"
    fi

    if [[ -z "$T_OPEN" ]]; then
        pass "All ten test-outs passed — the whole map is validated"
    else
        warn "Test-out NOT passed for week(s):$T_OPEN — these are pre-identified gaps; drill them before generic review"
    fi
fi

echo ""

# ── Study Artifacts ───────────────────────────────────────────────────────────
echo "── Study Artifacts ──"

MISSING=""
for n in 01 02 03 04 05 06 07 08 09 10 11; do
    for f in cheatsheet.md lab-script.sh audit-script.sh notes.md; do
        [[ -f "$LPDIR/week-$n/$f" ]] || MISSING+=" week-$n/$f"
    done
done
if [[ -z "$MISSING" ]]; then
    pass "All 11 week folders complete (4 files each)"
else
    warn "Missing file(s):$MISSING — regenerate with: Regenerate week [N] [filename]"
fi

SUPP=$(find "$LPDIR"/week-* -name 'supplemental-*' 2>/dev/null | wc -l)
if [[ "$SUPP" -gt 0 ]]; then
    info "$SUPP supplemental file(s) exist — past repeat-verdicts; those topics deserve one final quiz round"
else
    info "No supplemental files — no test-out ever came back 'repeat' (verify that's earned, not skipped)"
fi

if [[ -d "$HOME/homelab/incidents" ]]; then
    pass "incidents/ directory present — week-10 Task 7 source material intact"
fi

echo ""

# ── The Practice-Exam Gate ────────────────────────────────────────────────────
echo "── Practice-Exam Gate (the 80% rule) ──"

if [[ ! -f "$RESULTS" ]]; then
    warn "practice-exam-results.md does not exist — Session A not yet taken or not yet filed (lab Task A1 creates the template)"
else
    pass "Results file exists: $RESULTS"
    SCORE=$(grep -oE '\( *[0-9]+ *% *\)' "$RESULTS" | grep -oE '[0-9]+' | head -1)
    if [[ -z "$SCORE" ]]; then
        warn "No score percentage filled in yet — the 80% decision rule needs the number"
    elif [[ "$SCORE" -ge 80 ]]; then
        pass "Practice score: ${SCORE}% — clears the 80% gate; sit the exam"
    else
        warn "Practice score: ${SCORE}% — below the gate: two lowest domains own the remaining days, then re-test"
    fi
    if grep -qE '^\s*-\s*$' "$RESULTS"; then
        info "Missed-topics section still has empty bullets — finish filing the gaps"
    fi
fi

echo ""

# ── Repo State (the sprint should be committed before exam day) ───────────────
echo "── Repo State ──"

if git -C "$LPDIR" rev-parse --git-dir &>/dev/null; then
    UNTRACKED=$(git -C "$LPDIR" status --porcelain -- . 2>/dev/null | wc -l)
    if [[ "$UNTRACKED" -eq 0 ]]; then
        pass "linuxplus/ fully committed — eleven weeks of work is in history"
    else
        warn "$UNTRACKED uncommitted path(s) under linuxplus/ — commit and push before exam day (git status --short)"
    fi
    AHEAD=$(git -C "$LPDIR" rev-list --count '@{upstream}..HEAD' 2>/dev/null)
    if [[ -n "$AHEAD" && "$AHEAD" -gt 0 ]]; then
        warn "$AHEAD commit(s) not pushed — one laptop failure from losing the sprint record: git push"
    elif [[ -n "$AHEAD" ]]; then
        pass "No unpushed commits (as of last fetch)"
    fi
else
    warn "linuxplus/ is not inside a git repository — that shouldn't be possible; investigate"
fi

echo ""

# ── Logistics (can't be scripted — confirm by hand) ───────────────────────────
echo "── Logistics Checklist (self-attest) ──"
info "Exam booked for the week of Sep 14? (Pearson VUE — book it once the 80% gate clears)"
info "Two forms of ID ready / testing-center route or OnVUE system-check done?"
info "Dion practice exam #2 held in reserve for a re-test if the gate fails?"
info "Night-before plan: one pass of week-11/cheatsheet.md, then stop."

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
echo "  Summary: $PASS passed | $WARN warnings | $INFO informational"
if [[ $WARN -gt 0 ]]; then
    echo "  Every WARN above is a concrete pre-exam action. Clear the list."
else
    echo "  Nothing outstanding. Trust the eleven weeks."
fi
echo "══════════════════════════════════════════════════════"
echo ""
