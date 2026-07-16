#!/bin/bash
# Week 06 — Containers + Firewalls + OS Hardening
# Objectives: 2.6, 3.2, 3.3
# Run on: tp-mudd only — fully self-contained, no other devices required
# Estimated time: 45–60 min (Task 5 is short; Task 2 build is core — don't skip)
#
# Touches firewalld (test port, fully removed) and creates podman containers/
# images (pruned at the end). Cleanup steps are inline per task.

DRY_RUN=true  # Set to false to execute. true echoes commands instead of running them.

run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

SCRATCH="/tmp/week06"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 06 Lab — Containers + Firewalls + OS Hardening"
echo "  Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN"
echo "════════════════════════════════════════════════════════"
echo ""

run_cmd "mkdir -p $SCRATCH"

# ── TASK 1: Container Lifecycle — and Proof It's Rootless ─────────────────────
# Why it matters: Objective 2.6 — the full op sequence the exam tests, plus the
# rootless fact most people only read about: the container is YOUR process.
echo "── TASK 1: podman Lifecycle ──"

echo ""
echo "[1a] Confirm the rootless setup before anything runs:"
run_cmd "podman info 2>/dev/null | grep -A2 'rootless'"

echo ""
echo "[1b] Pull and run nginx detached, publishing 8080->80 (PREDICT: why not 80->80?):"
run_cmd "podman pull docker.io/library/nginx:alpine"
run_cmd "podman run -d --name week06web -p 8080:80 --env WEEK=six docker.io/library/nginx:alpine"
run_cmd "podman ps"

echo ""
echo "[1c] It's a real web server — Week 3's diagnostics work unchanged:"
run_cmd "curl -sI http://127.0.0.1:8080 | head -3"
run_cmd "ss -tlnp | grep 8080"

echo ""
echo "[1d] logs, exec, inspect — the three interrogation verbs:"
run_cmd "podman logs week06web | tail -3"
run_cmd "podman exec week06web sh -c 'echo inside: \$(id -u) hostname: \$(hostname) WEEK=\$WEEK'"
run_cmd "podman inspect week06web --format 'IP: {{.NetworkSettings.IPAddress}} | started: {{.State.StartedAt}}'"

echo ""
echo "[1e] THE ROOTLESS PROOF — nginx claims uid 0 inside; the HOST says otherwise:"
run_cmd "podman exec week06web id"
run_cmd "ps aux | grep 'nginx: master' | grep -v grep | awk '{print \"host sees owner: \" \$1}'"
echo "  ^ 'root' inside is your unprivileged UID outside — user namespaces at work."

echo ""
echo "[1f] Stop and remove (leave the image for Task 2's cache):"
run_cmd "podman stop week06web && podman rm week06web"
run_cmd "podman ps -a | grep week06 || echo '  gone'"

echo ""

# ── TASK 2: Build an Image — ENTRYPOINT vs CMD, Layers ────────────────────────
# Why it matters: Objective 2.6 — the Dockerfile directives are tested by name,
# and ENTRYPOINT-vs-CMD only sticks after you override one and not the other.
echo "── TASK 2: podman build ──"

echo ""
echo "[2a] Write a minimal Dockerfile exercising the tested directives:"
if $DRY_RUN; then
    echo "[DRY RUN] write $SCRATCH/Containerfile (FROM/ENV/COPY/USER/ENTRYPOINT/CMD)"
else
    cat > "$SCRATCH/Containerfile" <<'EOF'
FROM docker.io/library/alpine:latest
ENV GREETING=week06
COPY hello.sh /usr/local/bin/hello.sh
RUN chmod +x /usr/local/bin/hello.sh && adduser -D labuser
USER labuser
ENTRYPOINT ["/usr/local/bin/hello.sh"]
CMD ["default-argument"]
EOF
    cat > "$SCRATCH/hello.sh" <<'EOF'
#!/bin/sh
echo "GREETING=$GREETING | running as: $(id -un) | args: $*"
EOF
fi

echo ""
echo "[2b] Build and list — note the layer count matches the instruction count:"
run_cmd "podman build -q -t week06:v1 -f $SCRATCH/Containerfile $SCRATCH"
run_cmd "podman images | grep -E 'week06|REPOSITORY'"
run_cmd "podman history week06:v1 | head -8"

