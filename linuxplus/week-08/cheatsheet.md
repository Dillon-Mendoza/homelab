# Week 08 — Bash Scripting + Python Basics
# Domain: 4.0 Automation, Orchestration, and Scripting (17%) | Objectives: 4.2, 4.3
# Calendar: Aug 17–23 | Session A — 45 min read
# Performance-based questions concentrate here: expect "fix this script" and
# "what does this output" formats, not definitions.

---

## Objective 4.2 — Bash Scripting

### Script Skeleton — Every Line Has a Job

```bash
#!/bin/bash                  # interpreter directive — must be line 1
set -e                       # exit on any command failure
set -u                       # error on undefined variables
set -o pipefail              # a pipeline fails if ANY stage fails (not just the last)
trap 'rm -rf "$TMPDIR"' EXIT # cleanup that runs no matter HOW the script exits
```

`set -x` prints each command before executing it (with `+ ` prefix) — the first move when debugging someone else's script: `bash -x script.sh`.

### Variables and Assignment Rules

```bash
NAME=value            # NO spaces around = — 'NAME = value' runs NAME as a command
export NAME           # child processes now inherit it (without export they don't)
local var=1           # inside a function: scoped to the function
unset NAME            # remove it;  unalias ll  removes an alias
readonly PIN=42       # constant
```

**Positional parameters:** `$1 $2 ...` args, `$0` script name, `$#` arg count, `$@` all args (quote it: `"$@"` preserves per-arg word boundaries), `$?` last exit code, `$$` own PID.

### Expansion — the Highest-Density Exam Table

| Syntax | Meaning | Example (`f=/var/log/dnf.log`) |
|---|---|---|
| `${var}` | Plain expansion (braces disambiguate: `${x}y`) | — |
| `${var:-default}` | Value, or default if unset/empty | `${1:-chronyd}` — default arg |
| `${var:=default}` | Same, but also *assigns* the default | — |
| `${var:?msg}` | Error out with msg if unset | cheap arg validation |
| `${#var}` | String length | — |
| `${var#pat}` / `${var##pat}` | Strip shortest / longest match from **front** | `${f##*/}` → `dnf.log` (basename) |
| `${var%pat}` / `${var%%pat}` | Strip shortest / longest from **back** | `${f%.*}` → `/var/log/dnf` (drop extension) |
| `${var/old/new}` | Replace first (`//` = all) | — |
| `$(cmd)` | Command substitution — **nests cleanly** | `$(dirname $(which bash))` |
| `` `cmd` `` | Same thing, legacy — nesting requires escaping. Recognize it; write `$()` | — |
| `$(( expr ))` | Arithmetic | `$(( 5 / 2 ))` → `2` (integer only!) |
| `(cmd)` | **Subshell** — runs in a copy; variable changes and `cd` don't escape it | `(cd /tmp && ls)` — you're still where you were |

Front/back mnemonic: `#` is left of `%` on the keyboard number row → `#` trims the left (front), `%` trims the right (back).

### Tests — [ ] vs [[ ]]

`[` **is a command** (alias of `test`) — every operand must be quoted and word-split rules apply. `[[ ]]` is bash **syntax** — no word splitting inside, supports `&&`, `||`, `=~`, unquoted variables are safe. **Write `[[ ]]`; be able to read `[ ]`.**

| Numeric (integers) | String | Files |
|---|---|---|
| `-eq` equal | `=` / `==` equal | `-f` regular file exists |
| `-ne` not equal | `!=` not equal | `-d` directory exists |
| `-lt` / `-le` less | `<` / `>` **lexicographic** sort order | `-e` exists (any type) |
| `-gt` / `-ge` greater | `-z` string is empty | `-r` / `-w` / `-x` readable/writable/executable |
| | `-n` string is non-empty | `-s` exists and non-empty |

**The classic trap:** `[[ 10 -gt 9 ]]` is true (numeric); `[[ "10" > "9" ]]` is **false** ("1" sorts before "9" lexicographically). Mixing the operator families silently inverts answers.

**Regex:** `[[ "$str" =~ ^[0-9]+$ ]]` — regex on the right, **unquoted** (quotes make it a literal string match). Capture groups land in `BASH_REMATCH`: after `[[ "eth0:1500" =~ ^(.+):([0-9]+)$ ]]`, `${BASH_REMATCH[1]}` is `eth0`, `[2]` is `1500`.

### Conditionals and Loops

```bash
if [[ -f "$1" ]]; then ... elif ...; then ... else ... fi

case "$1" in
    start|restart) systemctl restart "$svc" ;;
    st*)           echo "status" ;;          # glob patterns, not regex
    *)             echo "usage: ..."; exit 2 ;;
esac

for svc in sshd chronyd tailscaled; do ... done       # word list
for i in {1..5}; do ... done                          # brace range
for ((i=0; i<5; i++)); do ... done                    # C-style
while read -r line; do ... done < /etc/hosts          # THE file-reading idiom
until systemctl is-active -q myservice; do sleep 1; done   # loop while FALSE
```

Arrays: `svcs=(sshd chronyd)`, iterate `"${svcs[@]}"`, count `${#svcs[@]}`.

