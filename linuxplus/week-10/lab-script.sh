#!/bin/bash
# Week 10 — Full Troubleshooting Sprint
# Objectives: 5.1, 5.2, 5.3, 5.4, 5.5
# Run on: tp-mudd only — fully self-contained, no other devices required
# Estimated time: 45–60 min (Task 7 incident review is the closer — do not skip it)
#
# FORMAT THIS WEEK IS DIFFERENT: each task INJECTS a real fault, then stops.
# You diagnose with your own hands before reading on. The methodology is the
# lab: identify → theory → test → plan → fix → verify. Predict before you peek.
#
# Faults touch real system state (a throwaway unit, resolv.conf, loop mounts).
# Everything is reversible, every station restores itself, and a trap restores
# DNS even if the script dies mid-run. Still: read each block before running.

DRY_RUN=true  # Set to false to execute. true echoes commands instead of running them.

run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

SCRATCH="/tmp/week10"
IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')

# Safety net: if the script dies while DNS is broken (Task 4), restore it.
cleanup() {
    if ! $DRY_RUN && [[ -f "$SCRATCH/.dns-broken" ]]; then
        echo "!! trap: restoring DNS (resolv.conf symlink + resolvectl revert)"
        sudo ln -sfn ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
        [[ -n "$IFACE" ]] && sudo resolvectl revert "$IFACE" 2>/dev/null
        sudo resolvectl flush-caches 2>/dev/null
        rm -f "$SCRATCH/.dns-broken"
    fi
}
trap cleanup EXIT

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 10 Lab — Troubleshooting Sprint (fault injection)"
echo "  Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN | default iface: ${IFACE:-unknown}"
echo "════════════════════════════════════════════════════════"
echo ""

run_cmd "mkdir -p $SCRATCH $SCRATCH/mnt"

# ── TASK 1: Fault — a systemd Unit That Won't Start (5.2) ─────────────────────
# Why it matters: unit failures are a guaranteed exam scenario, and 203/EXEC
# is the single most recognizable failure code systemd produces.
echo "── TASK 1: Broken systemd Unit ──"

echo ""
echo "[1a] INJECT — install a service with a subtle typo in ExecStart:"
if $DRY_RUN; then
    echo "[DRY RUN] write /etc/systemd/system/week10-broken.service (ExecStart=/usr/bin/sleeep 300)"
else
    sudo tee /etc/systemd/system/week10-broken.service >/dev/null <<'EOF'
[Unit]
Description=Week 10 fault injection — a deliberately broken service

[Service]
ExecStart=/usr/bin/sleeep 300
EOF
fi
run_cmd "sudo systemctl daemon-reload && sudo systemctl start week10-broken.service 2>&1 | head -2"

echo ""
echo "[1b] DIAGNOSE — before scrolling further, run these yourself and form a theory:"
echo "       systemctl status week10-broken.service"
echo "       journalctl -u week10-broken.service -n 10 --no-pager"
echo "       systemd-analyze verify week10-broken.service"
run_cmd "systemctl status week10-broken.service --no-pager 2>&1 | grep -E 'Active|Process' | head -3"
echo "  ^ status=203/EXEC — systemd's code for 'could not execute ExecStart'."
echo "    verify names the exact problem: the binary path does not exist."

echo ""
echo "[1c] FIX — and hit the daemon-reload trap on purpose:"
run_cmd "sudo sed -i 's/sleeep/sleep/' /etc/systemd/system/week10-broken.service"
run_cmd "sudo systemctl restart week10-broken.service 2>&1 | head -2; systemctl status week10-broken.service --no-pager 2>&1 | grep -E 'Warning|changed' | head -2"
echo "  ^ see the 'unit file changed on disk' warning? Edits are INVISIBLE to"
echo "    systemd until daemon-reload — this is the tested gotcha."
run_cmd "sudo systemctl daemon-reload && sudo systemctl restart week10-broken.service && systemctl is-active week10-broken.service"

echo ""
echo "[1d] VERIFY + CLEAN — full removal, in the right order:"
run_cmd "sudo systemctl stop week10-broken.service && sudo rm /etc/systemd/system/week10-broken.service && sudo systemctl daemon-reload"

