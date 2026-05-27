# reporter/display.py
# Formats and prints the health report to stdout.
# Supports plain text and a compact summary mode.

import datetime

STATUS_COLORS = {
    "OK":      "\033[92m",  # green
    "WARN":    "\033[93m",  # yellow
    "CRIT":    "\033[91m",  # red
    "UNKNOWN": "\033[90m",  # grey
}
RESET = "\033[0m"


def colorize(status, text):
    color = STATUS_COLORS.get(status, "")
    return f"{color}{text}{RESET}"


def status_icon(status):
    return {
        "OK":      "✓",
        "WARN":    "⚠",
        "CRIT":    "✗",
        "UNKNOWN": "?",
    }.get(status, "?")


def render_bar(value, max_value=100, width=20, status="OK"):
    """Render an ASCII progress bar."""
    if max_value == 0:
        filled = 0
    else:
        filled = int((value / max_value) * width)

    bar = "█" * filled + "░" * (width - filled)
    return colorize(status, f"[{bar}]")


def print_report(report, metrics):
    """
    Print the full formatted health report.
    `report`  — output of analyzer.health.analyze()
    `metrics` — raw parsed dict from collector.parser
    """
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    ts  = metrics.get("timestamp", "?")

    print()
    print("╔══════════════════════════════════════╗")
    print("║       MUDD HEALTH — SYSTEM REPORT    ║")
    print("╚══════════════════════════════════════╝")
    print(f"  Report time : {now}")
    print(f"  Snapshot ts : {ts}")
    print()

    checks = report["checks"]

    # Per-metric block
    metric_labels = {
        "cpu_used":  "CPU Usage",
        "mem_pct":   "Memory Usage",
        "disk_pct":  "Disk Usage  ",
        "load_1":    "Load Avg 1m ",
    }

    for key, label in metric_labels.items():
        if key not in checks:
            continue

        chk    = checks[key]
        status = chk["status"]
        value  = metrics.get(key, 0)
        bar    = render_bar(value, status=status)
        icon   = status_icon(status)

        print(f"  {label}  {bar}  {value:>6.1f}%  {colorize(status, icon + ' ' + status)}")

    print()

    # Uptime line
    from collector.parser import format_uptime
    uptime_sec = metrics.get("uptime_sec", 0)
    print(f"  Uptime      : {format_uptime(uptime_sec)}")

    # Top processes
    top_procs = metrics.get("top_procs", "")
    if top_procs:
        procs = [p for p in top_procs.split(",") if p]
        print(f"  Top procs   : {', '.join(procs)}")

    print()
    print("  ── Overall ─────────────────────────")

    score  = report["overall_score"]
    ostatus = report["overall_status"]
    print(f"  Score       : {colorize(ostatus, str(score) + '/100')}")
    print(f"  Status      : {colorize(ostatus, ostatus)}")

    alerts = report["alerts"]
    if alerts:
        print()
        print(f"  ── Alerts ({len(alerts)}) ──────────────────────")
        for alert in alerts:
            print(f"    {colorize('CRIT', '→')} {alert}")

    print()


def print_summary(report):
    """One-line summary suitable for cron output or logging."""
    score   = report["overall_score"]
    status  = report["overall_status"]
    nalerts = len(report["alerts"])
    ts      = datetime.datetime.now().isoformat(timespec="seconds")
    print(f"[{ts}] mudd_health | score={score}/100 status={status} alerts={nalerts}")