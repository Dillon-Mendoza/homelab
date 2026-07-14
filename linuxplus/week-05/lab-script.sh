#!/bin/bash
# Week 05 — Processes + Software + Systemd
# Objectives: 2.3, 2.4, 2.5
# Run on: tp-mudd only — fully self-contained, no other devices required
# Estimated time: 45–60 min (Task 6 container and Task 8 timer are optional)
#
# Creates a disposable systemd unit (week05.service). Task 7 removes it —
# run the cleanup even if you stop early.

DRY_RUN=true  # Set to false to execute. true echoes commands instead of running them.

run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

SCRATCH="/tmp/week05"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 05 Lab — Processes + Software + Systemd"
echo "  Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN"
echo "════════════════════════════════════════════════════════"
echo ""

run_cmd "mkdir -p $SCRATCH"

# ── TASK 1: Observe Processes — Including a Real Zombie ───────────────────────
# Why it matters: Objective 2.3 — the exam shows ps output and asks about the
# STAT column. You'll read real states, then manufacture the one everyone
# memorizes but few have seen: a zombie.
echo "── TASK 1: Process States ──"

echo ""
echo "[1a] Find tailscaled — three tools, same answer:"
run_cmd "pgrep -a tailscaled"
run_cmd "pidof tailscaled"
run_cmd "ps -o pid,ppid,stat,ni,user,comm -p \$(pidof tailscaled)"

echo ""
echo "[1b] The kernel's raw view of it under /proc:"
run_cmd "TSPID=\$(pidof tailscaled); tr '\\0' ' ' < /proc/\$TSPID/cmdline; echo"
run_cmd "grep -E '^(State|Uid|Threads)' /proc/\$(pidof tailscaled)/status"
run_cmd "sudo ls /proc/\$(pidof tailscaled)/fd | wc -l && echo 'open file descriptors'"

echo ""
echo "[1c] Who spawned whom — find tailscaled and your own shell in the tree:"
run_cmd "pstree -p | head -30"

echo ""
echo "[1d] MAKE A ZOMBIE — parent sleeps without reaping its exited child:"
run_cmd "python3 -c 'import os,time; pid=os.fork(); (pid==0) and os._exit(0); time.sleep(15)' & sleep 1; ps aux | awk '\$8 ~ /^Z/ {print \$2, \$8, \$11, \$12, \$13}'"
echo "  ^ STAT 'Z', name shows <defunct>. Now PREDICT: will kill -9 remove it?"
run_cmd "ZPID=\$(ps aux | awk '\$8 ~ /^Z/ {print \$2; exit}'); [ -n \"\$ZPID\" ] && kill -9 \$ZPID; sleep 1; ps aux | awk '\$8 ~ /^Z/ {print \$2, \$8, \$11}' || echo 'no zombies'"
echo "  ^ Still there — it's already dead. It vanishes when the parent's sleep ends"
echo "  (~15s) and the parent exits: systemd adopts and reaps it. Wait and re-check:"
run_cmd "sleep 15; ps aux | awk '\$8 ~ /^Z/' | wc -l"

echo ""

# ── TASK 2: Signals — Prove What's Catchable ──────────────────────────────────
# Why it matters: Objective 2.3 — "SIGKILL cannot be caught" is a memorized
# fact until you write a trap handler and watch KILL sail through it.
echo "── TASK 2: Signals vs a trap Handler ──"

echo ""
echo "[2a] Write a process that CATCHES SIGTERM and SIGHUP:"
if $DRY_RUN; then
    echo "[DRY RUN] write $SCRATCH/trapdemo.sh — loops forever, traps TERM and HUP"
else
    cat > "$SCRATCH/trapdemo.sh" <<'EOF'
#!/bin/bash
trap 'echo "  trapdemo: caught SIGTERM — refusing to die"' TERM
trap 'echo "  trapdemo: caught SIGHUP — pretending to reload config"' HUP
echo "  trapdemo: running as PID $$"
while true; do sleep 1; done
EOF
    chmod +x "$SCRATCH/trapdemo.sh"
fi

echo ""
echo "[2b] Start it, then hit it with HUP, then TERM — watch it shrug both off:"
run_cmd "$SCRATCH/trapdemo.sh & sleep 1; DPID=\$(pgrep -f trapdemo.sh | head -1); kill -HUP \$DPID; sleep 1; kill -TERM \$DPID; sleep 1; ps -o pid,stat,comm -p \$DPID"

echo ""
echo "[2c] Now SIGKILL — no handler can exist for it:"
run_cmd "DPID=\$(pgrep -f trapdemo.sh | head -1); kill -9 \$DPID; sleep 1; ps -p \$DPID || echo '  gone. 9 is not a request.'"