echo ""

# ── TASK 2: Fault — Filesystem Full Three Ways (5.2) ──────────────────────────
# Why it matters: 'disk full' has three distinct exam faces — genuinely full,
# full-but-du-disagrees (deleted-open file), and full-with-free-space (inodes).
echo "── TASK 2: Disk Full — Three Different Ways ──"

echo ""
echo "[2a] Build a sacrificial 64MB ext4 filesystem on a loop file (Week 2 skills):"
run_cmd "truncate -s 64M $SCRATCH/disk.img && mkfs.ext4 -q $SCRATCH/disk.img"
run_cmd "sudo mount -o loop $SCRATCH/disk.img $SCRATCH/mnt && sudo chown $USER: $SCRATCH/mnt && df -h $SCRATCH/mnt | tail -1"

echo ""
echo "[2b] FACE 1 — genuinely full. Fill it, read the error, confirm with df:"
run_cmd "dd if=/dev/zero of=$SCRATCH/mnt/big bs=1M 2>&1 | tail -1"
run_cmd "df -h $SCRATCH/mnt | tail -1"

echo ""
echo "[2c] FACE 2 — the deleted-but-open file. A process holds 'big' open; we rm it:"
run_cmd "tail -f $SCRATCH/mnt/big >/dev/null 2>&1 & echo \"holder PID: \$!\""
run_cmd "rm $SCRATCH/mnt/big && df -h $SCRATCH/mnt | tail -1 && du -sh $SCRATCH/mnt 2>/dev/null"
echo "  ^ PREDICT before you look: df says ~100%, du says ~0. Who is right?"
echo "    Both — the file has no name but still has an inode and blocks, because"
echo "    a process holds it open. THE command for this:"
run_cmd "lsof +L1 $SCRATCH/mnt 2>/dev/null | head -3"
run_cmd "pkill -f 'tail -f $SCRATCH/mnt/big'; sleep 1; df -h $SCRATCH/mnt | tail -1"
echo "  ^ kill the holder → kernel frees the blocks → df drops instantly."
echo "    Real-world face: 'we rotated the huge log but the disk is still full'."

echo ""
echo "[2d] FACE 3 — inode exhaustion. Tiny fs, starved of inodes on purpose:"
run_cmd "truncate -s 16M $SCRATCH/inodes.img && mkfs.ext4 -q -N 64 $SCRATCH/inodes.img && mkdir -p $SCRATCH/mnt2 && sudo mount -o loop $SCRATCH/inodes.img $SCRATCH/mnt2 && sudo chown $USER: $SCRATCH/mnt2"
run_cmd "for i in \$(seq 1 100); do touch $SCRATCH/mnt2/f\$i 2>/dev/null || { echo \"failed at file \$i: No space left on device\"; break; }; done"
run_cmd "df -h $SCRATCH/mnt2 | tail -1 && df -i $SCRATCH/mnt2 | tail -1"
echo "  ^ df -h: plenty of space. df -i: IUse% = 100. 'No space left' lies —"
echo "    it means no INODES left. df -i is the reflex to build."

echo ""

# ── TASK 3: Fault — Permission Denied That chmod Can't Fix (5.2/5.4) ──────────
# Why it matters: 'perms look right but execution fails' has two culprits the
# exam loves — mount options and SELinux. This station plants the first.
echo "── TASK 3: The Unfixable Permission Denied ──"

echo ""
echo "[3a] INJECT — remount the loop fs noexec, plant an executable script:"
run_cmd "sudo mount -o remount,noexec $SCRATCH/mnt"
run_cmd "printf '#!/bin/bash\necho it works\n' > $SCRATCH/mnt/hello.sh && chmod +x $SCRATCH/mnt/hello.sh"

