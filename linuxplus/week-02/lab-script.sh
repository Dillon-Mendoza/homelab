#!/bin/bash
# Week 02 — Hardware Management + Storage
# Objectives: 1.2, 1.3
# Run on: tp-mudd only — fully self-contained, no other devices required
# Estimated time: 45–60 min (Task 5 RAID block is an optional stretch)

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
echo "  Week 02 Lab — Hardware Management + Storage"
echo "  Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN"
echo "════════════════════════════════════════════════════════"
echo ""

# ── TASK 1: Hardware Inventory on tp-mudd ─────────────────────────────────────
# Why it matters: Objective 1.2 — these are the read-only inspection tools the
# exam expects you to pick between (lsblk vs lspci vs lsusb vs lshw vs dmidecode).
echo "── TASK 1: Hardware Inventory ──"

echo ""
echo "[1a] Loaded kernel modules — filter for network/tailscale relevant ones:"
run_cmd "lsmod | grep -E 'tailscale|wireguard|tun' "

echo ""
echo "[1b] Full module list, first 20 (pipe through less when exploring on your own):"
run_cmd "lsmod | head -20"

echo ""
echo "[1c] CPU architecture and virtualization flags (confirm AMD-V / svm present —"
echo "     this matters again in Week 3 when you verify this laptop can host VMs):"
run_cmd "lscpu | grep -E 'Model name|Virtualization|Flags' "

echo ""
echo "[1d] Installed memory — slots and capacity from SMBIOS, not usage:"
run_cmd "sudo dmidecode -t memory | grep -E 'Size|Speed|Locator' "

echo ""
echo "[1e] Memory block ranges (online/offline):"
run_cmd "lsmem | head -20"

echo ""
echo "[1f] PCI devices — identify this laptop's NVMe controller and NIC:"
run_cmd "lspci | grep -iE 'sata|nvme|ethernet|network' "

echo ""
echo "[1g] USB devices currently enumerated:"
run_cmd "lsusb"

echo ""
echo "[1h] Full hardware tree, short form:"
run_cmd "sudo lshw -short"

echo ""
echo "[1i] Kernel ring buffer — recent hardware events with human-readable timestamps:"
run_cmd "dmesg -T | tail -30"

echo ""

# ── TASK 2: Module Load/Unload Cycle ──────────────────────────────────────────
# Why it matters: Objective 1.2 — modprobe vs insmod vs rmmod is a direct exam
# distinction. Doing this once with a harmless module cements the layer each
# command operates at.
echo "── TASK 2: Module Load/Unload Cycle ──"

echo ""
echo "[2a] Pick a harmless, currently-unloaded module to test with (example: dummy):"
run_cmd "modinfo dummy"

echo ""
echo "[2b] Load it with modprobe (resolves dependencies):"
run_cmd "sudo modprobe dummy"
run_cmd "lsmod | grep dummy"

echo ""
echo "[2c] Unload it cleanly:"
run_cmd "sudo rmmod dummy"
run_cmd "lsmod | grep dummy || echo 'confirmed unloaded'"

echo ""
echo "[2d] Rebuild the module dependency map (usually run after installing new modules):"
run_cmd "sudo depmod -a"

echo ""

# ── TASK 3: Build a Real LVM Stack From Loop Devices ─────────────────────────
# Why it matters: Objective 1.3 — instead of looking at someone else's LVM,
# you build the entire PV -> VG -> LV -> filesystem chain yourself, grow it,
# hit the #1 exam trap (two-step resize) on purpose, and tear it down in the
# correct order. Loop devices mean zero risk to this laptop's real disk.
echo "── TASK 3: LVM Stack — Build It Yourself ──"

LABDIR="/tmp/week02-lvm"
VG="vg_lab"

