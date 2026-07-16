#!/bin/bash
# Week 09 Audit — Git Repo Health (the homelab repo itself)
# Re-run anytime. Checks working-tree cleanliness, remote sync state, the
# dual-remote push config, identity, ignored-vs-tracked hygiene, and
# accidentally committed secrets.
# Run on: tp-mudd (Fedora 44) only.

PASS=0
WARN=0
INFO=0

pass() { echo "[PASS] $*"; ((PASS++)); }
warn() { echo "[WARN] $*"; ((WARN++)); }
info() { echo "[INFO] $*"; ((INFO++)); }

REPO="${1:-$HOME/homelab}"

echo ""
echo "══════════════════════════════════════════════════════"
echo "  AUDIT: Git Repo Health — $REPO"
echo "  Host: $(hostname) | $(date)"
echo "══════════════════════════════════════════════════════"
echo ""

if ! git -C "$REPO" rev-parse --git-dir &>/dev/null; then
    warn "$REPO is not a git repository — pass the repo path as the first argument"
    exit 1
fi
cd "$REPO" || exit 1

# ── Identity ──────────────────────────────────────────────────────────────────
echo "── Identity ──"

UNAME=$(git config user.name)
UEMAIL=$(git config user.email)
if [[ -n "$UNAME" && -n "$UEMAIL" ]]; then
    pass "Commit identity set: $UNAME <$UEMAIL>"
else
    warn "user.name or user.email unset — commits will carry a wrong/empty identity"
fi

echo ""

# ── Working Tree ──────────────────────────────────────────────────────────────
echo "── Working Tree ──"

DIRTY=$(git status --porcelain | wc -l)
if [[ "$DIRTY" -eq 0 ]]; then
    pass "Working tree clean — everything is committed"
else
    info "$DIRTY uncommitted path(s) — fine mid-work; review with: git status --short"
fi

STASHES=$(git stash list | wc -l)
if [[ "$STASHES" -eq 0 ]]; then
    pass "No forgotten stashes"
else
    warn "$STASHES stash(es) sitting in the pile — stashes are where work goes to be forgotten: git stash list"
fi

BRANCH=$(git branch --show-current)
info "Current branch: ${BRANCH:-DETACHED HEAD$(git rev-parse --short HEAD 2>/dev/null | sed 's/^/ at /')}"
[[ -z "$BRANCH" ]] && warn "Detached HEAD — commits made here can be lost; create a branch"

echo ""

# ── Remotes + Sync State ──────────────────────────────────────────────────────
echo "── Remotes (dual-push: Gitea + GitHub) ──"

PUSH_URLS=$(git remote get-url --push --all origin 2>/dev/null | wc -l)
if [[ "$PUSH_URLS" -ge 2 ]]; then
    pass "origin has $PUSH_URLS push URLs — dual-remote push intact:"
    git remote get-url --push --all origin | while read -r u; do echo "    $u"; done
else
    warn "origin has only $PUSH_URLS push URL — the dual Gitea+GitHub push is not configured (see CLAUDE.md)"
fi

if [[ -n "$BRANCH" ]]; then
    UPSTREAM=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
    if [[ -n "$UPSTREAM" ]]; then
        AHEAD=$(git rev-list --count '@{upstream}..HEAD' 2>/dev/null)
        BEHIND=$(git rev-list --count 'HEAD..@{upstream}' 2>/dev/null)
        if [[ "$AHEAD" -eq 0 ]]; then
            pass "No unpushed commits (in sync with $UPSTREAM as of last fetch)"
        else
            warn "$AHEAD commit(s) not pushed — one laptop failure from being lost: git push"
        fi
        [[ "$BEHIND" -gt 0 ]] && info "$BEHIND commit(s) behind $UPSTREAM (as of last fetch) — git pull when convenient"
    else
        info "Branch '$BRANCH' has no upstream — push with -u to set one"
    fi
fi

LAST_COMMIT_AGE=$(( ( $(date +%s) - $(git log -1 --format=%ct 2>/dev/null) ) / 86400 ))
if [[ "$LAST_COMMIT_AGE" -le 14 ]]; then
    pass "Last commit ${LAST_COMMIT_AGE}d ago — repo is alive"
else
    info "Last commit ${LAST_COMMIT_AGE}d ago — documentation debt accumulating?"
fi

echo ""

# ── Ignore Hygiene ────────────────────────────────────────────────────────────
echo "── .gitignore Hygiene ──"

if [[ -f .gitignore ]]; then
    pass ".gitignore exists"
    for pat in '.venv' '__pycache__'; do
        if grep -q "$pat" .gitignore; then
            pass "$pat is ignored"
        else
            info "$pat not in .gitignore — add before a venv or cache lands in history"
        fi
    done
else
    warn "No .gitignore — first venv or editor swap file will offer itself for commit"
fi

TRACKED_IGNORED=$(git ls-files -i -c --exclude-standard 2>/dev/null | head -5)
if [[ -z "$TRACKED_IGNORED" ]]; then
    pass "No tracked files that match ignore rules (.gitignore ≠ untrack — this catches the gap)"
else
    warn "Tracked files matching .gitignore (git rm --cached to untrack):"
    echo "$TRACKED_IGNORED" | while read -r f; do echo "    $f"; done
fi

echo ""

# ── Secrets in History-Adjacent Places ────────────────────────────────────────
echo "── Committed Secrets Scan ──"

RISKY_FILES=$(git ls-files | grep -iE '(^|/)(id_rsa|id_ed25519|.*\.pem|.*\.key|\.env)$' | grep -vE '\.pub$|authorized_keys' | head -5)
if [[ -z "$RISKY_FILES" ]]; then
    pass "No private-key/.env filenames tracked"
else
    warn "Tracked file(s) that usually hold secrets — verify each is safe to publish (this repo pushes to GitHub):"
    echo "$RISKY_FILES" | while read -r f; do echo "    $f"; done
fi

INLINE=$(git grep -lniE '(password|token|api_key)\s*=\s*["'"'"'][A-Za-z0-9]{8,}' -- '*.sh' '*.py' '*.md' 2>/dev/null | head -3)
if [[ -z "$INLINE" ]]; then
    pass "No inline credential patterns in tracked scripts/docs"
else
    warn "Possible inline credentials in tracked files:"
    echo "$INLINE" | while read -r f; do echo "    $f"; done
fi

echo ""

# ── Repo Weight ───────────────────────────────────────────────────────────────
echo "── Repo Weight ──"

BIG=$(git ls-files -z | xargs -0 -I{} du -k "{}" 2>/dev/null | awk '$1 > 5120 {print $2 " (" int($1/1024) "MB)"}' | head -3)
if [[ -z "$BIG" ]]; then
    pass "No tracked files over 5MB (git stores every version of big files forever)"
else
    info "Large tracked file(s):"
    echo "$BIG" | while read -r f; do echo "    $f"; done
fi

info "Branches: $(git branch | wc -l) local | Tags: $(git tag | wc -l)"

echo ""

# ── Automation Tooling Presence ───────────────────────────────────────────────
echo "── Automation Tooling ──"

if command -v ansible &>/dev/null; then
    pass "ansible available: $(ansible --version 2>/dev/null | head -1)"
else
    info "ansible not installed (lab Task 5 installs ansible-core)"
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
echo "  Summary: $PASS passed | $WARN warnings | $INFO informational"
if [[ $WARN -gt 0 ]]; then
    echo "  Review WARN items above before moving on."
fi
echo "══════════════════════════════════════════════════════"
echo ""
