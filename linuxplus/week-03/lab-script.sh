#!/bin/bash
# Week 03 — Networking + Backup + Virtualization
# Objectives: 1.4, 1.6, 1.7
# Run on: tp-mudd (primary), with SSH tasks to dell-ubuntu for virsh/KVM inspection
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
echo "  Week 03 Lab — Networking + Backup + Virtualization"
echo "  Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN"
echo "════════════════════════════════════════════════════════"
echo ""

# ── TASK 1: Map the Network Topology From the CLI ─────────────────────────────
# Why it matters: Objective 1.4 — the exam hands you command output and asks
# what it means. Generating that output from YOUR mesh makes it readable forever.
echo "── TASK 1: Network Topology (tp-mudd) ──"

echo ""
echo "[1a] All interfaces, brief form — identify physical NIC, wifi, tailscale0:"
run_cmd "ip -br addr"

echo ""
echo "[1b] Link state and MTU — note tailscale0's MTU vs the physical NIC's 1500:"
run_cmd "ip link"

echo ""
echo "[1c] Routing table — find the default route AND the Tailscale 100.64.0.0/10 routes:"
run_cmd "ip route"

echo ""
echo "[1d] Everything listening on this box, with owning process:"
run_cmd "sudo ss -tulpn"

echo ""
echo "[1e] Neighbor (ARP) cache — who has this box talked to on the local segment:"
run_cmd "ip neigh"

echo ""
echo "  On paper: sketch tp-mudd's interfaces -> routes -> which route a packet"
echo "  to muddpi takes vs. a packet to 8.8.8.8. Longest-prefix match decides."
echo ""

# ── TASK 2: DNS Resolution Chain ──────────────────────────────────────────────
# Why it matters: Objective 1.4 — this fleet just moved DNS to Pi-hole via
# Tailscale. Tracing the actual resolution path beats memorizing a diagram,
# and 'dig @server' isolation is a core 5.3 troubleshooting move.
echo "── TASK 2: DNS Resolution Chain ──"

echo ""
echo "[2a] What does resolv.conf actually point to (symlink? MagicDNS 100.100.100.100?):"
run_cmd "ls -l /etc/resolv.conf"
run_cmd "cat /etc/resolv.conf"

echo ""
echo "[2b] Per-interface DNS truth from systemd-resolved:"
run_cmd "resolvectl status"

echo ""
echo "[2c] Resolution ORDER — which sources, in what sequence:"
run_cmd "grep '^hosts:' /etc/nsswitch.conf"

echo ""
echo "[2d] Query through the default path, then isolate by querying Pi-hole directly:"
run_cmd "dig +short anthropic.com"
echo "  Then directly against pi-zero's Pi-hole (use its Tailscale IP):"
echo "  dig anthropic.com @<pi-zero-tailscale-ip>"

echo ""
echo "[2e] Watch a query on the wire while running the dig above in another terminal:"
echo "  sudo tcpdump -i tailscale0 -n port 53"

echo ""
echo "[2f] nslookup gives the same answer through the older interface (still on the exam):"
run_cmd "nslookup anthropic.com"

echo ""

# ── TASK 3: Path and Port Diagnostics Across the Mesh ─────────────────────────
# Why it matters: Objective 1.4 — each tool answers a different question.
# Running them against real tiers shows the ACL model in tool output.
echo "── TASK 3: Path + Port Diagnostics ──"

echo ""
echo "[3a] Reachability — one host per tier:"
run_cmd "ping -c 3 dell-ubuntu"
run_cmd "ping -c 3 muddpi"
run_cmd "ping -c 3 pi-zero"

echo ""
echo "[3b] Path MTU discovery without root:"
run_cmd "tracepath dell-ubuntu"

echo ""
echo "[3c] Per-hop loss statistics to the cloud exit node:"
run_cmd "mtr --report --report-cycles 10 mudd-cloud"

echo ""
echo "[3d] Is Gitea's port actually accepting connections (transport-layer check):"
run_cmd "nc -zv dell-ubuntu 3000"

echo ""
echo "[3e] Same service at the HTTP layer — headers only:"
run_cmd "curl -I http://dell-ubuntu:3000"

echo ""
echo "[3f] Port sweep of one host — compare against its documented UFW policy:"
run_cmd "nmap -p 22,80,443,3000,9443,19999 dell-ubuntu"

echo ""

# ── TASK 4: tar + Compression Lifecycle ───────────────────────────────────────
# Why it matters: Objective 1.6 — create/verify/extract is the full cycle the
# exam tests, and the compression-flag-to-extension mapping only sticks by use.
echo "── TASK 4: tar Archive Lifecycle ──"

WORKDIR="/tmp/week03-backup"

echo ""
echo "[4a] Archive /etc with gzip (note: tar drops the leading / — watch the warning):"
run_cmd "mkdir -p $WORKDIR"
run_cmd "sudo tar -czvf $WORKDIR/etc-backup.tar.gz /etc 2>&1 | tail -5"

echo ""
echo "[4b] VERIFY contents without extracting — always do this before trusting a backup:"
run_cmd "tar -tzvf $WORKDIR/etc-backup.tar.gz | head -15"

echo ""
echo "[4c] Same source, xz compression — compare size and how much longer it takes:"
run_cmd "sudo tar -cJvf $WORKDIR/etc-backup.tar.xz /etc 2>/dev/null | tail -1"
run_cmd "ls -lh $WORKDIR/"