### Functions, Exit Codes, IFS

```bash
check() {
    local name="$1"              # local or it leaks into the caller
    systemctl is-active -q "$name"
    return $?                    # functions return 0-255, same as scripts exit
}
check sshd && echo up || echo down
```

- **Exit codes:** `0` = success/true, non-zero = failure — **the reverse of Python/C truthiness inside the language**. `exit 2` conventionally = usage error. `$?` holds the last one, and is itself overwritten by every command — capture it immediately (`rc=$?`).
- **IFS** (Internal Field Separator) — what `read` and word-splitting split on; default space/tab/newline. Parse delimited data by overriding it *for one command*:
  `IFS=: read -r user _ uid _ <<< "$(getent passwd $USER)"` — colon-split into variables. `OFS` is awk's output twin.

---

## Objective 4.3 — Python Basics

### venv — the Non-Negotiable Workflow

```bash
python3 -m venv .venv               # create (a directory of its own interpreter+libs)
source .venv/bin/activate           # enter — prompt gains (.venv), pip now installs HERE
pip install requests                # dependencies land in .venv, not the system
pip list / pip freeze > requirements.txt
deactivate                          # leave
```

Why it's tested: `pip install` into the system Python can conflict with `dnf`-managed packages (Fedora will actively refuse — "externally-managed-environment"). One venv per project, always. Muddroom should live in one.

### Data Types — Know the Mutability Column

| Type | Literal | Ordered? | Mutable? | Sysadmin use |
|---|---|---|---|---|
| `bool` | `True` / `False` (capitalized!) | — | — | flags |
| `int` / `float` | `42` / `0.94` | — | — | `/proc` values — note `int("42")` conversion |
| `str` | `"text"` | ✓ | **No** — methods return new strings | everything |
| `list` | `[1, 2]` | ✓ | ✓ | command output lines |
| `tuple` | `(1, 2)` | ✓ | **No** | fixed records (immutable list) |
| `dict` | `{"key": "val"}` | insertion-ordered | ✓ | config, JSON |
| `set` | `{1, 2}` | ✗ | ✓ | dedup, membership tests |

`list` vs `tuple` = mutable vs immutable is the exam's favorite pair. `str.split()` returns a `list`: `open('/proc/loadavg').read().split()` → `['0.52', '0.61', ...]` — then `float(fields[0])`.

### Fundamentals the Exam Names

- **Indentation is syntax** — blocks are defined by consistent indentation (PEP 8: 4 spaces, never tabs mixed with spaces → `IndentationError`/`TabError` are *syntax* errors, not style complaints).
- **Python 3.x** is current; `python3` is the binary on this laptop (`python3 --version`).
- **Extensible via modules** — `import` from a huge stdlib or pip-installed packages.
- **PEP 8** — the style convention: 4-space indent, `snake_case` functions/variables, `UPPER_CASE` constants, imports at top. Enough to answer "which line violates PEP 8."

### Stdlib Modules for Sysadmin Work

| Module | Job | One-liner |
|---|---|---|
| `sys` | args, exit codes | `sys.argv[1]`, `sys.exit(1)` |
| `os` | env, paths, uid | `os.environ.get("HOME")`, `os.getuid()` |
| `pathlib` | modern paths | `Path("/proc/loadavg").read_text()` |
| `subprocess` | run commands | `subprocess.run(["systemctl","is-active",svc])` → `.returncode` |
| `json` | parse/emit JSON | `json.loads(text)` → dicts and lists |
| `shutil` | copy/move/disk | `shutil.disk_usage("/")` |
| `argparse` | real CLI parsing | flags, help text, type conversion |

The bridge between the two objectives: `subprocess.run([...]).returncode == 0` is Python reading bash's exit-code convention — success is `0` there, even though `0` is falsy in Python. Session B's port of the health-check script makes you feel that seam.

---

## Quick Recall

`NAME = value` — broken; assignment allows no spaces
`${var:-default}` — use default if unset; `:=` also assigns it
`${f##*/}` — basename; `${f%.*}` — strip extension (# front, % back)
`$()` nests; backticks don't — recognize both, write `$()`
`$(( ))` — integer arithmetic only; 5/2 is 2
`(cmd)` — subshell: cd and variable changes die with it
`[[ ]]` — bash syntax, safe unquoted, has `=~`; `[ ]` — the `test` command, quote everything
`-eq` numbers, `=` strings; `[[ "10" > "9" ]]` is FALSE (lexicographic)
`=~` regex must be unquoted; groups in `BASH_REMATCH`
`while read -r line; do ...; done < file` — the file-reading idiom
`local` — without it, function variables leak to the caller
Exit 0 = success; `$?` is overwritten by every command — capture immediately
`IFS=: read -r a b c` — split one line on colons
`set -e` exit on error; `set -u` undefined vars; `set -o pipefail` any-stage failure
`trap '...' EXIT` — cleanup that survives crashes
venv: `python3 -m venv .venv && source .venv/bin/activate` — pip stays contained
tuple immutable, list mutable — the tested pair
`True`/`False` capitalized; 4-space indent is law (PEP 8); indentation errors are syntax errors
`subprocess.run([...]).returncode` — bash's exit codes read from Python