echo ""
echo "[2c] ENTRYPOINT vs CMD — run three ways, PREDICT each output first:"
run_cmd "podman run --rm week06:v1"
echo "  ^ no args: CMD supplied 'default-argument' to the ENTRYPOINT"
run_cmd "podman run --rm week06:v1 override-args here"
echo "  ^ your args REPLACED CMD, still fed to the same ENTRYPOINT"
run_cmd "podman run --rm --env GREETING=changed week06:v1"
echo "  ^ --env beat the baked-in ENV. Also note: every run printed 'labuser' — the"
echo "  USER directive means nothing in this image runs as root. That's hardening."

echo ""
echo "[2d] Tag it like a release, then inspect the duplicate:"
run_cmd "podman tag week06:v1 week06:stable && podman images | grep week06"

echo ""

# ── TASK 3: Volumes + the SELinux Label ───────────────────────────────────────
# Why it matters: Objectives 2.6 and 3.3 collide here — bind mounts on an
# enforcing system need :z/:Z, and you can watch the relabel happen.
echo "── TASK 3: Bind Mount with :Z ──"

echo ""
echo "[3a] A host directory, before — note its context:"
run_cmd "mkdir -p $SCRATCH/shared && echo 'host data' > $SCRATCH/shared/host.txt"
run_cmd "ls -Z $SCRATCH/shared/host.txt"

echo ""
echo "[3b] Mount it into a container WITH the :Z flag, write from inside:"
run_cmd "podman run --rm -v $SCRATCH/shared:/data:Z docker.io/library/alpine:latest sh -c 'cat /data/host.txt && echo container-was-here > /data/ctr.txt'"

echo ""
echo "[3c] After — the label changed to container_file_t. That's what :Z did:"
run_cmd "ls -Z $SCRATCH/shared/"
echo "  Without :Z on an enforcing host, step 3b would have died with EACCES —"
echo "  a permission error that chmod cannot fix. ls -Z is the diagnostic."

echo ""

# ── TASK 4: firewalld — the Runtime/Permanent Split, Both Directions ──────────
# Why it matters: Objective 3.2 — this split is the most-tested firewalld fact,
# and this laptop's documented policy (tailscale0-only inbound) is the baseline
# you're auditing against.
echo "── TASK 4: firewalld ──"

echo ""
echo "[4a] Orientation — zones, interfaces, current ruleset:"
run_cmd "firewall-cmd --get-default-zone"
run_cmd "firewall-cmd --get-active-zones"
run_cmd "firewall-cmd --get-zone-of-interface=tailscale0 2>/dev/null || echo '  (tailscale0 not assigned to a zone — note which zone catches it by default)'"
run_cmd "sudo firewall-cmd --list-all"
echo "  Cross-check what you see against the documented tp-mudd policy:"
echo "  no inbound except over tailscale0. Does the ruleset actually say that?"

echo ""
echo "[4b] Direction 1 — RUNTIME add, then watch --reload erase it:"
run_cmd "sudo firewall-cmd --add-port=8080/tcp && sudo firewall-cmd --query-port=8080/tcp"
run_cmd "sudo firewall-cmd --reload && sudo firewall-cmd --query-port=8080/tcp || echo '  GONE — runtime changes do not survive a reload'"

echo ""
echo "[4c] Direction 2 — PERMANENT add... which changes nothing live:"
run_cmd "sudo firewall-cmd --permanent --add-port=8080/tcp"
run_cmd "sudo firewall-cmd --query-port=8080/tcp || echo '  NOT live — --permanent wrote config only'"
run_cmd "sudo firewall-cmd --reload && sudo firewall-cmd --query-port=8080/tcp && echo '  NOW live — reload activated the permanent config'"

echo ""
echo "[4d] Clean removal (permanent + reload), verify both views agree:"
run_cmd "sudo firewall-cmd --permanent --remove-port=8080/tcp && sudo firewall-cmd --reload"
run_cmd "sudo firewall-cmd --list-ports; sudo firewall-cmd --permanent --list-ports"

echo ""
echo "[4e] Services vs ports — read one predefined service definition:"
run_cmd "firewall-cmd --info-service=ssh"

echo ""