echo ""
echo "[2d] Niceness — start lowered, then renice further; note the NI column:"
run_cmd "nice -n 10 sleep 60 & sleep 1; ps -o pid,ni,comm -p \$(pgrep -f 'sleep 60' | head -1)"
run_cmd "renice -n 19 -p \$(pgrep -f 'sleep 60' | head -1)"
run_cmd "ps -o pid,ni,comm -p \$(pgrep -f 'sleep 60' | head -1)"
echo "  Now try to renice it BACK DOWN to 5 as a regular user (predict first):"
run_cmd "renice -n 5 -p \$(pgrep -f 'sleep 60' | head -1) || echo '  DENIED — only root lowers niceness, even back toward default'"
run_cmd "pkill -f 'sleep 60'"

echo ""

# ── TASK 3: Job Control ───────────────────────────────────────────────────────
# Why it matters: Objective 2.3 — jobs/fg/bg/nohup are interactive by nature;
# these steps are meant to be TYPED in your terminal, not run via script.
echo "── TASK 3: Job Control (do these by hand in your shell) ──"

echo "
  1. sleep 300                    # foreground — terminal is now stuck
  2. Ctrl+Z                       # suspend: '[1]+ Stopped' — STAT is now T
  3. jobs                         # see it listed as %1
  4. bg %1                        # resume it IN THE BACKGROUND
  5. ps -o pid,stat,comm -C sleep # STAT back to S
  6. fg %1                        # pull to foreground, then Ctrl+C (SIGINT) to kill
  7. nohup sleep 300 &            # now close this terminal tab entirely,
     open a new one:  pgrep -a sleep   # still alive — nohup ignored the HUP
     pkill sleep                  # cleanup
"

echo ""

# ── TASK 4: Scheduling — cron and at ──────────────────────────────────────────
# Why it matters: Objective 2.3 — writing a real crontab line and watching it
# fire beats reading the syntax table ten times.
echo "── TASK 4: cron + at ──"

echo ""
echo "[4a] Add a heartbeat entry — every 5 minutes, no editor needed:"
run_cmd "( crontab -l 2>/dev/null; echo '*/5 * * * * date >> /tmp/week05-cron.log' ) | crontab -"
run_cmd "crontab -l"

echo ""
echo "[4b] While you wait for it to fire (up to 5 min — continue with Task 5),"
echo "     confirm crond is even running (a stopped crond is a 5.2 exam scenario):"
run_cmd "systemctl is-active crond"

echo ""
echo "[4c] One-shot scheduling with at (install if missing: sudo dnf install -y at"
echo "     && sudo systemctl enable --now atd):"
run_cmd "echo 'date >> /tmp/week05-at.log' | at now + 1 minute 2>&1 || echo '  (at/atd not installed — optional, the syntax above is what the exam tests)'"
run_cmd "atq 2>/dev/null"

echo ""
echo "[4d] LATER — verify both fired, then remove the cron entry surgically"
echo "     (crontab -r would nuke everything; we filter instead):"
run_cmd "cat /tmp/week05-cron.log 2>/dev/null | tail -3"
run_cmd "crontab -l | grep -v week05-cron.log | crontab -"
run_cmd "crontab -l || echo '  (crontab now empty)'"
run_cmd "rm -f /tmp/week05-cron.log /tmp/week05-at.log"

echo ""

# ── TASK 5: dnf / rpm Workflow on the Host ────────────────────────────────────
# Why it matters: Objective 2.4 — the full transaction lifecycle including the
# rollback (dnf history undo), which is the exam's favorite dnf feature.
echo "── TASK 5: dnf + rpm (RPM family, live) ──"

echo ""
echo "[5a] Where do packages come from? Read one repo definition:"
run_cmd "dnf repolist --enabled | head -8"
run_cmd "grep -E '^(name|enabled|gpgcheck)' /etc/yum.repos.d/fedora.repo | head -6"

echo ""
echo "[5b] Install htop, then interrogate it with BOTH layers:"
run_cmd "sudo dnf install -y htop"
run_cmd "rpm -qi htop | head -8"
run_cmd "rpm -ql htop | head -8"
run_cmd "rpm -qf /usr/bin/htop"

echo ""
echo "[5c] The transaction log — find your install:"
run_cmd "sudo dnf history | head -6"
run_cmd "sudo dnf history info last | head -15"

