# Week 08 — Reference Notes
# Objectives: 4.2, 4.3 | Calendar: Aug 17–23

---

## Exam Objective Mapping

**4.2 — Given a scenario, perform automated tasks using shell scripting**
- Variables: environmental, positional (`$1`, `$2`), `export`, `local`, `alias`, `set`, `unset`, `unalias`
- Expansion: `${var}`, `$(cmd)` / backticks, subshell `(cmd)`
- IFS/OFS; conditionals (`if`, `case`); loops (`for`, `while`, `until`); functions
- Comparisons: numeric (`-eq -ne -lt -le -gt -ge`), string (`= != < > == =~`)
- Test operators: `-f -d -z -n`; regex `[[ =~ ]]`; return codes `$?`; `#!/bin/bash`

**4.3 — Summarize Python basics used for Linux system administration**
- `python3 -m venv`; `pip install`
- Data types: boolean, integer, float, string, list, dictionary
- Indentation as syntax; Python 3.x; extensible via modules
- Built-in modules for sysadmin work; PEP 8

---

## Key Man Pages

`man bash` — three targeted searches, not a read-through: `/Parameter Expansion` (Task 1's table in canonical form), `/CONDITIONAL EXPRESSIONS` (every test operator), `/^SHELL BUILTIN` then find `set` (what -e/-u/-x/pipefail each do, precisely).

`help test` and `help [[` — the *builtin* help system, often forgotten: instant operator reference without leaving the terminal. `help trap`, `help local`, `help return` likewise — builtins aren't in section 1 man pages.

`man 1 python3` — thin, but documents `-m` (how `python3 -m venv` and `-m py_compile` work: run a module as a script).

For Python itself the primary source is docs.python.org — the `venv`, `subprocess`, and `pathlib` pages map 1:1 to this week's lab. Treat "the docs" as Python's man pages; knowing where answers live is the durable skill.

`man shellcheck` (if installed) — the audit script points every finding at a wiki code (SC2086 etc.); each code's page is a micro-lesson in exactly one scripting mistake.

---

## Video Timestamps

**Theory Course (12hr — nGPK6YBbKpg):**
The Domain 4 block opens with "Shell Scripting" (4.2) followed by "Python Basics" (4.3). The scripting section will move fast through the comparison operators — pause and predict outputs before the presenter runs anything; passive watching does nothing for performance-based questions.

**Labs Course (7hr — JXIaR23OdB8):**
The scripting lab likely builds something similar to check-service.sh. Watch it AFTER you've passed the grader with your own version — comparing three implementations (yours, theirs, the reference) is far more instructive than following along with one.

---

## Book Reference — How Linux Works, 3rd Ed. (Ward)

**Ch. 11 — Introduction to Shell Scripting**
The topic-map assigns this before Session B, and that's the right order: read it, then build. It covers quoting (the deepest treatment you'll find at this level), variables, conditionals, loops, and — critically — *when not to write a shell script*, which is the judgment behind Task 7's port-to-Python question. Ward's quoting section explains the `"$@"` vs `$@` distinction better than the man page does.

**Ch. 13 — User Environments (third appearance)**
Week 1 used it for startup files, Week 4 for /etc/skel; this week it closes the loop on *why* your interactive shell and your script see different environments — non-login non-interactive shells read none of your aliases or bashrc functions. When a script works in your terminal but fails from cron (Week 5), this chapter is the explanation.

**Python:** outside the book's scope by design. docs.python.org's tutorial chapters 3–5 cover 4.3's entire surface if you want prose; the lab plus the reference solution covers it if you want practice.

---

## Things That Trip People Up

**1. `[[ "10" > "9" ]]` is false**
String `>` compares sort order character by character: `"1" < "9"`, comparison over. Numeric intent needs `-gt`. Any exam question comparing numbers with `>` inside `[[ ]]` (or worse, unescaped inside `[ ]`, where it's a redirect!) is testing this. Task 2a made you produce both answers side by side.

**2. Quoting the regex kills it**
`[[ $s =~ "^abc$" ]]` matches the literal string `^abc$`, not the pattern. The regex side of `=~` must be unquoted (or stored in a variable and expanded unquoted — the robust idiom: `re='^[0-9]+$'; [[ $x =~ $re ]]`).

**3. `set -e` has blind spots**
It does NOT trigger for failures inside `if` conditions, `&&`/`||` chains, or non-final pipeline stages (without `pipefail`). A script can `set -e` and still sail past a failed `grep | sort`. The full rail set is `set -euo pipefail` — and even then, trap EXIT for cleanup because `-e` deaths skip your final lines (Task 4a's demo).

**4. `$?` is perishable**
Every command overwrites it — including the `echo` you added to debug. `cmd; echo "rc=$?"` works; `cmd; echo done; echo "rc=$?"` reports echo's success. Capture immediately: `rc=$?`.

**5. Missing `local` makes function variables global**
`myfunc() { count=5; }` silently sets `count` for the whole script — a spooky-action bug that surfaces far from its cause. Every variable in every function gets `local` unless leaking is the explicit intent.

**6. Exit-code truthiness flips at the Python border**
In bash, 0 is success and behaves as "true" in `if systemctl is-active`. In Python, `0` is falsy — so `if subprocess.run(...).returncode:` is the *failure* branch. Task 7's one-sentence question exists because this seam produces real bugs in exactly the wrapper scripts sysadmins write most.

---

## Connect to the Homelab

This is the week the study system and the homelab merge into the same activity. The repo already contains working scripts — the network-monitor and health-check tooling, four generations of lab and audit scripts — and the audit this week turns *your own codebase* into the assessment target: shebangs, `bash -n`, secrets scan, world-writable checks, all run against `~/homelab` itself. The lab's build exercise isn't hypothetical either: `check-fleet.sh` with its array-loop, function, and timestamped log is a strictly better version of an ad-hoc health check, and the cleanup step says it plainly — promote it into `~/homelab/scripts/` with a commit rather than letting it die in `/tmp`. Same for Python: Muddroom is a Python project developed on this laptop, so the venv discipline in Task 6 (and the audit's `pip list --user` check) is its development hygiene, not exam trivia. Looking one week ahead: Week 9's Ansible and Git material will assume exactly the scripting fluency built here — and the systemd timer from Week 5's notes plus this week's `check-fleet.sh` combine into a real scheduled monitor whenever you're ready to wire them together.
