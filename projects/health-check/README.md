# Health-check

A multi-module Python + Bash system health monitor built as a reverse-engineering exercise

## Purpose

This project is a deliberate learning exercise, not production software. The codebase was written with intentional bugs embedded across all five files - a mix of syntax errors and logic errors at intermediate difficulty. The goal is to read the code carefully, identify every defect without running it first, and fix them. Running it is only for confirmation.

It also serves as a practical introduction to multi-module Python project structure, subprocess orchestration from a main entry point, and the kind of metric collection work that shows up in real sysadmin tooling.

## What it does

Collects system health metrics via Bash script, parses and evaluates them in Python against configurable thresholds, and renders a formatted terminal report with per-metric status, and ASCII progress bar, a weighted overals health score, and an alert for anything in WARN or CRIT state.

```
collect.sh -> /tmp/mudd_snapshot.txt -> collector/parser.py -> analyzer/health.py -> reporter/display.py
```

Metrics collected: CPU usage, memory usage, disk usage, 1 minute load average, uptime, top CPU consuming processes.

## Project Structure

```
mudd-health/
├── collect.sh              # Bash: gathers raw metrics, writes snapshot file
├── main.py                 # Entry point: orchestrates the full pipeline
├── collector/
│   └── parser.py           # Parses snapshot into typed Python dict
├── analyzer/
│   └── health.py           # Evaluates metrics against thresholds, scores health
└── reporter/
    └── display.py          # Formats and prints the terminal report
```

## Usage
 
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
 
Exit codes: `0` = OK or WARN, `2` = CRIT. Intended to be cron-safe.
 
## Dependencies
 
- Python 3.6+
- `mpstat` (from `sysstat` package) — required by `collect.sh`
- `bc` — used for floating point arithmetic in the shell script
- Standard library only on the Python side
Install sysstat if needed:
```bash
# Fedora / RHEL
sudo dnf install sysstat bc
 
# Ubuntu / Debian
sudo apt install sysstat bc
```
 
## The Exercise
 
There are five intentional bugs in this codebase. One in `collect.sh`, two in `collector/parser.py`, one in `analyzer/health.py` (actually in `main.py`), and one in `reporter/display.py`. Read each file before running anything. The goal is to build the habit of reading code as a diagnostic tool, not relying on the runtime to surface problems.
 
Document your findings before fixing. What file, what line, what's wrong, and what it should be.
 
---
 
*Part of Mudd Labs — projects/health-check*
 
