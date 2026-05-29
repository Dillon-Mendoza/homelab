# health-check

A multi-module Python + Bash system health monitor for Linux devices. Collects real-time system metrics, evaluate them against configurable thresholds, and renders a formatted terminal report with per-metric status, weighted health score, and alerts.

This project was provided as a structured debugging exercise. The Python codebase and Bash collector were written by Claude with five intentional bugs embedded across all files. My contributions were: identifying and fixing all five bugs through code reading before the tool was ever run, writing `requirements.sh` from scratch, and validating the full pipeline across two devices.

---

## What It Does

`collect.sh` gathers raw system metrics and writes them to a snapshot file. The Python pipeline reads that snapshot, evaluates each metricm and prints a full terminal report.

```
collect.sh -> /tmp/mudd_snapshot.txt -> collector/parser.py -> analyzer/health.py -> reporter/display.py
```

Metrics collected:
- CPU usage (%)
- Memory usage (%)
- Disk Usage on root partition (%)
- 1 Minute load average
- System uptime
- Top 3 CPU consuming processes

Each metric is evaluated against warn and critical thresholds. A weighted score from 0-100 is calculated across all metrics and an overall status of OK, WARN, or CRIT is reported.

---

## Sample Output

```
╔══════════════════════════════════════╗
║       MUDD HEALTH — SYSTEM REPORT    ║
╚══════════════════════════════════════╝
  Report time : 2026-05-28 19:08:52
  Snapshot ts : 1780016931
 
  CPU Usage     [░░░░░░░░░░░░░░░░░░░░]     1.1%  ✓ OK
  Memory Usage  [██████░░░░░░░░░░░░░░]    30.0%  ✓ OK
  Disk Usage    [████████████░░░░░░░░]    61.0%  ✓ OK
  Load Avg 1m   [░░░░░░░░░░░░░░░░░░░░]     0.2%  ✓ OK
 
  Uptime      : 11d 59m
  Top procs   : python3:6.1, sshd:0.3, packagekitd:0.3
 
  ── Overall ─────────────────────────
  Score       : 100.0/100
  Status      : OK
```

---

## Project Structure

```
health-check/
├── collect.sh              # Bash: gathers raw metrics, writes snapshot file
├── main.py                 # Entry point: orchestrates the full pipeline
├── requirements.sh         # OS-aware dependency installer — written by Mudd
├── .gitignore
├── collector/
│   └── parser.py           # Parses snapshot file into typed Python dict
├── analyzer/
│   └── health.py           # Evaluates metrics against thresholds, scores health
└── reporter/
    └── display.py          # Formats and prints the terminal report
```
 
---

## Setup

### 1. Clone the repo

```bash
git clone <repo-url>
cd health-check
```

### 2. Install system dependencies

A setup script handles OS detection and installs the required packages automatically

```bash
chmod +x requirements.sh
./requirements.sh
```

Supports Fedora/REHL (`dnf`) and Ubuntu/Debian (`apt`). For other distributions, install `sysstat` and `bc` manually using your package manager.

### 3. Run

```bash
# Collect fresh metrics and print full report
python3 main.py --collect

# Full report using existing snapshot (no re-collect)
python3 main.py

# One-line summary — suitable for cron or logging
python3 main.py --summary
 
# Collect + summary
python3 main.py --collect --summary
```
 
---
 
## Dependencies
 
| Dependency | Type | Used by |
|---|---|---|
| Python 3.6+ | Runtime | All Python modules |
| `sysstat` (`mpstat`) | System package | `collect.sh` |
| `bc` | System package | `collect.sh` |
| Standard library only | Python | No pip install needed |
 
---
 
## Thresholds
 
Default thresholds are defined in `analyzer/health.py` and can be adjusted directly.
 
| Metric | Warn | Critical |
|---|---|---|
| CPU usage | 75% | 90% |
| Memory usage | 70% | 85% |
| Disk usage | 80% | 95% |
| Load average (1m) | 2.0 | 4.0 |
 
---
 
## Exit Codes
 
| Code | Meaning |
|---|---|
| `0` | OK |
| `1` | WARN |
| `2` | CRIT |
 
Exit codes make the tool cron-safe — a monitoring wrapper or alerter can act on non-zero returns.
 
---
 
## My Contributions
 
The Python modules and `collect.sh` were provided as a debugging exercise and were not written by me. My work on this project:
 
**Debugging** — Found and fixed five intentional bugs by reading the code before running it:
 
1. `collect.sh` — missing system dependencies (`sysstat`, `bc`) not declared for the target environment
2. `collector/parser.py` — invalid operator `=%` instead of `%=` (modulus assignment) in `format_uptime`
3. `collector/parser.py` — broken indentation on `if days`, `if hours`, and `return` blocks inside `format_uptime`
4. `main.py` — WARN status returned `sys.exit(0)` contradicting the stated intent of non-zero exit on non-OK status
5. `reporter/display.py` — import statement buried inside a function body instead of declared at the top of the file

**requirements.sh** — Written from scratch. Uses `/etc/os-release` with a `^ID=` anchor to detect the OS and route to the correct package manager (`dnf` or `apt`).
 
**Testing** — Validated the full pipeline on two devices running different distributions.
 
---
 
## Tested On
 
- Fedora 43 Server (KVM/QEMU VM)
- Ubuntu 24.04 LTS Server

---
 
*Part of Mudd Labs — projects/health-check*
 