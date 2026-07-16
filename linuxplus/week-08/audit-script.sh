#!/bin/bash
# Week 08 Audit — Script Hygiene Across the Homelab Repo
# Re-run anytime. Applies this week's standards to every shell and Python
# script already in ~/homelab: shebangs, syntax, safety rails, secrets,
# and permissions. Your own repo is the audit target.
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
echo "  AUDIT: Script Hygiene — $REPO"
echo "  Host: $(hostname) | $(date)"
echo "══════════════════════════════════════════════════════"
echo ""

if [[ ! -d "$REPO" ]]; then
    warn "$REPO not found — pass the repo path as the first argument"
    exit 1
fi

mapfile -t SHELL_SCRIPTS < <(find "$REPO" -name '*.sh' -type f ! -path '*/.git/*' 2>/dev/null)
mapfile -t PY_SCRIPTS < <(find "$REPO" -name '*.py' -type f ! -path '*/.git/*' ! -path '*/.venv/*' 2>/dev/null)
info "Found ${#SHELL_SCRIPTS[@]} shell script(s), ${#PY_SCRIPTS[@]} Python script(s)"

echo ""

# ── Shell: Syntax ─────────────────────────────────────────────────────────────
echo "── Shell Syntax (bash -n) ──"

SYNTAX_BAD=0
for s in "${SHELL_SCRIPTS[@]}"; do
    if ! bash -n "$s" 2>/dev/null; then
        warn "SYNTAX ERROR: $s"
        ((SYNTAX_BAD++))
    fi
done
[[ "$SYNTAX_BAD" -eq 0 && ${#SHELL_SCRIPTS[@]} -gt 0 ]] && pass "All ${#SHELL_SCRIPTS[@]} shell scripts parse clean"

echo ""

# ── Shell: Shebangs ───────────────────────────────────────────────────────────
echo "── Shebangs ──"

NO_SHEBANG=0
for s in "${SHELL_SCRIPTS[@]}"; do
    if ! head -1 "$s" | grep -q '^#!'; then
        warn "no shebang: $s"
        ((NO_SHEBANG++))
    fi
done
[[ "$NO_SHEBANG" -eq 0 && ${#SHELL_SCRIPTS[@]} -gt 0 ]] && pass "Every shell script declares its interpreter"

echo ""

# ── Shell: Safety Rails ───────────────────────────────────────────────────────
echo "── Safety Rails (set -e / -u / pipefail, trap) ──"

for s in "${SHELL_SCRIPTS[@]}"; do
    base=${s#"$REPO"/}
    RAILS=""
    grep -qE '^\s*set\s+.*-.*e|set -o errexit' "$s" && RAILS+="e"
    grep -qE 'set\s+.*-.*u|set -o nounset' "$s" && RAILS+="u"
    grep -q 'pipefail' "$s" && RAILS+="p"
    grep -qE '^\s*trap ' "$s" && RAILS+="t"
    if [[ -z "$RAILS" ]]; then
        info "no rails ($base) — fine for read-only scripts; risky if it modifies state"
    fi
done
pass "Safety-rail scan complete (rails are a judgment call, flagged not failed)"

echo ""

# ── Shell: Legacy Constructs ──────────────────────────────────────────────────
echo "── Legacy Constructs ──"

BACKTICKS=$(grep -lE '\`[^\`]+\`' "${SHELL_SCRIPTS[@]}" 2>/dev/null)
if [[ -z "$BACKTICKS" ]]; then
    pass "No backtick command substitution — \$() everywhere"
else
    info "Backticks found (works, but \$() nests and reads better):"
    echo "$BACKTICKS" | while read -r f; do echo "    ${f#"$REPO"/}"; done
fi

echo ""

# ── Secrets Scan ──────────────────────────────────────────────────────────────
echo "── Hardcoded Secrets Scan ──"

SECRETS=$(grep -rniE '(password|passwd|token|api_key|secret)\s*=\s*["'"'"'][^"'"'"']{4,}' \
    "${SHELL_SCRIPTS[@]}" "${PY_SCRIPTS[@]}" 2>/dev/null | grep -viE 'example|placeholder|CHANGE|<|\$\{|\$\(' | head -5)
if [[ -z "$SECRETS" ]]; then
    pass "No hardcoded credential patterns in scripts"
else
    warn "Possible hardcoded secret(s) — review each:"
    echo "$SECRETS" | while read -r line; do echo "    ${line:0:100}"; done
fi

echo ""

# ── Permissions ───────────────────────────────────────────────────────────────
echo "── Script Permissions ──"

WW_SCRIPTS=$(find "$REPO" \( -name '*.sh' -o -name '*.py' \) -type f -perm -0002 ! -path '*/.git/*' 2>/dev/null)
if [[ -z "$WW_SCRIPTS" ]]; then
    pass "No world-writable scripts (a world-writable script is a privilege-escalation gift)"
else
    warn "World-writable script(s):"
    echo "$WW_SCRIPTS" | while read -r f; do echo "    $f"; done
fi

for s in "${SHELL_SCRIPTS[@]}"; do
    if [[ -x "$s" ]] && ! head -1 "$s" | grep -q '^#!'; then
        warn "executable but no shebang: ${s#"$REPO"/} — runs under whatever shell invokes it"
    fi
done

echo ""

# ── Python ────────────────────────────────────────────────────────────────────
echo "── Python (py_compile + venv discipline) ──"

PY_BAD=0
for p in "${PY_SCRIPTS[@]}"; do
    if ! python3 -m py_compile "$p" 2>/dev/null; then
        warn "does not compile: ${p#"$REPO"/}"
        ((PY_BAD++))
    fi
done
[[ "$PY_BAD" -eq 0 && ${#PY_SCRIPTS[@]} -gt 0 ]] && pass "All ${#PY_SCRIPTS[@]} Python scripts compile (no syntax/indentation errors)"
[[ ${#PY_SCRIPTS[@]} -eq 0 ]] && info "No Python scripts in the repo yet — this week's loadavg.py is a candidate first resident"

VENVS=$(find "$REPO" -name 'pyvenv.cfg' ! -path '*/.git/*' 2>/dev/null | wc -l)
info "$VENVS venv(s) inside the repo (each project should own one; none should be committed — check .gitignore)"

USERPKGS=$(pip list --user 2>/dev/null | tail -n +3 | wc -l)
if [[ "$USERPKGS" -eq 0 ]]; then
    pass "No --user pip packages outside venvs (system Python stays dnf-managed)"
else
    info "$USERPKGS pip package(s) installed with --user — consider moving into per-project venvs"
fi

echo ""

# ── shellcheck (bonus, if installed) ──────────────────────────────────────────
echo "── shellcheck ──"

if command -v shellcheck &>/dev/null; then
    SC_ISSUES=0
    for s in "${SHELL_SCRIPTS[@]}"; do
        n=$(shellcheck -f gcc "$s" 2>/dev/null | wc -l)
        (( SC_ISSUES += n ))
    done
    info "shellcheck reports $SC_ISSUES total finding(s) across the repo — triage: shellcheck <file>"
else
    info "shellcheck not installed — 'sudo dnf install shellcheck' adds a professional-grade linter to every future script"
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
