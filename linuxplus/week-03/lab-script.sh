#!/bin/bash
# Week 03 — Networking + Backup + Virtualization
# Objectives: 1.4, 1.6, 1.7
# Run on: tp-mudd only — fully self-contained. Tasks 1, 2, 4, 5, 6 need no
# network at all beyond what's already on this laptop; Task 3's path tools
# use public internet targets (1.1.1.1), never other homelab devices.
# Estimated time: 45–60 min (Task 6g VM build is an optional stretch)

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

# ── TASK 1: Map This Machine's Network From the CLI ───────────────────────────
# Why it matters: Objective 1.4 — the exam hands you command output and asks
# what it means. Generating that output from YOUR laptop makes it readable forever.
echo "── TASK 1: Network Topology (tp-mudd) ──"

echo ""
echo "[1a] All interfaces, brief form — identify wifi, loopback, tailscale0:"
run_cmd "ip -br addr"

echo ""
echo "[1b] Link state and MTU — PREDICT FIRST: will tailscale0's MTU be above or"
echo "     below the physical NIC's 1500, and why?"
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
echo "  On paper: for a packet to 8.8.8.8 vs a packet to a 100.64.0.0/10 address,"
echo "  trace which route each takes. Longest-prefix match decides — not list order."
echo ""

# ── TASK 2: DNS Resolution Chain — Trace It, Then Break the Order ─────────────
# Why it matters: Objective 1.4 — the files/dns pipeline is memorized by most
# people and understood by few. You'll trace yours, then PROVE the nsswitch
# order by overriding a name in /etc/hosts and watching it win over DNS.
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
echo "[2d] Query through the default path, then ISOLATE by querying a specific"
echo "     server directly — the core 5.3 troubleshooting move:"
run_cmd "dig +short anthropic.com"
run_cmd "dig +short anthropic.com @1.1.1.1"
echo "  Same answer from both? Then your resolver chain is healthy. Different or"
echo "  timeout on the first? The problem is YOUR resolver, not the record."

echo ""
echo "[2e] PROVE the nsswitch order — override a real name in /etc/hosts and watch"
echo "     'files' beat 'dns'. getent uses the full NSS chain; dig ignores it:"
run_cmd "echo '127.0.0.1 anthropic.com' | sudo tee -a /etc/hosts"
run_cmd "getent hosts anthropic.com"
run_cmd "dig +short anthropic.com"
echo "  ^ getent returned 127.0.0.1 (reads /etc/hosts first), dig returned the real"
echo "  IP (talks straight to DNS, never consults nsswitch). THAT's the pipeline."
run_cmd "sudo sed -i '/^127.0.0.1 anthropic.com/d' /etc/hosts"
run_cmd "getent hosts anthropic.com"

echo ""
echo "[2f] Watch a query on the wire — run this in a second terminal, then re-run 2d:"
echo "  sudo tcpdump -ni any port 53"

echo ""
echo "[2g] nslookup gives the same answer through the older interface (still on the exam):"
run_cmd "nslookup anthropic.com"

echo ""

# ── TASK 3: Run Both Ends — Service Up, Then Diagnose It ──────────────────────
# Why it matters: Objective 1.4 — each tool answers a different question. By
# running the SERVER yourself on localhost, you see both sides of every check
# instead of poking at a machine someone else configured.
echo "── TASK 3: Port + Path Diagnostics (you own both ends) ──"

echo ""
echo "[3a] Start a throwaway HTTP server on loopback (leave it running):"
run_cmd "python3 -m http.server 8080 --bind 127.0.0.1 --directory /tmp &>/tmp/week03-http.log & echo \"server PID: \$!\""

echo ""
echo "[3b] Find it with ss — this is the 'is the service actually up' move:"
run_cmd "ss -tlnp | grep 8080"

echo ""
echo "[3c] Transport-layer check — is the port open and accepting?"
run_cmd "nc -zv 127.0.0.1 8080"
echo "  And the failure case, so you know what CLOSED looks like:"
run_cmd "nc -zv 127.0.0.1 8081 || echo '(connection refused — nothing listening there)'"

echo ""
echo "[3d] HTTP-layer check — headers only, then note how it differs from 3c:"
run_cmd "curl -I http://127.0.0.1:8080"