echo ""
echo "[4d] Extract the gzip archive to a scratch location with -C:"
run_cmd "mkdir -p $WORKDIR/restore"
run_cmd "tar -xzvf $WORKDIR/etc-backup.tar.gz -C $WORKDIR/restore 2>&1 | tail -3"
run_cmd "ls $WORKDIR/restore/etc | head -10"

echo ""
echo "[4e] cpio for contrast — it reads the file list from stdin:"
run_cmd "find /etc -maxdepth 1 -name '*.conf' 2>/dev/null | cpio -ov > $WORKDIR/confs.cpio"
run_cmd "cpio -tv < $WORKDIR/confs.cpio | head -5"

echo ""
echo "[4f] Read rotated logs WITHOUT extracting:"
run_cmd "ls /var/log/*.gz 2>/dev/null | head -3"
run_cmd "zgrep -il 'error' /var/log/*.gz 2>/dev/null | head -5"

echo ""

# ── TASK 5: rsync Between tp-mudd and dell-ubuntu ─────────────────────────────
# Why it matters: Objective 1.6 — the trailing-slash rule and --delete safety
# only become real when you watch them change what lands on the far end.
echo "── TASK 5: rsync Over Tailscale ──"

echo ""
echo "[5a] Build a small test tree:"
run_cmd "mkdir -p $WORKDIR/synctest && echo 'file one' > $WORKDIR/synctest/a.txt && echo 'file two' > $WORKDIR/synctest/b.txt"

echo ""
echo "[5b] Trailing slash — contents into target:"
run_cmd "rsync -avz $WORKDIR/synctest/ dell-ubuntu:/tmp/week03-sync/"

echo ""
echo "[5c] No trailing slash — directory itself lands inside target. Compare on the far end:"
run_cmd "rsync -avz $WORKDIR/synctest dell-ubuntu:/tmp/week03-sync-b/"
echo "  Then: ssh dell-ubuntu 'ls -R /tmp/week03-sync /tmp/week03-sync-b'"

echo ""
echo "[5d] Delete a local file, then MIRROR with --delete — dry-run first, always:"
run_cmd "rm $WORKDIR/synctest/b.txt"
run_cmd "rsync -avzn --delete $WORKDIR/synctest/ dell-ubuntu:/tmp/week03-sync/"
echo "  Read the dry-run output. Only then drop the -n and run it for real."

echo ""
echo "[5e] Verify the mirror matches:"
echo "  ssh dell-ubuntu 'ls /tmp/week03-sync/'   # b.txt should be gone after real run"

echo ""
echo "[5f] Re-run 5b unchanged — note it transfers ~nothing. This is the delta algorithm."
run_cmd "rsync -avz $WORKDIR/synctest/ dell-ubuntu:/tmp/week03-sync/"

echo ""

# ── TASK 6: KVM Inspection on dell-ubuntu ─────────────────────────────────────
# Why it matters: Objective 1.7 — dell-fedora is a real production VM. Read-only
# this session: inspect the stack, do NOT snapshot/revert a VM running n8n.
echo "── TASK 6: KVM/libvirt Stack (dell-ubuntu) ──"

echo ""
echo "[6a] All defined VMs and their states:"
echo "  ssh dell-ubuntu 'virsh list --all'"

echo ""
echo "[6b] Resource allocation for the Fedora VM — CPU, RAM, autostart:"
echo "  ssh dell-ubuntu 'virsh dominfo dell-fedora'"

echo ""
echo "[6c] Which disk image files back it:"
echo "  ssh dell-ubuntu 'virsh domblklist dell-fedora'"

echo ""
echo "[6d] Image properties — format, virtual size vs actual on-disk size:"
echo "  ssh dell-ubuntu 'sudo qemu-img info <path-from-6c>'"
echo "  If virtual > disk size: that is thin provisioning (qcow2)."

echo ""
echo "[6e] Which network type the VM uses (look for interface type= in the XML):"
echo "  ssh dell-ubuntu 'virsh dumpxml dell-fedora | grep -A3 \"interface type\"'"

echo ""
echo "[6f] Is the KVM module loaded, and is nested virt enabled on the host:"
echo "  ssh dell-ubuntu 'lsmod | grep kvm; cat /sys/module/kvm_*/parameters/nested'"

echo ""
echo "[6g] Local practice — create and inspect a throwaway qcow2 (no VM attached):"
run_cmd "qemu-img create -f qcow2 $WORKDIR/practice.qcow2 5G"
run_cmd "qemu-img info $WORKDIR/practice.qcow2"
run_cmd "qemu-img resize $WORKDIR/practice.qcow2 +2G"
run_cmd "qemu-img info $WORKDIR/practice.qcow2"

echo ""

# ── CLEANUP ───────────────────────────────────────────────────────────────────
echo "── Cleanup Check ──"
echo "  Local:  rm -rf $WORKDIR"
echo "  Remote: ssh dell-ubuntu 'rm -rf /tmp/week03-sync /tmp/week03-sync-b'"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 03 Lab Complete"
echo ""
echo "  Practiced:"
echo "  ✓ Topology mapping (ip addr/link/route, ss, ip neigh)"
echo "  ✓ DNS chain tracing (resolv.conf, resolvectl, nsswitch, dig @server, tcpdump)"
echo "  ✓ Path/port diagnostics (ping, tracepath, mtr, nc, curl, nmap)"
echo "  ✓ tar create/verify/extract + compression comparison + cpio + zgrep"
echo "  ✓ rsync trailing-slash semantics, --delete with dry-run, delta transfer"
echo "  ✓ Real KVM stack inspection + qemu-img create/info/resize"
echo ""
echo "  Objectives covered: 1.4, 1.6, 1.7"
echo "════════════════════════════════════════════════════════"
