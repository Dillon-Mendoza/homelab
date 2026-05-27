# analyzer/health.py
# Evaluates parsed metrics against configurable thresholds.
# Returns a structured report dict with status per metric and an overall score.

THRESHOLDS = {
    "cpu_used":  {"warn": 75.0, "crit": 90.0},
    "mem_pct":   {"warn": 70.0, "crit": 85.0},
    "disk_pct":  {"warn": 80,   "crit": 95},
    "load_1":    {"warn": 2.0,  "crit": 4.0},
}

STATUS_OK   = "OK"
STATUS_WARN = "WARN"
STATUS_CRIT = "CRIT"
STATUS_UNKN = "UNKNOWN"

# Score weights — must sum to 1.0
WEIGHTS = {
    "cpu_used": 0.30,
    "mem_pct":  0.30,
    "disk_pct": 0.20,
    "load_1":   0.20,
}


def evaluate_metric(key, value):
    """
    Return (status, message) for a single metric.
    """
    if key not in THRESHOLDS:
        return STATUS_UNKN, f"{key} has no threshold defined"

    t = THRESHOLDS[key]

    if value >= t["crit"]:
        return STATUS_CRIT, f"{key}={value} exceeds critical threshold ({t['crit']})"
    elif value >= t["warn"]:
        return STATUS_WARN, f"{key}={value} exceeds warning threshold ({t['warn']})"
    else:
        return STATUS_OK, f"{key}={value} is within normal range"


def score_metric(status):
    """
    Convert a status string to a numeric health score (0–100).
    OK=100, WARN=50, CRIT=0, UNKNOWN=50
    """
    return {
        STATUS_OK:   100,
        STATUS_WARN: 50,
        STATUS_CRIT: 0,
        STATUS_UNKN: 50,
    }.get(status, 50)


def analyze(metrics):
    """
    Run all threshold checks. Return a report dict:
    {
        "checks": {metric: {"status": ..., "message": ...}},
        "overall_score": float,   # weighted 0–100
        "overall_status": str,
        "alerts": [str],          # only WARN/CRIT messages
    }
    """
    checks = {}
    alerts = []
    weighted_score = 0.0
    total_weight = 0.0

    for key, weight in WEIGHTS.items():
        if key not in metrics:
            checks[key] = {"status": STATUS_UNKN, "message": f"{key} missing from snapshot"}
            weighted_score += score_metric(STATUS_UNKN) * weight
            total_weight += weight
            continue

        value = metrics[key]
        status, message = evaluate_metric(key, value)
        checks[key] = {"status": status, "message": message}

        if status in (STATUS_WARN, STATUS_CRIT):
            alerts.append(message)

        weighted_score += score_metric(status) * weight
        total_weight += weight

    # Normalize — guard against zero weight (shouldn't happen, but defensive)
    if total_weight > 0:
        overall_score = weighted_score / total_weight
    else:
        overall_score = 0.0

    # Determine overall status from worst individual check
    statuses = [c["status"] for c in checks.values()]

    if STATUS_CRIT in statuses:
        overall_status = STATUS_CRIT
    elif STATUS_WARN in statuses:
        overall_status = STATUS_WARN
    elif all(s == STATUS_OK for s in statuses):
        overall_status = STATUS_OK
    else:
        overall_status = STATUS_UNKN

    return {
        "checks": checks,
        "overall_score": round(overall_score, 1),
        "overall_status": overall_status,
        "alerts": alerts,
    }