echo ""
echo "[3e] Port sweep of this machine — compare against what ss showed in 3b:"
run_cmd "nmap -p 22,8080,8081 127.0.0.1"

echo ""
echo "[3f] Watch your own traffic on the wire — loopback capture while you curl:"
echo "  Terminal 1:  sudo tcpdump -i lo -n port 8080"
echo "  Terminal 2:  curl -s http://127.0.0.1:8080 >/dev/null"
echo "  Read the capture: SYN, SYN-ACK, ACK, then HTTP — the handshake is real."

echo ""
echo "[3g] Stop the server:"
run_cmd "pkill -f 'http.server 8080' && ss -tlnp | grep 8080 || echo 'confirmed down'"

echo ""
echo "[3h] Path tools against the internet (no homelab devices involved):"
run_cmd "ping -c 3 1.1.1.1"
run_cmd "tracepath -m 8 1.1.1.1"
run_cmd "mtr --report --report-cycles 5 1.1.1.1"
echo "  Reading order: ping = reachable at all? tracepath = what path, what MTU?"
echo "  mtr = WHERE along the path is the loss?"

echo ""
echo "[3i] Throughput with both ends on this machine — iperf3 server + client:"
run_cmd "iperf3 -s -D -1"
run_cmd "iperf3 -c 127.0.0.1 -t 3"
echo "  ^ Loopback throughput is memory-speed, not network-speed — the point is the"
echo "  workflow: one end runs -s, the other -c <server>. Same on any real pair."

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

# ── TASK 5: rsync — Trailing Slash and --delete, Proven Locally ───────────────
# Why it matters: Objective 1.6 — the trailing-slash rule and --delete safety
# only become real when you watch them change what lands at the destination.
# Local directories show it with instant feedback; the remote syntax
# (user@host:path) is identical, just with SSH as transport.
echo "── TASK 5: rsync Semantics ──"

echo ""
echo "[5a] Build a small source tree:"
run_cmd "mkdir -p $WORKDIR/synctest && echo 'file one' > $WORKDIR/synctest/a.txt && echo 'file two' > $WORKDIR/synctest/b.txt"

echo ""
echo "[5b] PREDICT FIRST: what will dest-A and dest-B each contain? Write it down,"
echo "     then run both and check yourself:"
run_cmd "rsync -av $WORKDIR/synctest/ $WORKDIR/dest-A/"
run_cmd "rsync -av $WORKDIR/synctest  $WORKDIR/dest-B/"
run_cmd "ls -R $WORKDIR/dest-A $WORKDIR/dest-B"
echo "  ^ dest-A holds the CONTENTS; dest-B holds synctest/ itself. One character."

echo ""
echo "[5c] Delete a source file, then MIRROR with --delete — dry-run first, always:"
run_cmd "rm $WORKDIR/synctest/b.txt"
run_cmd "rsync -avn --delete $WORKDIR/synctest/ $WORKDIR/dest-A/"
echo "  Read the dry-run output ('deleting b.txt'). Only then drop the -n:"
run_cmd "rsync -av --delete $WORKDIR/synctest/ $WORKDIR/dest-A/"
run_cmd "ls $WORKDIR/dest-A/"

echo ""
echo "[5d] Verify source and mirror match exactly:"
run_cmd "diff -r $WORKDIR/synctest $WORKDIR/dest-A && echo 'MIRROR VERIFIED'"

echo ""
echo "[5e] Re-run 5c's real sync unchanged — note it transfers ~nothing. Delta algorithm:"
run_cmd "rsync -av --delete $WORKDIR/synctest/ $WORKDIR/dest-A/"

echo ""
echo "[5f] The remote form uses identical semantics over SSH — prove it against"
echo "     THIS machine if sshd is running (optional):"
echo "  systemctl is-active sshd && rsync -avz $WORKDIR/synctest/ localhost:/tmp/week03-remote/"
echo "  Same trailing-slash rules, same --delete rules, SSH is just the transport."

echo ""

# ── TASK 6: Virtualization — This Laptop IS a Hypervisor ──────────────────────
# Why it matters: Objective 1.7 — tp-mudd has AMD-V. Verify the KVM stack from
# the CPU flag up, master qemu-img on throwaway images, and (stretch) create a
# disposable VM you can snapshot and destroy without consequence.
echo "── TASK 6: KVM/QEMU/libvirt on tp-mudd ──"

