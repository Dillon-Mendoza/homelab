#!/bin/bash
# Week 01 — Linux Fundamentals + Shell Operations
# Objectives: 1.1, 1.5
# Run on: tp-mudd (primary), with optional SSH tasks to dell-ubuntu
# Estimated time: 45–60 min

DRY_RUN=true  # Set to false to execute. true echoes commands instead of running them.

run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 01 Lab — Linux Fundamentals + Shell Operations"
echo "  Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN"
echo "════════════════════════════════════════════════════════"
echo ""

# ── TASK 1: Inspect the boot sequence ─────────────────────────────────────────
# Why it matters: Objective 1.1 — boot process is a guaranteed exam topic.
# Knowing how long each service took to start is also real-world sysadmin work.
echo "── TASK 1: Boot Sequence Analysis ──"

echo ""
echo "[1a] Total boot time:"
run_cmd "systemd-analyze"

echo ""
echo "[1b] Top 20 slowest services at boot (blame output):"
run_cmd "systemd-analyze blame | head -20"

echo ""
echo "[1c] Boot chain — shows dependency tree of critical path:"
run_cmd "systemd-analyze critical-chain"

echo ""
echo "[1d] Kernel parameters used at this boot:"
run_cmd "cat /proc/cmdline"

echo ""
echo "[1e] Current default systemd target:"
run_cmd "systemctl get-default"

echo ""
echo "[1f] Journal from current boot — last 30 lines:"
run_cmd "journalctl -b -n 30"

echo ""
echo "[1g] Journal from current boot — errors and above only:"
run_cmd "journalctl -b -p err"

echo ""

# ── TASK 2: FHS Verification ──────────────────────────────────────────────────
# Why it matters: Objective 1.1 — exam questions test directory purposes directly.
# You should be able to identify what belongs in each directory without hesitation.
echo "── TASK 2: Filesystem Hierarchy Standard ──"

echo ""
echo "[2a] Top-level directory listing with types:"
run_cmd "ls -la /"

echo ""
echo "[2b] Confirm /proc is virtual — size is 0 for everything:"
run_cmd "ls -la /proc | head -20"

echo ""
echo "[2c] See live kernel info through /proc:"
run_cmd "cat /proc/version"
run_cmd "cat /proc/meminfo | grep -E '^(MemTotal|MemFree|MemAvailable)'"
run_cmd "cat /proc/cpuinfo | grep 'model name' | head -1"

echo ""
echo "[2d] What's consuming space in /var (your biggest variable-data dir):"
run_cmd "du -sh /var/log /var/cache /var/lib 2>/dev/null | sort -rh"

echo ""
echo "[2e] Check /tmp has sticky bit set (world-writable but only owner can delete):"
run_cmd "ls -ld /tmp"

echo ""

# ── TASK 3: Architecture and Distribution Identification ──────────────────────
# Why it matters: Objective 1.1 — you run two distro families. Know both cold.
echo "── TASK 3: Architecture + Distro Identity ──"

echo ""
echo "[3a] Machine architecture:"
run_cmd "uname -m"

echo ""
echo "[3b] Full kernel and OS info:"
run_cmd "uname -a"

echo ""
echo "[3c] Distribution identity (tp-mudd is RPM-based):"
run_cmd "cat /etc/os-release"

echo ""
echo "[3d] Confirm package manager (should be dnf on Fedora):"
run_cmd "which dnf && dnf --version | head -1"

echo ""
echo "[3e] SSH to dell-ubuntu and identify its distro family (dpkg-based):"
echo "  Run manually: ssh dell-ubuntu 'cat /etc/os-release && which apt'"
echo "  Compare: Ubuntu uses apt/dpkg. tp-mudd uses dnf/rpm. Same Linux, different toolchains."

echo ""

# ── TASK 4: Shell Config Files ────────────────────────────────────────────────
# Why it matters: Objective 1.5 — .bashrc vs .bash_profile is a classic exam trap.
# Understanding the load order prevents real-world misconfigurations too.
echo "── TASK 4: Shell Config Files ──"

echo ""
echo "[4a] Show current shell config files and their sizes:"
run_cmd "ls -la ~/.bashrc ~/.bash_profile ~/.profile 2>/dev/null"

echo ""
echo "[4b] What's currently in your .bashrc (aliases, PATH additions, etc.):"
run_cmd "grep -v '^#' ~/.bashrc | grep -v '^$'"

echo ""
echo "[4c] Add a test alias to .bashrc and source it:"
run_cmd "echo \"alias ll='ls -lah'\" >> ~/.bashrc"
run_cmd "source ~/.bashrc"
run_cmd "alias | grep ll"

echo ""
echo "[4d] Remove the test alias when done (cleanup):"
run_cmd "sed -i \"/alias ll='ls -lah'/d\" ~/.bashrc"

echo ""
echo "[4e] View PATH — note the colon-separated search order:"
run_cmd "echo \$PATH | tr ':' '\n'"

echo ""