echo ""
echo "[3a] Create three 300MB backing files and attach them as loop devices"
echo "     (these are your 'disks' — everything from here on is identical to real hardware):"
run_cmd "mkdir -p $LABDIR"
run_cmd "for i in 1 2 3; do dd if=/dev/zero of=$LABDIR/disk\$i.img bs=1M count=300 status=none; done"
run_cmd "for i in 1 2 3; do sudo losetup -f $LABDIR/disk\$i.img; done"
run_cmd "losetup -a | grep week02-lvm"

echo ""
echo "[3b] Capture the assigned loop device names:"
run_cmd "D1=\$(losetup -j $LABDIR/disk1.img | cut -d: -f1); D2=\$(losetup -j $LABDIR/disk2.img | cut -d: -f1); D3=\$(losetup -j $LABDIR/disk3.img | cut -d: -f1); echo \"disks: \$D1 \$D2 \$D3\""
echo "  NOTE: if you run tasks one at a time in a shell, re-set D1/D2/D3 the same way."

echo ""
echo "[3c] Layer 1 — physical volumes on the first two disks (third stays spare for [3i]):"
run_cmd "sudo pvcreate \$D1 \$D2"
run_cmd "sudo pvs"

echo ""
echo "[3d] Layer 2 — one volume group spanning both PVs:"
run_cmd "sudo vgcreate $VG \$D1 \$D2"
run_cmd "sudo vgs && sudo vgdisplay $VG | grep -E 'VG Size|Free'"

echo ""
echo "[3e] Layer 3 — two logical volumes: absolute size (-L) and percent-of-free (-l):"
echo "  PREDICT FIRST: after a 200M LV, how much of the ~600M VG will 50%FREE take?"
run_cmd "sudo lvcreate -L 200M -n lv_ext4 $VG"
run_cmd "sudo lvcreate -l 50%FREE -n lv_xfs $VG"
run_cmd "sudo lvs"

echo ""
echo "[3f] Filesystems — ext4 on one, xfs on the other, then mount both:"
run_cmd "sudo mkfs.ext4 -q /dev/$VG/lv_ext4"
run_cmd "sudo mkfs.xfs -q /dev/$VG/lv_xfs"
run_cmd "sudo mkdir -p /mnt/lab-ext4 /mnt/lab-xfs"
run_cmd "sudo mount /dev/$VG/lv_ext4 /mnt/lab-ext4 && sudo mount /dev/$VG/lv_xfs /mnt/lab-xfs"
run_cmd "df -h /mnt/lab-ext4 /mnt/lab-xfs"

echo ""
echo "[3g] THE #1 LVM EXAM TRAP, performed live — grow the LV, then notice the"
echo "     filesystem did NOT grow with it:"
run_cmd "sudo lvextend -L +100M /dev/$VG/lv_ext4"
run_cmd "sudo lvs /dev/$VG/lv_ext4 && df -h /mnt/lab-ext4"
echo "  ^ Compare: lvs shows the new size, df still shows the old one. Now step two:"
run_cmd "sudo resize2fs /dev/$VG/lv_ext4"
run_cmd "df -h /mnt/lab-ext4"

echo ""
echo "[3h] Same two-step grow for xfs — note xfs_growfs takes the MOUNTPOINT,"
echo "     resize2fs took the DEVICE. That asymmetry is a tested detail:"
run_cmd "sudo lvextend -L +50M /dev/$VG/lv_xfs"
run_cmd "sudo xfs_growfs /mnt/lab-xfs"
run_cmd "df -h /mnt/lab-xfs"
echo "  And the famous limitation: xfs cannot shrink. There is no command to try —"
echo "  xfs_growfs has no shrink mode. ext4 can shrink, but only unmounted."

echo ""
echo "[3i] Grow the VG itself with the spare disk — this is how real servers get"
echo "     more space without downtime:"
run_cmd "sudo pvcreate \$D3 && sudo vgextend $VG \$D3"
run_cmd "sudo vgs $VG"