echo ""
echo "[3b] DIAGNOSE — run it, read the failure, then explain why ls -l is innocent:"
run_cmd "$SCRATCH/mnt/hello.sh 2>&1; ls -l $SCRATCH/mnt/hello.sh"
echo "  ^ Permission denied with rwx clearly set. chmod 777 would NOT help."
echo "    The answer is not on the file — it's on the MOUNT:"
run_cmd "findmnt $SCRATCH/mnt -o TARGET,OPTIONS"
echo "  ^ noexec. Same trick powers nosuid and nodev hardening (Week 2 fstab"
echo "    options — as a defense there, as a symptom here)."

echo ""
echo "[3c] FIX + VERIFY, then tear both filesystems down:"
run_cmd "sudo mount -o remount,exec $SCRATCH/mnt && $SCRATCH/mnt/hello.sh"
run_cmd "sudo umount $SCRATCH/mnt $SCRATCH/mnt2"
echo "  SELinux twin of this symptom (Week 6/7 skills, run if time permits):"
echo "    sudo ausearch -m AVC -ts today | tail   # any denials from your session?"

echo ""

# ── TASK 4: Fault — DNS, Broken at Two Different Layers (5.3) ─────────────────
# Why it matters: 'DNS failure' on Fedora is layered — resolv.conf is a symlink
# to a systemd-resolved stub, and different tools take different paths. Breaking
# both layers separately is the only way to really own this.
echo "── TASK 4: DNS Fault Injection (auto-restoring) ──"

echo ""
echo "[4a] BASELINE — map the healthy resolution stack first (methodology step 1):"
run_cmd "ls -l /etc/resolv.conf && grep '^hosts:' /etc/nsswitch.conf"
run_cmd "resolvectl status 2>/dev/null | grep -A2 'Link.*$IFACE' | head -3"
echo "  ^ resolv.conf → stub (127.0.0.53); nsswitch hands 'hosts' to resolve"
echo "    (systemd-resolved via D-Bus) BEFORE dns. Two paths, one name."

echo ""
echo "[4b] INJECT layer 1 — replace the resolv.conf symlink with a dead resolver:"
run_cmd "touch $SCRATCH/.dns-broken"
run_cmd "sudo rm -f /etc/resolv.conf && printf 'nameserver 203.0.113.53\n' | sudo tee /etc/resolv.conf >/dev/null"
echo "    (203.0.113.x is TEST-NET-3 — documentation space, guaranteed dead.)"

echo ""
echo "[4c] DIAGNOSE — PREDICT which of these three fail before running them:"
run_cmd "dig +time=2 +tries=1 +short example.com 2>&1 | tail -1"
run_cmd "getent hosts example.com | head -1"
run_cmd "curl -sI --max-time 5 https://example.com | head -1"
echo "  ^ dig FAILS (it reads resolv.conf directly). getent and curl still WORK —"
echo "    nsswitch routed them through systemd-resolved over D-Bus, which never"
echo "    looked at resolv.conf. One 'DNS failure', two truths. On the exam,"
echo "    corrupt resolv.conf = broken DNS; on modern Fedora, know the nuance."

echo ""
echo "[4d] RESTORE layer 1 — put the symlink back, verify dig recovers:"
run_cmd "sudo ln -sfn ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf"
run_cmd "dig +time=2 +tries=1 +short example.com 2>&1 | tail -1"

echo ""
echo "[4e] INJECT layer 2 — poison systemd-resolved's UPSTREAM (the real break):"
run_cmd "sudo resolvectl dns $IFACE 203.0.113.53 && sudo resolvectl flush-caches"
run_cmd "getent hosts fedoraproject.org | head -1; echo \"getent exit code: \$?\""
echo "  ^ NOW everything is broken — the resolver itself has a dead upstream."
echo "    Isolate it the exam way: does an EXPLICIT server still answer?"
run_cmd "dig +time=2 +tries=1 +short fedoraproject.org @1.1.1.1 | head -1"
echo "  ^ works → network path is fine, upstream resolver config is the fault."
echo "    That dig @server comparison is THE dns-vs-network isolation move."

echo ""
echo "[4f] RESTORE layer 2 — resolved has a built-in undo for this:"
run_cmd "sudo resolvectl revert $IFACE && sudo resolvectl flush-caches && rm -f $SCRATCH/.dns-broken"
run_cmd "getent hosts fedoraproject.org | head -1 && echo 'DNS fully restored'"