# ── TASK 5: Redirection Practice ──────────────────────────────────────────────
# Why it matters: Objective 1.5 — redirection is on every Linux exam and used daily.
# The 2>&1 ordering trap is specifically tested on XK0-006.
echo "── TASK 5: Redirection ──"

SCRATCH="/tmp/week01-lab"
run_cmd "mkdir -p $SCRATCH"

echo ""
echo "[5a] Redirect stdout to a file (overwrite):"
run_cmd "ls /etc/ssh > $SCRATCH/ssh-files.txt"
run_cmd "cat $SCRATCH/ssh-files.txt"

echo ""
echo "[5b] Redirect stdout to a file (append):"
run_cmd "echo 'appended line' >> $SCRATCH/ssh-files.txt"
run_cmd "tail -3 $SCRATCH/ssh-files.txt"

echo ""
echo "[5c] Redirect stderr to a file (suppress permission errors from find):"
run_cmd "find /root -name '*.conf' 2>$SCRATCH/errors.txt"
run_cmd "cat $SCRATCH/errors.txt"

echo ""
echo "[5d] Merge stdout and stderr into one file:"
run_cmd "find /etc -name '*.conf' > $SCRATCH/all-output.txt 2>&1"
run_cmd "wc -l $SCRATCH/all-output.txt"

echo ""
echo "[5e] Pipe: count failed SSH login attempts in auth log:"
run_cmd "journalctl _SYSTEMD_UNIT=sshd.service | grep -c 'Failed' 2>/dev/null || echo '(no sshd log entries found)'"

echo ""
echo "[5f] Pipe chain: top 5 largest files in /var/log:"
run_cmd "find /var/log -type f -exec du -sh {} \; 2>/dev/null | sort -rh | head -5"

echo ""

# ── TASK 6: find Command Deep Dive ────────────────────────────────────────────
# Why it matters: Objectives 1.1 and 1.5 — find with -perm is how you locate
# SUID files in the wild. This appears directly in security objectives too (3.3).
echo "── TASK 6: find Command ──"

echo ""
echo "[6a] Find all .conf files under /etc:"
run_cmd "find /etc -name '*.conf' -type f | wc -l"

echo ""
echo "[6b] Find files modified in the last 24 hours in /etc:"
run_cmd "find /etc -mtime -1 -type f 2>/dev/null"

echo ""
echo "[6c] IMPORTANT — Find all SUID files on the system:"
echo "  (This is an exam objective AND a security audit task)"
run_cmd "find / -perm -4000 -type f 2>/dev/null"

echo ""
echo "[6d] Find all SGID files:"
run_cmd "find / -perm -2000 -type f 2>/dev/null"

echo ""
echo "[6e] Find world-writable directories (potential security issue):"
run_cmd "find / -perm -0002 -type d 2>/dev/null | grep -v proc | grep -v sys"

echo ""
echo "[6f] find with -exec: show permissions on all SUID files:"
run_cmd "find /usr/bin -perm -4000 -exec ls -lh {} \; 2>/dev/null"

echo ""

# ── TASK 7: Core Utility Practice ─────────────────────────────────────────────
# Why it matters: Objective 1.5 — these tools appear in performance-based
# questions. You need to produce output, not just know they exist.
echo "── TASK 7: Core Utilities ──"

echo ""
echo "[7a] grep — find active (non-comment) sshd_config settings:"
run_cmd "grep -v '^#' /etc/ssh/sshd_config | grep -v '^$'"

echo ""
echo "[7b] awk — extract username and UID from /etc/passwd:"
run_cmd "awk -F: '{print \$1, \$3}' /etc/passwd | column -t | head -15"

echo ""
echo "[7c] sed — show sshd_config with comments stripped:"
run_cmd "sed '/^#/d;/^$/d' /etc/ssh/sshd_config"

echo ""
echo "[7d] cut + sort + uniq — most common shells in /etc/passwd:"
run_cmd "cut -d: -f7 /etc/passwd | sort | uniq -c | sort -rn"

echo ""
echo "[7e] tee — write journalctl output to file AND display it:"
run_cmd "journalctl -b -p err | tee $SCRATCH/boot-errors.txt | wc -l"
run_cmd "echo 'Boot errors saved to: $SCRATCH/boot-errors.txt'"

echo ""

# ── CLEANUP ───────────────────────────────────────────────────────────────────
echo "── Cleanup ──"
run_cmd "rm -rf $SCRATCH"
echo ""

echo "════════════════════════════════════════════════════════"
echo "  Week 01 Lab Complete"
echo ""
echo "  Practiced:"
echo "  ✓ Boot sequence analysis (systemd-analyze, journalctl)"
echo "  ✓ FHS directory identification and /proc virtual filesystem"
echo "  ✓ Architecture and distribution identification"
echo "  ✓ Shell config file load order (.bashrc vs .bash_profile)"
echo "  ✓ All redirection forms including 2>&1 ordering"
echo "  ✓ find with -perm, -mtime, -type, -exec"
echo "  ✓ grep, awk, sed, cut, sort, uniq, tee in realistic scenarios"
echo ""
echo "  Objectives covered: 1.1, 1.5"
echo "════════════════════════════════════════════════════════"