# ── TASK 5: Under the Hood — nftables, Chains, ip_forward ─────────────────────
# Why it matters: Objective 3.2 — firewalld is a frontend; the exam still tests
# the iptables chain flow and the sysctl that makes routing possible at all.
echo "── TASK 5: The Packet Path ──"

echo ""
echo "[5a] What firewalld actually programmed — nftables is the real backend:"
run_cmd "sudo nft list ruleset | head -15"

echo ""
echo "[5b] The compatibility shim view (note 'nf_tables' in its version string):"
run_cmd "sudo iptables -V && sudo iptables -L INPUT -n | head -5"

echo ""
echo "[5c] Is this laptop a router? (PREDICT — it's not an exit node):"
run_cmd "sysctl net.ipv4.ip_forward"
echo "  ^ mudd-cloud, as a Tailscale exit node, runs with this = 1 (conceptual"
echo "  anchor). Any NAT/FORWARD-chain scenario silently assumes it."

echo ""

# ── TASK 6: Hardening Sharp Tools — umask, chattr, ACLs ───────────────────────
# Why it matters: Objective 3.3 — three mechanisms that override what ls -l
# seems to say. Each produces a 'permissions look fine but...' exam scenario.
echo "── TASK 6: umask + chattr + ACLs ──"

echo ""
echo "[6a] umask math — predict the modes before each touch:"
run_cmd "umask"
run_cmd "touch $SCRATCH/default.txt && mkdir $SCRATCH/default.dir && stat -c '%a %n' $SCRATCH/default.txt $SCRATCH/default.dir"
run_cmd "( umask 027 && touch $SCRATCH/strict.txt && mkdir $SCRATCH/strict.dir && stat -c '%a %n' $SCRATCH/strict.txt $SCRATCH/strict.dir )"
echo "  ^ 027: file 666-027=640, dir 777-027=750. The subshell kept it temporary."

echo ""
echo "[6b] Immutable — watch root itself get refused:"
run_cmd "echo 'protect me' > $SCRATCH/immutable.txt && sudo chattr +i $SCRATCH/immutable.txt"
run_cmd "lsattr $SCRATCH/immutable.txt"
run_cmd "sudo rm $SCRATCH/immutable.txt 2>&1 || echo '  ^ root DENIED — +i beats uid 0'"
run_cmd "ls -l $SCRATCH/immutable.txt | awk '{print \$1}'"
echo "  ^ and ls -l shows nothing unusual — only lsattr reveals why. Undo:"
run_cmd "sudo chattr -i $SCRATCH/immutable.txt && rm $SCRATCH/immutable.txt && echo '  removable again'"

echo ""
echo "[6c] ACLs — grant one extra user read access, spot the + in ls -l:"
run_cmd "echo 'acl demo' > $SCRATCH/acl.txt && setfacl -m u:nobody:r $SCRATCH/acl.txt"
run_cmd "ls -l $SCRATCH/acl.txt | awk '{print \$1}'"
run_cmd "getfacl --omit-header $SCRATCH/acl.txt"
run_cmd "setfacl -b $SCRATCH/acl.txt && ls -l $SCRATCH/acl.txt | awk '{print \$1}'"
echo "  ^ -b stripped every ACL; the + is gone."

echo ""

# ── TASK 7: SELinux — Contexts, the mv Bug, and the Audit Trail ───────────────
# Why it matters: Objective 3.3 + 5.4 preview — this laptop enforces SELinux
# for real, so every command here reads live policy, not a demo.
echo "── TASK 7: SELinux on an Enforcing Host ──"

echo ""
echo "[7a] Mode and identity:"
run_cmd "getenforce"
run_cmd "id -Z"
run_cmd "ls -Z /etc/ssh/sshd_config"

echo ""
echo "[7b] THE mv BUG — create a file in your home, mv one copy and cp another"
echo "     into /tmp, then compare contexts (PREDICT which will differ):"
run_cmd "touch ~/week06-ctx.txt && ls -Z ~/week06-ctx.txt"
run_cmd "cp ~/week06-ctx.txt /tmp/week06-cp.txt && mv ~/week06-ctx.txt /tmp/week06-mv.txt"
run_cmd "ls -Z /tmp/week06-cp.txt /tmp/week06-mv.txt"
echo "  ^ cp inherited /tmp's context (tmp_t); mv DRAGGED user_home_t along. In a"
echo "  service directory that stowaway context is an outage. The fix:"
run_cmd "restorecon -v /tmp/week06-mv.txt"
run_cmd "ls -Z /tmp/week06-mv.txt && rm /tmp/week06-cp.txt /tmp/week06-mv.txt"