echo ""

# ── TASK 5: Performance — Generate Load, Read the Numbers (5.5) ───────────────
# Why it matters: 5.5 questions hand you vmstat/uptime output and ask what is
# wrong. Reading numbers YOU caused builds the symptom→cause mapping for real.
echo "── TASK 5: Performance Symptoms, Self-Inflicted ──"

echo ""
echo "[5a] BASELINE — idle numbers first, or the loaded ones mean nothing:"
run_cmd "nproc && uptime"
run_cmd "vmstat 1 3 | tail -4"
echo "  ^ note r, b, si/so, us/sy/id/wa. First data line is since-boot average — skip it."

echo ""
echo "[5b] CPU saturation — one spinner per core, then re-read:"
run_cmd "for i in \$(seq \$(nproc)); do yes >/dev/null & done; sleep 5; vmstat 1 3 | tail -3; uptime; pkill -x yes"
echo "  ^ r ≈ core count, us ~100, id ~0 — and the 1-min load only CREPT up."
echo "    Load averages are momentum, not speedometers: 1-min vs 15-min tells"
echo "    you 'getting worse' vs 'recovering'. CPU-bound = high load AND high us."

echo ""
echo "[5c] I/O pressure — direct writes bypass the page cache, then re-read:"
run_cmd "dd if=/dev/zero of=$SCRATCH/io.bin bs=1M count=1024 oflag=direct 2>/dev/null & vmstat 1 4 | tail -4; wait; rm -f $SCRATCH/io.bin"
echo "  ^ watch b and wa. On this NVMe they may barely twitch — that non-finding"
echo "    IS a finding: fast disk = no I/O wall. On spinning rust or dying disks,"
echo "    wa climbing while us idles is the signature. High load + idle CPU = here."

echo ""
echo "[5d] PSI — the modern pressure gauges, one file per resource:"
run_cmd "grep -H . /proc/pressure/cpu /proc/pressure/memory /proc/pressure/io | grep some"
echo "  ^ 'some avg10' = % of the last 10s at least one task stalled on that"
echo "    resource. Three files replace a whole page of vmstat interpretation."

echo ""
echo "[5e] Memory truth + OOM history:"
run_cmd "free -h | head -2 && swapon --show"
run_cmd "journalctl -k -g -i 'out of memory' --no-pager 2>/dev/null | tail -2 || echo '  (no OOM events in journal — healthy)'"
echo "  ^ read AVAILABLE, not free — low 'free' is just healthy page cache."
echo "    OOM leaves its confession only in the kernel log; the victim vanishes."

echo ""
echo "[5f] OPTIONAL — the sysstat pair the objectives name:"
echo "       sudo dnf install -y sysstat && iostat -x 1 3 && pidstat 1 3"
echo "     iostat %util/await = per-disk saturation; pidstat = per-PROCESS blame."

echo ""

# ── TASK 6: Monitoring — Catch a Webhook With Your Own Hands (5.1) ────────────
# Why it matters: threshold → event → alert → webhook is 5.1's chain. Running
# both ends on localhost turns four vocabulary words into one observed fact.
echo "── TASK 6: Threshold Check + Webhook, Both Ends Local ──"

echo ""
echo "[6a] A listener plays 'n8n' (this is all a webhook receiver is):"
run_cmd "(timeout 10 nc -l 127.0.0.1 9090 > $SCRATCH/webhook-capture.txt 2>/dev/null &) ; sleep 1"

echo ""
echo "[6b] A health check evaluates a threshold and fires the webhook:"
run_cmd "LOAD=\$(awk '{print \$1}' /proc/loadavg); DISK=\$(df --output=pcent / | tail -1 | tr -dc '0-9'); PAYLOAD=\"{\\\"host\\\":\\\"\$(hostname)\\\",\\\"load1\\\":\$LOAD,\\\"disk_pct\\\":\$DISK,\\\"event\\\":\\\"health-check\\\"}\"; echo \"payload: \$PAYLOAD\"; curl -m 2 -s -X POST -H 'Content-Type: application/json' -d \"\$PAYLOAD\" http://127.0.0.1:9090 || true"
echo "    (curl times out — raw nc never sends an HTTP response. The POST still"
echo "     landed, and delivery is the entire concept.)"