echo ""
echo "[3j] fstab practice with a real UUID — get it, write the entry by hand, verify:"
run_cmd "sudo blkid /dev/$VG/lv_ext4"
echo "  Manually add to /etc/fstab (then remove after [3l]):"
echo "    UUID=<uuid-from-above>  /mnt/lab-ext4  ext4  defaults,nofail  0  2"
echo "  Then verify your syntax without rebooting:"
run_cmd "sudo umount /mnt/lab-ext4 && sudo mount -a && df -h /mnt/lab-ext4"
run_cmd "sudo findmnt --verify"

echo ""
echo "[3k] Sketch the stack you just built, from memory, on paper:"
echo "     3 loop disks -> 3 PVs -> 1 VG (vg_lab) -> 2 LVs -> ext4 + xfs -> mountpoints"
echo "     If you can't draw it without looking, re-run 3c-3f before moving on."

echo ""
echo "[3l] Teardown — the ORDER is the lesson (top of the stack first):"
run_cmd "sudo umount /mnt/lab-ext4 /mnt/lab-xfs"
echo "  Manually remove your test line from /etc/fstab now."
run_cmd "sudo lvremove -y /dev/$VG/lv_ext4 /dev/$VG/lv_xfs"
run_cmd "sudo vgremove $VG"
run_cmd "sudo pvremove \$D1 \$D2 \$D3"
run_cmd "sudo losetup -d \$D1 \$D2 \$D3"
run_cmd "rm -rf $LABDIR && sudo rmdir /mnt/lab-ext4 /mnt/lab-xfs"

echo ""

# ── TASK 4: What Does THIS Laptop Actually Use? ───────────────────────────────
# Why it matters: Objective 1.3 — Fedora Workstation defaults to btrfs, not xfs
# (xfs is the RHEL server default). Knowing your own machine's layout cold makes
# every filesystem question concrete instead of abstract.
echo "── TASK 4: This Machine's Real Storage Layout ──"

echo ""
echo "[4a] Block device tree with filesystem types and UUIDs — the orientation command:"
run_cmd "lsblk -f"

echo ""
echo "[4b] What filesystem is / actually on? (Predict before you run: btrfs or xfs?)"
run_cmd "findmnt -no FSTYPE /"

echo ""
echo "[4c] The real fstab on this machine — map every entry to the six fields:"
run_cmd "grep -vE '^\s*#|^\s*$' /etc/fstab"

echo ""
echo "[4d] Kernel's live mount truth vs /etc/mtab:"
run_cmd "ls -l /etc/mtab"
run_cmd "grep ' / ' /proc/mounts"

echo ""

# ── TASK 5 (OPTIONAL STRETCH): Software RAID With mdadm ──────────────────────
# Why it matters: Objective 1.3 lists mdadm and /proc/mdstat. Building a RAID1
# mirror from loop devices and reading its status notation ([UU] vs [U_]) turns
# a memorized table into something you've watched happen. Skip if past 60 min.
echo "── TASK 5 (OPTIONAL): mdadm RAID1 on Loop Devices ──"

echo ""
echo "[5a] Two fresh 200MB loop disks:"
run_cmd "mkdir -p $LABDIR-raid && for i in 1 2; do dd if=/dev/zero of=$LABDIR-raid/r\$i.img bs=1M count=200 status=none; sudo losetup -f $LABDIR-raid/r\$i.img; done"
run_cmd "R1=\$(losetup -j $LABDIR-raid/r1.img | cut -d: -f1); R2=\$(losetup -j $LABDIR-raid/r2.img | cut -d: -f1); echo \"raid disks: \$R1 \$R2\""

echo ""
echo "[5b] Assemble a RAID1 mirror and read /proc/mdstat — look for [UU]:"
run_cmd "sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 \$R1 \$R2 --run"
run_cmd "cat /proc/mdstat"

