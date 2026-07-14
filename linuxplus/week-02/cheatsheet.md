# Week 02 — Hardware Management + Storage
# Domain: 1.0 System Management (23%) | Objectives: 1.2, 1.3
# Calendar: Jul 6–12 | Session A — 45 min read

---

## Objective 1.2 — Device Management

### Kernel Modules

The kernel is modular — drivers load and unload without a reboot. Five commands, know the layer each operates at.

| Command | What it does | Layer |
|---|---|---|
| `lsmod` | Lists currently loaded modules (reads `/proc/modules`) | Inspection |
| `modinfo <module>` | Shows metadata: version, dependencies, params, license | Inspection |
| `modprobe <module>` | Loads a module AND its dependencies | High-level load |
| `insmod <path.ko>` | Loads a single module file, no dependency resolution | Low-level load |
| `rmmod <module>` | Unloads a module (fails if in use) | Unload |
| `depmod` | Rebuilds the module dependency map (`modules.dep`) | Maintenance |

**Why `modprobe` over `insmod`:** `insmod` needs the exact `.ko` path and will fail silently on missing dependencies. `modprobe` reads `/lib/modules/$(uname -r)/modules.dep` (built by `depmod`) and pulls in everything required. In practice you almost never reach for `insmod` outside of building or testing a module by hand.

On `tp-mudd` (Fedora 44), check what's backing your NIC and Tailscale interface:
```
lsmod | grep -E 'tailscale|wireguard'
modinfo wireguard
```

Remove a module cleanly, confirm it's gone, reload it:
```
sudo rmmod <module>
lsmod | grep <module>
sudo modprobe <module>
```

---

### Device Inspection Tools

These answer "what hardware does this box actually have" — a constant sysadmin question and a guaranteed exam category.

| Command | Shows | Homelab use |
|---|---|---|
| `lscpu` | CPU architecture, cores, threads, flags, virtualization support | Confirm `tp-mudd`'s AMD CPU exposes `svm` (AMD-V) before enabling KVM |
| `lsmem` | Installed RAM, memory blocks, online/offline ranges | Check total vs. usable RAM on `tp-mudd` |
| `lspci` | PCI bus devices — NICs, GPUs, storage controllers | Identify `tp-mudd`'s NVMe controller (`lspci \| grep -i nvme`) and wifi NIC |
| `lsusb` | USB bus devices | Confirm a USB drive enumerated before you try to mount it |
| `lshw` | Full hardware tree — CPU, memory, storage, network in one report | `sudo lshw -short` for a fast top-level summary |
| `dmesg` | Kernel ring buffer — boot-time and runtime hardware events | `dmesg -T \| grep -i usb` right after plugging in a drive |
| `dmidecode` | Reads SMBIOS/DMI tables — motherboard, BIOS version, RAM slots | `sudo dmidecode -t memory` to see populated vs. empty DIMM slots |

**Exam framing:** these are read-only inspection tools. None of them change system state — they report what the kernel already knows. If a question describes "verifying installed RAM matches what the vendor spec sheet says," that's `lsmem` or `dmidecode -t memory`, not `free -h` (which shows usage, not installed slots).

---

### Sensors and IPMI

- `lm_sensors` — package providing `sensors` command. Run `sensors-detect` once to probe hardware, then `sensors` reports CPU temp, fan speed, voltages. On `tp-mudd` it reads the ThinkPad's thermal sensors directly (`thinkpad_isa` adapter) — run it under load and watch the CPU temp move.
- `ipmitool` — talks to a server's dedicated management controller (BMC), out-of-band from the OS. `ipmitool sensor list` reads temps/fans/power even if the OS is unresponsive. Only relevant to server-class hardware with a BMC — not `tp-mudd`.
- `nvtop` — `htop`-style live view for GPU utilization. Only useful if a GPU is present; not applicable to any current homelab node but appears in the objective list.

**Exam trap:** IPMI is out-of-band — it works even if the OS has crashed or the machine hasn't booted an OS at all, because it talks to the BMC, not to Linux. `lm_sensors` is in-band — it requires a running, responsive kernel.

---

### initrd Management

- `dracut` — builds the initramfs on Fedora/RHEL. `dracut --force` rebuilds for the current kernel; add `--kver <version>` to target a specific one.
- `mkinitrd` — older/legacy equivalent, largely superseded by `dracut` on modern RPM-based systems and by `mkinitramfs`/`update-initramfs` on Debian/Ubuntu (`dell-ubuntu`, `muddpi`, `pi-zero`).