echo ""
echo "[6c] Read what the 'monitoring platform' received:"
run_cmd "sleep 1; cat $SCRATCH/webhook-capture.txt"
echo "  ^ an HTTP POST with a JSON body. Your n8n instance on dell-fedora ingests"
echo "    exactly this shape all day (conceptual anchor — nothing to run there)."
echo "    Vocabulary now earned: threshold (the if), event (the crossing),"
echo "    alert (the decision), webhook (this POST), notification (what n8n sends next)."

echo ""

# ── TASK 7: Incident Review + Live Journal Triage (5.3/5.4 + methodology) ─────
# Why it matters: you own two REAL incident writeups. The exam's scenario
# questions are these documents with the names changed.
echo "── TASK 7: Your Own Incidents, Re-Read as Exam Scenarios ──"

echo ""
echo "[7a] Re-read both (10 minutes, actually read them):"
echo "       less ~/homelab/incidents/tailscale-acl-outage.md"
echo "       less ~/homelab/incidents/Dns-failure.md"

echo ""
echo "[7b] For EACH incident, answer out loud — write the answers in notes:"
echo "     1. Map every action taken onto the 7-step methodology. Which steps"
echo "        were done well? Which step was skipped or done out of order?"
echo "     2. Which single command cracked each case?"
echo "        (ACL outage: ip route show table 52 / n8n: docker exec ... ping)"
echo "     3. Which exam objective is each? (ACL → 5.3 routing/firewall;"
echo "        n8n → 5.3 DNS + stale state — and Task 4 was its little sibling)"
echo "     4. Methodology step 6 is 'implement preventive measures' — the n8n"
echo "        writeup says the daemon.json DNS pin was NEVER applied. That open"
echo "        item is a step-6 failure sitting in your repo. What would you do?"

echo ""
echo "[7c] Live triage — the habit the sprint should leave behind:"
run_cmd "journalctl -b -p err --no-pager | tail -15"
echo "  ^ classify each line: (a) actionable now, (b) known/cosmetic noise,"
echo "    (c) needs research. Anything in (a) — congratulations, a real ticket."
run_cmd "systemctl --failed --no-legend || echo '  (no failed units)'"

echo ""

# ── CLEANUP CHECK ─────────────────────────────────────────────────────────────
echo "── Cleanup Check ──"
run_cmd "mount | grep -c $SCRATCH/mnt || true"
echo "  ^ must be 0 — if not: sudo umount $SCRATCH/mnt $SCRATCH/mnt2"
echo "  DNS: ls -l /etc/resolv.conf must show the stub symlink; if anything is"
echo "  off: sudo ln -sfn ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf"
echo "       sudo resolvectl revert $IFACE"
echo "  Then: rm -rf $SCRATCH"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 10 Lab Complete"
echo ""
echo "  Faults injected AND diagnosed (all on tp-mudd):"
echo "  ✓ 203/EXEC unit failure — status/journalctl/verify chain + daemon-reload trap"
echo "  ✓ Disk full three ways: genuinely full, deleted-but-open (lsof +L1),"
echo "    inode exhaustion (df -h lies, df -i confesses)"
echo "  ✓ noexec 'Permission denied' that chmod cannot fix — findmnt reveals"
echo "  ✓ DNS broken at two layers — resolv.conf vs resolved upstream; dig vs"
echo "    getent divergence; dig @server isolation; resolvectl revert"
echo "  ✓ CPU vs I/O load signatures self-inflicted and read via vmstat + PSI"
echo "  ✓ threshold→event→alert→webhook chain run end-to-end on localhost"
echo "  ✓ Two real incidents mapped onto the 7-step methodology + live journal triage"
echo ""
echo "  Objectives covered: 5.1, 5.2, 5.3, 5.4, 5.5"
echo "════════════════════════════════════════════════════════"
