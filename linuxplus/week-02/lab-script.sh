#!/bin/bash
# Week 02 — Hardware Management + Storage
# Objectives: 1.2, 1.3
# Run on: tp-mudd (primary), with SSH tasks to dell-ubuntu for LVM inspection
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
echo "[1b] Full module list, piped through less equivalent (head for lab output):"
run_cmd "lsmod | head -20"

echo ""
echo "[1c] CPU architecture and virtualization flags (confirm AMD-V / svm present):"
run_cmd "lscpu | grep -E 'Model name|Virtualization|Flags' "

echo ""
echo "[1d] Installed memory — slots and capacity from SMBIOS, not usage:"
run_cmd "sudo dmidecode -t memory | grep -E 'Size|Speed|Locator' "

echo ""
echo "[1e] Memory block ranges (online/offline):"
run_cmd "lsmem | head -20"

echo ""
echo "[1f] PCI devices — identify storage controller and NIC:"
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

# ── TASK 3: LVM Inspection on dell-ubuntu ─────────────────────────────────────
# Why it matters: Objective 1.3 — map a REAL LVM stack instead of a hypothetical
# one. This is the production target device, so treat it read-only this session.
echo "── TASK 3: LVM Stack Inspection (dell-ubuntu) ──"

echo ""
echo "[3a] Physical volumes:"
echo "  Run manually over SSH: ssh dell-ubuntu 'sudo pvdisplay'"

echo ""
echo "[3b] Volume groups:"
echo "  Run manually over SSH: ssh dell-ubuntu 'sudo vgdisplay'"

echo ""
echo "[3c] Logical volumes:"
echo "  Run manually over SSH: ssh dell-ubuntu 'sudo lvdisplay'"

echo ""
echo "[3d] Compact one-line summaries of all three layers:"
echo "  Run manually over SSH: ssh dell-ubuntu 'sudo pvs; sudo vgs; sudo lvs'"

echo ""
echo "[3e] Block device tree with filesystem type and UUID:"
echo "  Run manually over SSH: ssh dell-ubuntu 'lsblk -f'"

echo ""
echo "  After running the above manually, sketch the stack on paper:"
echo "  PV(s) -> VG name -> LV name(s) -> filesystem type -> mountpoint"

echo ""

# ── TASK 4: Loop Device Practice (Safe, Local) ────────────────────────────────
# Why it matters: Objective 1.3 — practicing mkfs/mount/fstab against a loop
# device is zero-risk. No real disk touched, but every command is identical to
# what you'd run against a physical partition.
echo "── TASK 4: Loop Device — Filesystem + Mount Practice ──"

LOOPFILE="/tmp/week02-disk.img"
LOOPMNT="/tmp/week02-mnt"

echo ""
echo "[4a] Create a 512MB backing file and attach it as a loop device:"
run_cmd "dd if=/dev/zero of=$LOOPFILE bs=1M count=512"
run_cmd "sudo losetup -fP $LOOPFILE"
run_cmd "losetup -a | grep week02-disk"

echo ""
echo "[4b] Identify the loop device assigned (example: /dev/loop0):"
run_cmd "LOOPDEV=\$(losetup -j $LOOPFILE | cut -d: -f1) && echo \"Loop device: \$LOOPDEV\""

echo ""
echo "[4c] Format it ext4:"
run_cmd "sudo mkfs.ext4 \$(losetup -j $LOOPFILE | cut -d: -f1)"

echo ""
echo "[4d] Get its UUID and filesystem type (what you'd put in fstab):"
run_cmd "sudo blkid \$(losetup -j $LOOPFILE | cut -d: -f1)"

echo ""
echo "[4e] Mount it, add a test entry to /etc/fstab using nofail, then verify with mount -a:"
run_cmd "sudo mkdir -p $LOOPMNT"
echo "  Manually add to /etc/fstab (use the UUID from 4d):"
echo "    UUID=<uuid-from-4d>  $LOOPMNT  ext4  defaults,nofail  0  2"
run_cmd "sudo mount -a"
run_cmd "df -h $LOOPMNT"
run_cmd "mount | grep $LOOPMNT"

echo ""
echo "[4f] Write a file, confirm space usage tracks it:"
run_cmd "sudo dd if=/dev/zero of=$LOOPMNT/testfile bs=1M count=50"
run_cmd "df -h $LOOPMNT"

echo ""
echo "[4g] Cleanup — unmount, remove the fstab entry, detach the loop device:"
run_cmd "sudo umount $LOOPMNT"
echo "  Manually remove the line you added to /etc/fstab"
run_cmd "sudo losetup -d \$(losetup -j $LOOPFILE | cut -d: -f1)"
run_cmd "rm -f $LOOPFILE"
run_cmd "rmdir $LOOPMNT"

echo ""

# ── TASK 5: Disk and Inode Usage ──────────────────────────────────────────────
# Why it matters: Objective 1.3 — df -h alone hides inode exhaustion. Confirming
# both metrics on a real system is the exam scenario made concrete.
echo "── TASK 5: Disk + Inode Usage ──"

echo ""
echo "[5a] Filesystem space usage, human-readable:"
run_cmd "df -h"

echo ""
echo "[5b] Inode usage — compare against 5a, look for a filesystem with high inode %% but low space %%:"
run_cmd "df -i"

echo ""
echo "[5c] Largest directories under /var/log (candidate for space pressure):"
run_cmd "du -sh /var/log/* 2>/dev/null | sort -rh | head -10"

echo ""
echo "[5d] Count files in a directory known for many small files (mail spool, cache):"
run_cmd "find /var/cache -type f 2>/dev/null | wc -l"

echo ""

# ── CLEANUP ───────────────────────────────────────────────────────────────────
echo "── Cleanup Check ──"
echo "  Confirm no leftover loop devices: losetup -a"
echo "  Confirm /etc/fstab has no stray test entries: grep week02 /etc/fstab"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 02 Lab Complete"
echo ""
echo "  Practiced:"
echo "  ✓ Hardware inspection (lscpu, lsmem, lspci, lsusb, lshw, dmidecode, dmesg)"
echo "  ✓ Module load/unload cycle (modprobe, rmmod, depmod, modinfo)"
echo "  ✓ Real LVM stack mapping on dell-ubuntu (pvdisplay/vgdisplay/lvdisplay)"
echo "  ✓ Full filesystem lifecycle on a loop device (mkfs, blkid, fstab, mount -a)"
echo "  ✓ Disk space vs. inode usage distinction (df -h vs. df -i)"
echo ""
echo "  Objectives covered: 1.2, 1.3"
echo "════════════════════════════════════════════════════════"