echo ""
echo "[6a] Bottom of the stack — does the CPU expose virtualization (svm = AMD-V)?"
run_cmd "lscpu | grep -i virtualization"

echo ""
echo "[6b] Is the KVM kernel module loaded, and does /dev/kvm exist?"
run_cmd "lsmod | grep kvm"
run_cmd "ls -l /dev/kvm"

echo ""
echo "[6c] Nested virtualization state (1 or Y = a VM here could host VMs):"
run_cmd "cat /sys/module/kvm_amd/parameters/nested"

echo ""
echo "[6d] qemu-img — create a thin-provisioned qcow2 and READ the info output:"
run_cmd "qemu-img create -f qcow2 $WORKDIR/practice.qcow2 5G"
run_cmd "qemu-img info $WORKDIR/practice.qcow2"
echo "  ^ 'virtual size: 5G, disk size: ~200K' — THAT is thin provisioning, live."

echo ""
echo "[6e] Grow it, then convert to raw and compare on-disk size:"
run_cmd "qemu-img resize $WORKDIR/practice.qcow2 +2G"
run_cmd "qemu-img info $WORKDIR/practice.qcow2"
run_cmd "qemu-img convert -f qcow2 -O raw $WORKDIR/practice.qcow2 $WORKDIR/practice.raw"
run_cmd "ls -lhs $WORKDIR/practice.qcow2 $WORKDIR/practice.raw"
echo "  ^ raw allocates differently and holds no snapshots — the qcow2/raw tradeoff"
echo "  from the cheatsheet, visible in ls output."

echo ""
echo "[6f] Remember Week 2's lesson stacked one deeper: qemu-img resize grew the"
echo "     VIRTUAL disk. A real guest would still need the partition grown AND the"
echo "     filesystem grown INSIDE it. Three layers now, not two."

echo ""
echo "[6g] OPTIONAL STRETCH (adds ~20 min + one package group): build a throwaway"
echo "     VM and run the full virsh lifecycle against something you own:"
echo "     sudo dnf install @virtualization"
echo "     sudo systemctl enable --now libvirtd"
echo "     virt-install --name lab-vm --memory 1024 --vcpus 1 \\"
echo "       --disk size=5 --install fedora42 --nographics   # or --cdrom an ISO"
echo "     Then, in order, observing state after each:"
echo "     virsh list --all / virsh dominfo lab-vm / virsh domblklist lab-vm"
echo "     virsh snapshot-create-as lab-vm clean 'fresh install'"
echo "     virsh snapshot-list lab-vm / virsh snapshot-revert lab-vm clean"
echo "     virsh destroy lab-vm      # hard power-off — VM still DEFINED. Verify!"
echo "     virsh list --all          # lab-vm shows 'shut off', not gone"
echo "     virsh undefine lab-vm --remove-all-storage   # THIS is deletion"
echo "     The destroy-vs-undefine distinction is a guaranteed exam question, and"
echo "     you just watched both happen to a VM that cost you nothing."

echo ""

# ── CLEANUP ───────────────────────────────────────────────────────────────────
echo "── Cleanup Check ──"
echo "  rm -rf $WORKDIR /tmp/week03-http.log"
echo "  grep anthropic /etc/hosts        # must return nothing (2e cleanup ran)"
echo "  ss -tlnp | grep 8080             # must return nothing (3g ran)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 03 Lab Complete"
echo ""
echo "  Practiced (all on tp-mudd, no other devices required):"
echo "  ✓ Topology mapping (ip addr/link/route, ss, ip neigh)"
echo "  ✓ DNS chain traced AND proven — /etc/hosts override beat DNS via nsswitch"
echo "  ✓ Ran both ends: local HTTP server diagnosed with ss, nc, curl, nmap, tcpdump"
echo "  ✓ iperf3 server+client workflow; ping/tracepath/mtr reading order"
echo "  ✓ tar create/verify/extract + compression comparison + cpio + zgrep"
echo "  ✓ rsync trailing-slash semantics, --delete with dry-run, delta transfer, diff -r verify"
echo "  ✓ KVM stack verified from CPU flag up; qemu-img create/info/resize/convert"
echo ""
echo "  Objectives covered: 1.4, 1.6, 1.7"
echo "════════════════════════════════════════════════════════"