echo ""
echo "[5c] Fail one member on purpose and read the notation change ([UU] -> [U_]):"
run_cmd "sudo mdadm /dev/md0 --fail \$R2"
run_cmd "cat /proc/mdstat"
echo "  ^ This degraded-array output is exactly what performance-based questions show."

echo ""
echo "[5d] Teardown:"
run_cmd "sudo mdadm --stop /dev/md0"
run_cmd "sudo mdadm --zero-superblock \$R1 \$R2"
run_cmd "sudo losetup -d \$R1 \$R2 && rm -rf $LABDIR-raid"

echo ""

# ── TASK 6: Disk Space vs Inode Exhaustion — See the Lie Yourself ─────────────
# Why it matters: Objective 1.3 — "No space left on device" with free space
# showing in df -h is inode exhaustion. Instead of memorizing that, you build a
# tiny filesystem with almost no inodes and hit the error on purpose.
echo "── TASK 6: Disk + Inode Usage ──"

echo ""
echo "[6a] Space and inode usage on the real system — compare the two views:"
run_cmd "df -h /"
run_cmd "df -i /"
echo "  NOTE: btrfs allocates inodes dynamically (df -i shows 0) — the exhaustion"
echo "  demo below uses ext4, where the inode table is fixed at mkfs time."

echo ""
echo "[6b] Build a 50MB ext4 filesystem with only 64 inodes:"
run_cmd "dd if=/dev/zero of=/tmp/tiny.img bs=1M count=50 status=none"
run_cmd "mkfs.ext4 -q -N 64 /tmp/tiny.img"
run_cmd "mkdir -p /tmp/tiny-mnt && sudo mount -o loop /tmp/tiny.img /tmp/tiny-mnt && sudo chown \$USER /tmp/tiny-mnt"

echo ""
echo "[6c] PREDICT FIRST: roughly how many empty files until 'No space left on device'?"
echo "     Then create files until it fails:"
run_cmd "for i in \$(seq 1 100); do touch /tmp/tiny-mnt/f\$i 2>&1 || { echo \"FAILED at file \$i\"; break; }; done"

echo ""
echo "[6d] Now read both views — space says fine, inodes say full. This is the exam scenario:"
run_cmd "df -h /tmp/tiny-mnt && df -i /tmp/tiny-mnt"

echo ""
echo "[6e] Teardown:"
run_cmd "sudo umount /tmp/tiny-mnt && rm -f /tmp/tiny.img && rmdir /tmp/tiny-mnt"

echo ""
echo "[6f] Largest directories under /var/log on this machine (real space pressure candidates):"
run_cmd "du -sh /var/log/* 2>/dev/null | sort -rh | head -10"

echo ""

# ── CLEANUP ───────────────────────────────────────────────────────────────────
echo "── Cleanup Check ──"
echo "  No leftover loop devices:      losetup -a"
echo "  No stray fstab test entries:   grep -E 'lab-ext4|week02' /etc/fstab"
echo "  No leftover md arrays:         cat /proc/mdstat"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 02 Lab Complete"
echo ""
echo "  Practiced (all on tp-mudd, no other hardware touched):"
echo "  ✓ Hardware inspection (lscpu, lsmem, lspci, lsusb, lshw, dmidecode, dmesg)"
echo "  ✓ Module load/unload cycle (modprobe, rmmod, depmod, modinfo)"
echo "  ✓ Full LVM lifecycle built from scratch: pvcreate → vgcreate → lvcreate,"
echo "    two-step grow (lvextend + resize2fs/xfs_growfs), vgextend, ordered teardown"
echo "  ✓ fstab entry with real UUID, verified via mount -a and findmnt --verify"
echo "  ✓ (optional) mdadm RAID1 build, deliberate failure, /proc/mdstat notation"
echo "  ✓ Inode exhaustion produced on purpose — df -h vs df -i distinction"
echo ""
echo "  Objectives covered: 1.2, 1.3"
echo "════════════════════════════════════════════════════════"
