#!/usr/bin/env python3
# main.py — Entry point for mudd_health
# Usage:
#   python3 main.py           — full report
#   python3 main.py --summary — one-line summary only
#   python3 main.py --collect — run collect.sh first, then report

import sys
import os
import subprocess

# Ensure project root is importable regardless of cwd
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from collector.parser import parse_snapshot
from analyzer.health  import analyze
from reporter.display import print_report, print_summary

COLLECT_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "collect.sh")


def run_collector():
    """Execute collect.sh to refresh the snapshot."""
    if not os.path.exists(COLLECT_SCRIPT):
        print(f"[main] collect.sh not found at {COLLECT_SCRIPT}")
        sys.exit(1)

    result = subprocess.run(["bash", COLLECT_SCRIPT], capture_output=True, text=True)

    if result.returncode == 0:
        print(result.stdout.strip())
    else:
        print(f"[main] collect.sh failed:\n{result.stderr}")
        sys.exit(1)


def main():
    args = sys.argv[1:]

    run_collect = "--collect" in args
    summary_only = "--summary" in args

    if run_collect:
        run_collector()

    metrics = parse_snapshot()

    if metrics is None:
        print("[main] No snapshot data. Run with --collect to generate one.")
        sys.exit(1)

    report = analyze(metrics)

    if summary_only:
        print_summary(report)
    else:
        print_report(report, metrics)

    # Exit with a non-zero code if status is not OK — useful for cron alerting
    if report["overall_status"] == "OK":
        sys.exit(0)
    elif report["overall_status"] == "WARN":
        sys.exit(1)
    else:
        sys.exit(2)


if __name__ == "__main__":
    main()