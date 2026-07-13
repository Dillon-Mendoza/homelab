# Week 03 — Reference Notes
# Objectives: 1.4, 1.6, 1.7 | Calendar: Jul 13–19

---

## Exam Objective Mapping

**1.4 — Given a scenario, manage network services and configurations on a Linux server**
- Config files: `/etc/hosts`, `/etc/resolv.conf`, `/etc/nsswitch.conf`
- NetworkManager: `nmcli`, `nmconnect`
- Netplan: `netplan apply`, `netplan status`, `netplan try`, `/etc/netplan`
- Tools: `ip addr/link/route`, `ss`, `nmap`, `ping/ping6`, `dig`, `nslookup`, `traceroute`, `tracepath`, `curl`, `nc`, `tcpdump`, `mtr`, `iperf3`, `ethtool`, `arp`, `hostname`

**1.6 — Given a scenario, perform backup and restore operations for a Linux server**
- Archiving: `tar`, `cpio`
- Compression: `gzip`, `bzip2`, `xz`, `7-Zip`, `unzip`
- Transfer/clone: `rsync`, `dd`, `ddrescue`
- Compressed viewing: `zcat`, `zgrep`, `zless`

**1.7 — Summarize virtualization on Linux systems**
- Hypervisors: QEMU, KVM; VM tools: `virsh`, `virt-manager`, `libvirt`
- VM operations: snapshots, cloning, migrations, resource allocation
- Disk image ops: convert, resize, image properties (`qemu-img`)
- Network types: bridged, NAT, host-only/isolated, routed, open
- Bare metal vs. VM; VirtIO paravirtualized drivers; nested virtualization

---

## Key Man Pages

`man 5 nsswitch.conf` — the `hosts:` line section. This page explains *why* `/etc/hosts` beats DNS — the order is policy set here, not a property of the files. Section 5 specifically (the file format, not a command).

`man ss` — the FILTER section at the bottom. Beyond `-tulpn`, `ss` can filter by state and port (`ss -t state established '( dport = :22 )'`) — reading this once explains output you'll see in troubleshooting scenarios.

`man rsync` — the USAGE section's paragraph on trailing slashes. It states the rule in two sentences; read the primary source once and the trap loses its power. Also skim `--delete` and its variants.

`man tar` — the "Option styles" section explains why `-f` behaves the way it does (it takes an argument, so it must end a bundled group). Understanding the mechanism beats memorizing the rule.

`man virsh` — huge page; read only the `destroy` and `undefine` entries this week. The wording there is the exact distinction the exam tests (hard stop vs. remove definition).

---

## Video Timestamps

**Theory Course (12hr — nGPK6YBbKpg):**
Search for the "Network Configuration" / "Networking Tools" sections for 1.4, then "Backup and Restore" for 1.6, and "Virtualization" for 1.7. These typically run in sequence in the Domain 1 block after storage. Three separate objectives this week — budget the video time accordingly or prioritize 1.4 (largest tool surface).

**Labs Course (7hr — JXIaR23OdB8):**
Look for the networking-tools lab segment (`ip`, `ss`, `dig` demos) before Session B Task 1–3, and the `tar`/`rsync` walkthrough before Tasks 4–5. If there's a KVM/virt-manager segment, it maps to Task 6 — but your `dell-ubuntu` stack is a better lab than their VM.

---

## Things That Trip People Up

**1. rsync trailing slash — contents vs. the directory itself**
`rsync -av src/ dest/` puts src's *contents* in dest. `rsync -av src dest/` creates `dest/src/`. One character changes what your backup restores to. Lab Task 5 makes you produce both outcomes side by side — that's the memory you'll reach for on exam day.

**2. `virsh destroy` does not delete anything**
It's a hard power-off — the virtual power cable pulled. The VM definition and disk are untouched; `virsh undefine` is what removes the VM. Scenario questions exploit the name: "an admin ran `virsh destroy` — what happened to the VM's data?" Answer: nothing, it's just off.

**3. `tar -f` must end the bundled flag group**
`tar -cfzv backup.tar.gz /etc` fails: `-f` consumes `zv` as the filename. Always `-czvf`. Any "why did this tar command fail" question — check flag order before anything else.

**4. `/etc/resolv.conf` edits that vanish**
On every node in this fleet, that file is managed — systemd-resolved and/or Tailscale rewrite it. Hand-edits disappearing is not a bug; it's ownership. The exam frames this as "a change didn't persist" — the answer involves the managing service (or `nmcli`/netplan as the correct place to set DNS), never "edit the file harder."

**5. `traceroute` vs `tracepath` — root and MTU**
`tracepath` needs no privileges and reports path MTU; `traceroute` has more options but its ICMP mode needs root. If a question stresses "unprivileged user" or "MTU discovery," it wants `tracepath`. (MTU mismatch is a named 5.3 symptom later — a Tailscale interface at MTU 1280 vs. Ethernet's 1500 is the live example.)

**6. Internal snapshots require qcow2**
`virsh snapshot-create-as` against a VM backed by a raw image fails — raw has nowhere to store snapshot state. If a scenario mixes "raw disk image" and "snapshot," that's the conflict being tested. Also: snapshot before risky change, but snapshots are not backups — they live on the same disk as the VM.

**7. `dd` direction — no confirmation, no undo**
`if=` is the source, `of=` is what gets overwritten. Reversing them while "backing up" a disk destroys the disk you meant to save. Related: plain `dd` stalls on failing disks; `ddrescue` (easy sectors first, resumable via map file) is the correct answer for "recover data from a dying drive."

---

## Connect to the Homelab

This is the week the homelab stops being background and becomes the syllabus. Objective 1.4 is describing the network you just rebuilt: the fleet's DNS path (`tp-mudd` → MagicDNS `100.100.100.100` → Pi-hole on `pi-zero`) is a three-hop resolution chain you configured by hand within the last two weeks — Lab Task 2 just makes you observe it with the exam's tools (`resolvectl`, `dig @server`, `tcpdump` on `tailscale0`). The tiered ACL model shows up in tool output too: `nc -zv` and `nmap` results from `tp-mudd` (t0, sees everything) would differ from the same commands run on `muddpi` (t2) — the zero-trust policy is testable with 1.4's toolbox. For 1.7, `dell-ubuntu` running the `dell-fedora` VM under KVM/libvirt is a complete production example of the entire objective — hypervisor stack, resource allocation, qcow2 imaging, and NAT networking with Tailscale-inside-the-guest as the reachability answer. The gap is 1.6: nothing in the fleet does scheduled backups yet. Task 5's rsync-over-Tailscale run to `dell-ubuntu` is the seed of a real backup job — turning it into a cron entry (Week 5) or systemd timer would close the only objective this week that the homelab doesn't already demonstrate.