echo ""
echo "[5d] Remove it, then UNDO the removal — transactional rollback:"
run_cmd "sudo dnf remove -y htop"
run_cmd "sudo dnf history undo last -y || echo '  (if dnf5 rejects undo here: sudo dnf install -y htop — and note that undo-by-ID is the exam answer)'"
run_cmd "rpm -q htop && echo '  htop is BACK — the remove transaction was reversed'"

echo ""
echo "[5e] Verify package integrity — what changed since install (previews 3.6):"
run_cmd "rpm -V htop && echo '  (no output = nothing modified)'"

echo ""
echo "[5f] Keep htop or remove it — your call. Also glance at the sandboxed world:"
run_cmd "flatpak list 2>/dev/null | head -5 || echo '  (no flatpaks installed)'"
run_cmd "alternatives --list 2>/dev/null | head -5"

echo ""

# ── TASK 6 (OPTIONAL): apt / dpkg in an Ubuntu Container ──────────────────────
# Why it matters: Objective 2.4 — the exam tests BOTH families. The container
# is a real dpkg system; every command is exactly what you'd run on a server.
echo "── TASK 6 (OPTIONAL): apt + dpkg (dpkg family, containerized) ──"

echo ""
echo "[6a] One shot — full apt lifecycle inside Ubuntu 24.04:"
run_cmd "podman run --rm docker.io/library/ubuntu:24.04 bash -c 'apt update -qq && apt install -y -qq htop >/dev/null && echo INSTALLED && dpkg -l htop | tail -1 && dpkg -S /usr/bin/htop && apt remove -y -qq htop >/dev/null && echo REMOVED && apt purge -y -qq htop >/dev/null && echo PURGED-CONFIGS-TOO'"

echo ""
echo "[6b] Where Ubuntu defines its repos (contrast with 5a's .repo file):"
run_cmd "podman run --rm docker.io/library/ubuntu:24.04 bash -c 'cat /etc/apt/sources.list.d/ubuntu.sources | head -8'"
echo "  Map it mentally: baseurl<->URIs, enabled<->(file present), gpgkey<->Signed-By."

echo ""

# ── TASK 7: Build, Break, and Fix a systemd Service ───────────────────────────
# Why it matters: Objective 2.5 — you write a unit from scratch, run the verb
# tour on something disposable, then diagnose a realistic failure with
# status + journalctl (previewing 5.2's 'systemd unit failures').
echo "── TASK 7: A Disposable Unit — Full Lifecycle ──"

echo ""
echo "[7a] First, read a production unit for reference (read-only):"
run_cmd "systemctl cat sshd | head -20"

echo ""
echo "[7b] Write week05.service — every section from the cheatsheet skeleton:"
if $DRY_RUN; then
    echo "[DRY RUN] write /etc/systemd/system/week05.service (sleep infinity daemon)"
else
    sudo tee /etc/systemd/system/week05.service >/dev/null <<'EOF'
[Unit]
Description=Week 05 disposable lab service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/sleep infinity
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
fi
run_cmd "sudo systemctl daemon-reload"

echo ""
echo "[7c] The verb tour — watch state change after each:"
run_cmd "sudo systemctl start week05 && systemctl is-active week05"
run_cmd "systemctl is-enabled week05 || echo '  ^ active but NOT enabled — running now, gone after reboot'"
run_cmd "sudo systemctl enable week05 && systemctl is-enabled week05"
run_cmd "systemctl status week05 --no-pager | head -8"

echo ""
echo "[7d] Override via drop-in — add Nice=10 without touching the unit file:"
if $DRY_RUN; then
    echo "[DRY RUN] write /etc/systemd/system/week05.service.d/override.conf ([Service] Nice=10)"
else
    sudo mkdir -p /etc/systemd/system/week05.service.d
    printf '[Service]\nNice=10\n' | sudo tee /etc/systemd/system/week05.service.d/override.conf >/dev/null
fi
run_cmd "sudo systemctl daemon-reload && sudo systemctl restart week05"
run_cmd "systemctl cat week05 | tail -4"
run_cmd "ps -o pid,ni,comm -p \$(systemctl show -p MainPID --value week05)"
echo "  ^ NI=10 — Task 2's niceness, set declaratively. This drop-in is exactly"
echo "  what 'systemctl edit' creates. Objectives 2.3 and 2.5 just shook hands."

echo ""
echo "[7e] mask vs disable — try to start a masked unit:"
run_cmd "sudo systemctl stop week05 && sudo systemctl mask week05"
run_cmd "sudo systemctl start week05 2>&1 || echo '  ^ refused — masked means symlinked to /dev/null'"
run_cmd "ls -l /etc/systemd/system/week05.service"
run_cmd "sudo systemctl unmask week05"