echo ""
echo "[7c] chcon is temporary — set a wrong type on purpose, restorecon reverts it:"
run_cmd "touch $SCRATCH/chcon.txt && chcon -t container_file_t $SCRATCH/chcon.txt && ls -Z $SCRATCH/chcon.txt"
run_cmd "restorecon -v $SCRATCH/chcon.txt && ls -Z $SCRATCH/chcon.txt"
echo "  ^ policy won. Permanent custom labels need: semanage fcontext -a, THEN"
echo "  restorecon — chcon alone loses to any relabel."

echo ""
echo "[7d] Booleans — policy feature toggles, live:"
run_cmd "getsebool -a | head -5"
run_cmd "getsebool container_manage_cgroup 2>/dev/null || getsebool -a | grep container | head -3"

echo ""
echo "[7e] The audit trail — any AVC denials today? (Task 3 without :Z would be here):"
run_cmd "sudo ausearch -m AVC -ts today 2>/dev/null | tail -8 || echo '  (no denials today — a quiet log on an enforcing host is the goal state)'"

echo ""

# ── TASK 8: SSH + sudo Posture Check ──────────────────────────────────────────
# Why it matters: Objective 3.3 — audit the machine you actually depend on,
# using the effective-config tools rather than eyeballing files.
echo "── TASK 8: SSH Hardening + sudo Audit ──"

echo ""
echo "[8a] What sshd is ACTUALLY enforcing (post-includes, not one file's claim):"
run_cmd "sudo sshd -T 2>/dev/null | grep -Ei '^(permitrootlogin|passwordauthentication|x11forwarding|allowusers|allowgroups)' || echo '  (sshd not installed/running — evaluate the directives conceptually)'"
echo "  Fleet posture says: PermitRootLogin no, PasswordAuthentication no. Verify."

echo ""
echo "[8b] sudoers syntax health + who has what:"
run_cmd "sudo visudo -c"
run_cmd "sudo ls /etc/sudoers.d/"
run_cmd "sudo grep -rE '^[^#]*NOPASSWD' /etc/sudoers /etc/sudoers.d/ || echo '  no NOPASSWD grants — every sudo requires auth'"
run_cmd "getent group wheel"

echo ""
echo "[8c] The audit trail — your own recent sudo activity, attributed by name:"
run_cmd "journalctl _COMM=sudo -n 8 --no-pager | tail -8"
echo "  ^ this attribution is the whole argument for sudo -i over su -."

echo ""
echo "[8d] Cleartext-protocol check — none of these should exist here:"
run_cmd "rpm -q telnet-server tftp-server vsftpd 2>&1 | grep -v 'not installed' || echo '  clean — no telnet/tftp/ftp servers'"

echo ""

# ── CLEANUP ───────────────────────────────────────────────────────────────────
echo "── Cleanup ──"
run_cmd "podman rmi week06:v1 week06:stable 2>/dev/null; podman image prune -f >/dev/null 2>&1; true"
run_cmd "rm -rf $SCRATCH"
echo "  Verify: podman images | grep week06        # nothing"
echo "          sudo firewall-cmd --list-ports      # no 8080"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 06 Lab Complete"
echo ""
echo "  Practiced (all on tp-mudd):"
echo "  ✓ Full podman lifecycle + rootless proof (root inside = your UID outside)"
echo "  ✓ Image built from a Containerfile; ENTRYPOINT vs CMD overridden live"
echo "  ✓ Bind mount :Z relabeling observed with ls -Z"
echo "  ✓ firewalld runtime/permanent split demonstrated in BOTH failure directions"
echo "  ✓ nftables backend read; iptables chain flow; ip_forward checked"
echo "  ✓ umask math, chattr +i defeating root, ACLs and the ls -l +"
echo "  ✓ mv-vs-cp context bug produced and fixed with restorecon; chcon impermanence"
echo "  ✓ sshd -T effective config, visudo -c, NOPASSWD sweep, sudo audit trail"
echo ""
echo "  Objectives covered: 2.6, 3.2, 3.3"
echo "════════════════════════════════════════════════════════"