You rebuild initramfs after: installing a new kernel module that must be available at boot (e.g., a storage driver), or changing LVM/LUKS configuration on the root volume. If `/boot` fills up (from Week 1's FHS warning) and dracut can't write the new image, boot will fail on the next kernel update — this is the real-world failure mode behind the objective.

---

## Objective 1.3 — Storage Management

### The LVM Stack

Three layers, bottom to top. Know the create/display/remove command for each.

```
Physical Disk(s) → Physical Volume (PV) → Volume Group (VG) → Logical Volume (LV) → Filesystem
```

| Layer | Create | Display | Extend/Reduce | Remove |
|---|---|---|---|---|
| Physical Volume | `pvcreate /dev/sdb1` | `pvdisplay`, `pvs` | `pvresize /dev/sdb1` | `pvremove /dev/sdb1` |
| Volume Group | `vgcreate vg_data /dev/sdb1` | `vgdisplay`, `vgs` | `vgextend vg_data /dev/sdc1` / `vgreduce` | `vgremove vg_data` |
| Logical Volume | `lvcreate -L 20G -n lv_data vg_data` | `lvdisplay`, `lvs` | `lvextend -L +10G /dev/vg_data/lv_data` | `lvremove /dev/vg_data/lv_data` |

`pvs`, `vgs`, `lvs` give a compact one-line-per-object summary — use these for quick checks. `pvdisplay`/`vgdisplay`/`lvdisplay` give the full verbose report — use these when you need every attribute.

**Size syntax matters:**
- `lvcreate -L 10G -n lv_data vg_data` — absolute size
- `lvcreate -l 100%FREE -n lv_data vg_data` — consume all remaining space in the VG (lowercase `-l` = extents/percentage, uppercase `-L` = absolute size)

**The two-step resize (this is the #1 LVM exam trap):**
```
lvextend -L +10G /dev/vg_data/lv_data      # grows the logical volume
resize2fs /dev/vg_data/lv_data             # ext4 — grows the filesystem to fill it
xfs_growfs /mount/point                    # xfs — same idea, but takes a MOUNTPOINT not a device
```
Growing the LV does not grow the filesystem inside it. Forgetting the second command is the most common real-world LVM mistake and a direct exam question. Also note `xfs_growfs` takes the **mountpoint**, while `resize2fs` takes the **device path** — that inconsistency is tested.

In Session B you build this entire stack yourself on `tp-mudd` from loop devices — `pvcreate → vgcreate → lvcreate → mkfs → mount → lvextend → teardown`. Every command in the table above gets run for real against disks you create, so nothing here stays hypothetical. Zero risk to the laptop's real disk: the "disks" are files in `/tmp`.

---

### Partitioning Tools

| Tool | Style | Use case |
|---|---|---|
| `fdisk` | Interactive, MBR-native (also handles GPT on modern versions) | Quick partition edits, most common |
| `gdisk` | Interactive, GPT-native | GPT-specific edge cases, converting MBR→GPT |
| `parted` | Interactive or scriptable | Scripted partitioning, resizing partitions in place |
| `lsblk` | Read-only tree view of block devices | Fastest way to see the whole disk/partition layout |
| `blkid` | Read-only — shows UUID and filesystem type per block device | Getting the UUID to put in `/etc/fstab` |
| `growpart` | Grows a partition to fill available space | Cloud images / VMs after a disk resize (relevant to `mudd-cloud`, `dell-fedora` VM) |

`lsblk -f` combines the tree view with filesystem type and UUID in one call — usually the first command to run when orienting on unfamiliar storage.

---

### Filesystem Types

| FS | Type | Strengths | Key limitation |
|---|---|---|---|
| ext4 | Journaling | Default on most distros, mature, well understood | Can shrink (offline only) or grow |
| xfs | Journaling | High performance on large files, default on RHEL/Fedora | **Cannot shrink — ever.** Grow only. |
| btrfs | Copy-on-write | Snapshots, checksums, built-in RAID-like profiles | More complex, less universal tooling |
| tmpfs | RAM-backed | Fast, volatile — gone on unmount/reboot | Not persistent — don't put data you need here |

**Format/check/repair per filesystem:**
```
mkfs.ext4 /dev/vg_data/lv_data      fsck.ext4 /dev/...      resize2fs /dev/...
mkfs.xfs  /dev/vg_data/lv_data      xfs_repair /dev/...     xfs_growfs /mountpoint
```

**Exam trap:** xfs is the **RHEL server** default. Fedora *Workstation* — including `tp-mudd` — defaults to **btrfs** (verify yours: `findmnt -no FSTYPE /`), while Ubuntu installs default to ext4. Don't conflate "Fedora" with "xfs by default" — that's RHEL/Rocky/Alma. If a scenario says "the volume needs to shrink," xfs is immediately disqualified — the answer requires ext4 (offline, unmounted, with `resize2fs` to a smaller size after `e2fsck -f`) or btrfs (which can shrink online).

---

### RAID Levels (Conceptual)

| Level | Layout | Fault tolerance | Usable capacity |
|---|---|---|---|
| RAID 0 | Striped, no redundancy | None — one disk failure loses everything | 100% (n disks) |
| RAID 1 | Mirrored | Survives 1 disk failure | 50% (n=2) |
| RAID 5 | Striped + 1 parity | Survives 1 disk failure | (n-1)/n |
| RAID 10 | Mirrored pairs, then striped | Survives multiple failures (1 per mirror pair) | 50% |

`mdadm` builds and manages software RAID. `/proc/mdstat` shows live array status (`[UU]` = both disks up, `[U_]` = one disk missing/degraded — read this notation, it appears in performance-based questions).

---

### Mounting and `/etc/fstab`

Six fields, in order — this is the exam's favorite storage table to test verbatim:

```
<device>  <mountpoint>  <fstype>  <options>  <dump>  <pass>
```

Example entry, referencing a UUID (preferred over `/dev/sdX` since device letters can shift):
```
UUID=1a2b3c4d-...  /mnt/data  ext4  defaults,nofail  0  2
```

- **dump** — legacy backup flag, almost always `0` (unused today).
- **pass** — fsck order at boot. `0` = don't check. `1` = root filesystem (checked first). `2` = everything else, checked after root.
- **`nofail`** — boot continues even if this device isn't present. Without it, a missing external/network drive can drop the whole system into emergency mode at boot. Always use `nofail` for anything not physically guaranteed to be there (USB drives, NFS mounts).

**Mount options:**

| Option | Effect |
|---|---|
| `ro` / `rw` | Read-only / read-write |
| `noexec` | Blocks execution of binaries from this mount — common on `/tmp`, `/var/tmp` |
| `nosuid` | Ignores SUID/SGID bits on this mount — security hardening for untrusted mounts |
| `nodev` | Ignores device files on this mount |
| `noatime` | Skips updating file access time on every read — performance win, common on SSDs |
| `nodiratime` | Same idea, directories only |
| `remount` | Change options on an already-mounted filesystem without unmounting: `mount -o remount,ro /` |

`autofs` mounts network shares on-demand (first access) and unmounts after idle — avoids a dead NFS server hanging the whole boot the way a static `/etc/fstab` entry without `nofail` would.

`/etc/mtab` and `/proc/mounts` both show currently mounted filesystems — `/proc/mounts` is the kernel's live truth; `/etc/mtab` is often just a symlink to it on modern systems.

---

### Network Mounts

- **NFS** — native Unix network filesystem. Server exports via `/etc/exports`, client mounts with `mount -t nfs server:/export /local/mount`.
- **SMB/Samba** — Windows-interoperable share protocol. Client mounts with `mount -t cifs //server/share /local/mount -o username=...`.

---

### Disk Utilities and Inodes

- `df -h` — filesystem-level free space, human-readable.
- `du -sh /path/*` — directory-level space consumption, summarized per entry.
- `fio` — flexible I/O tester, benchmarks real read/write throughput and IOPS.

**Inode exhaustion** — a filesystem can report free space via `df -h` while `df -i` shows 0% inodes free, and file creation still fails with "No space left on device." Every file needs an inode regardless of size; a directory with millions of tiny files (e.g., mail spool, cache) can exhaust inodes long before it exhausts blocks. `df -i` is the tool that catches this — `df -h` alone will not.

---

## Quick Recall

`lsmod` — list loaded kernel modules
`modprobe` — load a module and resolve its dependencies
`insmod` — load a module file directly, no dependency resolution
`depmod` — rebuild the module dependency map
`lscpu` — CPU architecture and virtualization flags
`dmidecode -t memory` — installed RAM slots from SMBIOS, not usage
`ipmitool` — out-of-band hardware management via BMC, works without a running OS
`dracut --force` — rebuild initramfs for current kernel (Fedora/RHEL)
PV → VG → LV — the LVM stack, bottom to top
`lvextend` then `resize2fs`/`xfs_growfs` — growing an LV never auto-grows the filesystem
`xfs_growfs` takes a mountpoint; `resize2fs` takes a device path
xfs cannot shrink — ext4 can (offline only)
`/etc/fstab` fields — device, mountpoint, fstype, options, dump, pass
`nofail` — boot continues even if this mount is missing
`df -i` — check inode exhaustion; `df -h` alone won't show it