echo ""
echo "[7f] BREAK IT — sabotage ExecStart, then diagnose from the evidence:"
run_cmd "sudo sed -i 's|/usr/bin/sleep|/usr/bin/sleeep|' /etc/systemd/system/week05.service"
run_cmd "sudo systemctl daemon-reload && sudo systemctl start week05 2>&1 || true"
echo "  Symptom: start failed. Toolbox: systemctl status, journalctl -u. Investigate"
echo "  BEFORE reading 7g — what exactly is broken?"
run_cmd "systemctl status week05 --no-pager | tail -6"
run_cmd "journalctl -u week05 -n 5 --no-pager"

echo ""
echo "[7g] The tell: status=203/EXEC + 'No such file or directory' in the journal ="
echo "     bad ExecStart path. Fix, reload, verify, clear the failure record:"
run_cmd "sudo sed -i 's|/usr/bin/sleeep|/usr/bin/sleep|' /etc/systemd/system/week05.service"
run_cmd "sudo systemctl daemon-reload && sudo systemctl start week05 && systemctl is-active week05"
run_cmd "sudo systemctl reset-failed week05 2>/dev/null; true"

echo ""
echo "[7h] Full teardown — stop, disable, remove unit + drop-in, reload:"
run_cmd "sudo systemctl disable --now week05"
run_cmd "sudo rm -rf /etc/systemd/system/week05.service /etc/systemd/system/week05.service.d"
run_cmd "sudo systemctl daemon-reload"
run_cmd "systemctl status week05 --no-pager 2>&1 | head -2"

echo ""

# ── TASK 8 (OPTIONAL): A User-Level systemd Timer ─────────────────────────────
# Why it matters: Objective 2.5 lists timer units; this is cron's modern rival,
# and user units need no sudo at all.
echo "── TASK 8 (OPTIONAL): systemd Timer, --user Scope ──"

echo ""
echo "[8a] A service + timer pair in ~/.config/systemd/user/:"
if $DRY_RUN; then
    echo "[DRY RUN] write ~/.config/systemd/user/week05-tick.{service,timer} (minutely date logger)"
else
    mkdir -p ~/.config/systemd/user
    printf '[Unit]\nDescription=Week05 tick\n\n[Service]\nType=oneshot\nExecStart=/bin/bash -c "date >> /tmp/week05-timer.log"\n' > ~/.config/systemd/user/week05-tick.service
    printf '[Unit]\nDescription=Week05 tick timer\n\n[Timer]\nOnCalendar=minutely\n\n[Install]\nWantedBy=timers.target\n' > ~/.config/systemd/user/week05-tick.timer
fi
run_cmd "systemctl --user daemon-reload && systemctl --user start week05-tick.timer"
run_cmd "systemctl --user list-timers | head -4"

echo ""
echo "[8b] After 2+ minutes, verify ticks, then tear down:"
run_cmd "cat /tmp/week05-timer.log 2>/dev/null"
run_cmd "systemctl --user stop week05-tick.timer && rm -f ~/.config/systemd/user/week05-tick.* && systemctl --user daemon-reload && rm -f /tmp/week05-timer.log"
echo "  Compare what you just had vs Task 4's crontab: list-timers showed next/last"
echo "  run; the journal captured every execution. Cron offers neither."

echo ""

# ── CLEANUP CHECK ─────────────────────────────────────────────────────────────
echo "── Cleanup Check ──"
echo "  crontab -l                                  # no week05 lines"
echo "  systemctl status week05                     # 'could not be found'"
echo "  systemctl --user list-timers                # no week05-tick"
echo "  pgrep -f 'trapdemo|sleep 300'               # nothing"
run_cmd "rm -rf $SCRATCH"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 05 Lab Complete"
echo ""
echo "  Practiced (all on tp-mudd):"
echo "  ✓ Process states read live, zombie created and proven unkillable"
echo "  ✓ trap handler vs SIGTERM/SIGHUP/SIGKILL; nice/renice asymmetry"
echo "  ✓ Job control by hand; nohup surviving terminal close"
echo "  ✓ cron heartbeat written, verified, surgically removed; at one-shot"
echo "  ✓ dnf install/query/remove + history undo; rpm -qi/-ql/-qf/-V"
echo "  ✓ (optional) full apt/dpkg lifecycle incl. remove vs purge, in a container"
echo "  ✓ Unit written from scratch: verb tour, drop-in override, mask,"
echo "    deliberate ExecStart failure diagnosed via status + journalctl"
echo "  ✓ (optional) user-scope systemd timer vs cron, compared"
echo ""
echo "  Objectives covered: 2.3, 2.4, 2.5"
echo "════════════════════════════════════════════════════════"
