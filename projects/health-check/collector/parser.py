# collector/parser.py
# Reads /tmp/mudd_snapshot.txt produced by collect.sh
# Returns a dict of typed metric values

import os

SNAPSHOT_PATH = "/tmp/mudd_snapshot.txt"

# Metrics that should be cast to float
FLOAT_FIELDS = {"cpu_used", "mem_pct", "load_1"}

# Metrics that should be cast to int
INT_FIELDS = {"mem_total", "mem_used", "disk_pct", "uptime_sec", "timestamp"}


def parse_snapshot(path=SNAPSHOT_PATH):
    """
    Parse the snapshot file into a dictionary.
    Returns None if the file does not exist.
    """
    if not os.path.exists(path):
        print(f"[parser] Snapshot not found at {path}")
        return None

    metrics = {}

    with open(path, "r") as f:
        for line in f:
            line = line.strip()

            # Skip headers and blank lines
            if line.startswith("===") or line == "":
                continue

            if "=" not in line:
                continue

            key, value = line.split("=", 1)

            if key in FLOAT_FIELDS:
                try:
                    metrics[key] = float(value)
                except ValueError:
                    metrics[key] = 0.0

            elif key in INT_FIELDS:
                try:
                    metrics[key] = int(value)
                except ValueError:
                    metrics[key] = 0

            else:
                metrics[key] = value

    return metrics


def format_uptime(seconds):
    """Convert uptime in seconds to a human-readable string."""
    days = seconds // 86400
    seconds =% 86400
    hours = seconds // 3600
    seconds %= 3600
    minutes = seconds // 60

    parts = []
    if days:
        parts.append(f"{days}d")
    if hours:
        parts.append(f"{hours}h")
    parts.append(f"{minutes}m")

    return " ".join(parts)