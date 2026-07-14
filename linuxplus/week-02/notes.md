# Week 02 — Reference Notes
# Objectives: 1.2, 1.3 | Calendar: Jul 6–12

---

## Exam Objective Mapping

**1.2 — Summarize Linux device management concepts and tools**
- Kernel modules: `depmod`, `insmod`, `lsmod`, `modinfo`, `modprobe`, `rmmod`
- Device inspection: `dmesg`, `dmidecode`, `lscpu`, `lsmem`, `lspci`, `lsusb`, `lshw`
- Sensors/IPMI: `ipmitool`, `lm_sensors`, `nvtop`
- initrd management: `dracut`, `mkinitrd`

**1.3 — Given a scenario, manage storage in a Linux system**
- LVM: `pvcreate/pvdisplay/pvremove/pvresize`, `vgcreate/vgextend/vgreduce/vgdisplay`, `lvcreate/lvextend/lvresize/lvremove/lvdisplay`, `lvs/vgs/pvs`
- Partitioning: `fdisk`, `gdisk`, `parted`, `lsblk`, `blkid`, `growpart`
- Filesystems: ext4, xfs, btrfs, tmpfs — `mkfs`, `fsck`, `resize2fs`, `xfs_growfs`, `xfs_repair`
- RAID: `mdadm`, `/proc/mdstat`
- Mounting: `/etc/fstab`, `/etc/mtab`, `/proc/mounts`, `autofs`, `mount`, `umount`
- Mount options: `noatime`, `nodev`, `nodiratime`, `noexec`, `nofail`, `nosuid`, `remount`, `ro`, `rw`
- Network mounts: NFS, SMB/Samba
- Disk utilities: `df`, `du`, `fio`
- Inodes — exhaustion as a distinct failure mode from space exhaustion

---

## Key Man Pages

`man lsblk` — check the `-f` flag specifically (filesystem type + UUID in the tree view). This is the fastest orientation command for unfamiliar storage and worth knowing cold.

`man fstab` (or `man 5 fstab`) — read the full field description. The exam tests all six fields; this page is the canonical source, more precise than most tutorials.

`man mount` — the `FILESYSTEM-INDEPENDENT MOUNT OPTIONS` section covers every option in this week's table (`noatime`, `nosuid`, `nodev`, etc.) in the exact wording the exam draws from.

`man lvm` — overview page linking to `lvcreate`, `lvextend`, `pvcreate` individually. Start here if a specific LVM command's flags aren't sticking.

`man xfs_growfs` — short page, but confirms directly that it takes a mountpoint, not a device — the detail most likely to be tested as a trick.

---

## Video Timestamps

**Theory Course (12hr — nGPK6YBbKpg):**
Search for "Device Management" and "Storage Management" sections — these map directly to 1.2 and 1.3 and typically run back-to-back early in the course, right after the fundamentals section covered in Week 1.

**Labs Course (7hr — JXIaR23OdB8):**
Look for the LVM walkthrough segment — it demonstrates the full `pvcreate → vgcreate → lvcreate → mkfs → mount` chain live, which is the same sequence you build yourself in Task 3 of this week's lab script. Watch alongside or right before Session B.

---

## Things That Trip People Up

**1. Growing an LV does not grow the filesystem**
`lvextend` only changes the logical volume's size. The filesystem inside still thinks it's the old size until you run `resize2fs` (ext4) or `xfs_growfs` (xfs) against it. Two separate operations, two separate exam question angles.

**2. `resize2fs` takes a device, `xfs_growfs` takes a mountpoint**
This asymmetry is not intuitive and is exactly the kind of thing XK0-006 likes to test with a "why did this command fail" scenario.

**3. xfs cannot shrink, period**
Not "harder to shrink" — actually impossible without destroying and recreating the filesystem. If a scenario needs a volume to get smaller, ext4 is the only correct answer among the filesystems in scope this week, and even then it must be unmounted first.

**4. `nofail` prevents a boot hang, not a mount failure**
Without `nofail`, a missing device listed in `/etc/fstab` can drop the entire boot into an emergency shell waiting for that mount. `nofail` doesn't make the mount succeed — it just lets boot continue without it.

**5. `df -h` can lie about "space available" when inodes are the real problem**
A filesystem with thousands of tiny files (mail spool, session cache, container layers) can hit "No space left on device" while `df -h` shows 40% free. Only `df -i` reveals inode exhaustion. This distinction shows up as a troubleshooting scenario, not just a definition question.

**6. `insmod` vs `modprobe` — dependency resolution is the whole difference**
`insmod` loads exactly the file you point it at and nothing else. If that module depends on another that isn't already loaded, it fails. `modprobe` reads the dependency map built by `depmod` and loads the whole chain. Any scenario mentioning "a module failed to load due to missing dependencies" points to the `insmod` failure mode, and the fix is `modprobe`.

---

## Connect to the Homelab

Everything this week happens on `tp-mudd`, and the machine itself is the best reference point: Fedora Workstation put `/` on **btrfs** (confirm with `lsblk -f` in lab Task 4), which makes this laptop a live counterexample to the common "Fedora = xfs" shortcut — xfs is the RHEL *server* default. The LVM stack you build in Task 3 from loop devices is functionally identical to what a production server like `dell-ubuntu` runs; the difference is that here you own every layer because you created it, grew it, and tore it down in order — a stronger foundation than reading someone else's `vgdisplay` output. Kernel module management is already in daily use on this laptop without you noticing: the `tun` module underneath `tailscale0`, plus the ThinkPad-specific modules (`thinkpad_acpi`) that surface battery and thermal data — `lsmod` on this machine is a working tour of Objective 1.2. The other fleet devices remain useful as *mental* examples (ext4 on the Ubuntu nodes, a VM consuming host storage on the Dell), but nothing this week requires touching them.
