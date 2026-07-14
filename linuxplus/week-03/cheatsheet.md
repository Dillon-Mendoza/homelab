# Week 03 — Networking + Backup + Virtualization
# Domain: 1.0 System Management (23%) | Objectives: 1.4, 1.6, 1.7
# Calendar: Jul 13–19 | Session A — 45 min read

---

## Objective 1.4 — Network Services and Configuration

### The Three Config Files

Name resolution on Linux is a pipeline, and these three files define it. The exam tests them as a set.

| File | Role |
|---|---|
| `/etc/nsswitch.conf` | The **order** of resolution sources. The `hosts:` line (typically `files dns`) says: check `/etc/hosts` first, then DNS. |
| `/etc/hosts` | Static name→IP mappings. Wins over DNS because `nsswitch.conf` says so — not because of anything magic about the file itself. |
| `/etc/resolv.conf` | Which DNS server(s) to query, and in what search domain. `nameserver`, `search`, `options` directives. |

**The modern complication (and a live fact on this fleet):** on Fedora and Ubuntu, `/etc/resolv.conf` is usually a symlink managed by `systemd-resolved` — the real state lives in `resolvectl status`. Tailscale MagicDNS inserts `100.100.100.100` as the nameserver and forwards to whatever the tailnet DNS config says — which on this network is Pi-hole on `pi-zero`. If a scenario says "user edited `/etc/resolv.conf` and the change disappeared," the answer is: a manager (systemd-resolved, NetworkManager, or a VPN client) owns that file and rewrote it.

Check the real resolution path on `tp-mudd`:
```
ls -l /etc/resolv.conf          # symlink? to what?
resolvectl status               # per-interface DNS servers
grep hosts /etc/nsswitch.conf   # resolution order
```

---

### NetworkManager vs. Netplan

Two tools, two distro families — the exam expects you to know which belongs where.

**NetworkManager** (`nmcli`) — Fedora, RHEL, and default on most desktops. Also present on Ubuntu desktop.
```
nmcli device status                    # every interface and its state
nmcli connection show                  # saved connection profiles
nmcli connection show "profile-name"   # full detail on one profile
nmcli connection up/down "profile"     # activate/deactivate
nmcli con mod "profile" ipv4.dns 100.100.100.100   # persistent change
```
`nmcli con mod` writes to the profile (persistent); the change applies on next activation. This mirrors the runtime-vs-permanent split you'll meet again with `firewall-cmd` in Week 6.

**Netplan** — Ubuntu server only (`dell-ubuntu`, `mudd-cloud`). YAML files in `/etc/netplan/`, rendered through either NetworkManager or `systemd-networkd` (the `renderer:` key).
```
netplan status         # current applied config
netplan try            # apply with automatic rollback in 120s if you don't confirm
netplan apply          # apply permanently
```
**`netplan try` is the exam's favorite:** it's the safety net for remote changes — if your new config kills your SSH session, you can't confirm, so it rolls back on its own. Changing network config on `dell-ubuntu` over Tailscale is exactly the scenario it exists for.

---

### The `ip` Suite

`ifconfig`, `route`, and `arp` are the deprecated net-tools generation. `ip` replaces all of them. Know the mapping.

| Old (deprecated) | Modern | Shows |
|---|---|---|
| `ifconfig` | `ip addr` (or `ip -br addr` for brief) | Interfaces + addresses |
| `ifconfig eth0 up` | `ip link set eth0 up` | Link state control |
| `route -n` | `ip route` | Routing table |
| `arp -a` | `ip neigh` | ARP/neighbor cache |

`ip route` reading practice: the `default via <gw> dev <iface>` line is the gateway. On `tp-mudd`, Tailscale routes for `100.64.0.0/10` appear alongside the LAN default route — two paths, and which one a packet takes is decided by longest-prefix match, not list order.

---

### Diagnostic Toolbox

The exam gives a symptom and asks which tool. Learn these as "what question does this tool answer":

Every example below runs from `tp-mudd` alone — targets are this laptop itself (`127.0.0.1`) or the public internet, never another homelab device.

| Tool | Question it answers | Key usage |
|---|---|---|
| `ping` / `ping6` | Is the host reachable at the IP layer? | `ping -c 4 1.1.1.1` |
| `traceroute` | What path do packets take? (UDP by default, needs root for ICMP mode) | `traceroute 1.1.1.1` |
| `tracepath` | Same, but no root needed, and it discovers path MTU | `tracepath 1.1.1.1` |
| `mtr` | Continuous traceroute + loss stats per hop — where is packet loss happening? | `mtr --report 1.1.1.1` |
| `dig` | What does DNS actually return? | `dig +short anthropic.com`, `dig anthropic.com @1.1.1.1` (isolate a resolver) |
| `nslookup` | Same question, older tool — still on the objective list | `nslookup anthropic.com` |
| `ss` | What is listening / connected on this box? | `ss -tulpn` |
| `nc` | Is that specific port actually open and accepting? | `nc -zv 127.0.0.1 8080` (against the lab's own test server) |
| `curl` | Does the HTTP layer work? | `curl -I http://127.0.0.1:8080` (headers only), `-v` (full transaction) |
| `tcpdump` | What is actually on the wire? | `sudo tcpdump -i lo -n port 8080` — watch your own curl happen |
| `nmap` | What ports are open across a host/subnet? | `nmap -p 22,8080 127.0.0.1` |
| `iperf3` | What throughput can this link actually sustain? | one terminal: `iperf3 -s`, another: `iperf3 -c 127.0.0.1` — you run both ends |
| `ethtool` | Link speed/duplex/negotiation on a physical NIC | `ethtool <nic>` — meaningless on virtual interfaces like `tailscale0` |
| `hostname` / `hostnamectl` | What is this box called? (`hostnamectl set-hostname` to change, persistent) | `hostnamectl` |

**`ss -tulpn` decoded** — this exact flag string is worth memorizing: **t**cp, **u**dp, **l**istening, **p**rocesses, **n**umeric (no name resolution). It's the modern `netstat -tulpn` and the first command in almost every "is the service actually up" investigation.

**`dig` vs `ping` for DNS problems:** if `ping google.com` fails but `ping 8.8.8.8` works, that's DNS, not connectivity. `dig` then tells you whether the configured resolver answers at all, and `dig @other-server` isolates whether the problem is your resolver or the record. This is the troubleshooting progression 5.3 will test in Week 10 — the tools land now.

---

## Objective 1.6 — Backup and Restore

### tar — The One Command You Must Know Cold

| Flag | Meaning |
|---|---|
| `-c` | Create archive |
| `-x` | Extract archive |
| `-t` | List contents (test) without extracting |
| `-v` | Verbose |
| `-f <file>` | Archive filename — **must come last in a bundled flag group**, because it consumes the next argument |
| `-z` | gzip (`.tar.gz` / `.tgz`) |
| `-j` | bzip2 (`.tar.bz2`) |
| `-J` | xz (`.tar.xz`) |
| `-C <dir>` | Change to directory before operating |

The canonical trio:
```
tar -czvf etc-backup.tar.gz /etc          # create
tar -tzvf etc-backup.tar.gz               # list/verify without extracting
tar -xzvf etc-backup.tar.gz -C /tmp/restore   # extract to a target dir
```

**Why `-f` last matters:** `tar -cfzv archive.tar.gz /etc` fails or misbehaves because `-f` grabs `zv` as the filename. Flag-order questions are cheap points if you know this one rule.

Compression letter → extension mnemonic: **z**→gzip, **j**→bzip2, **J**→xz. Ratio and speed run the same direction: gzip fastest/loosest, xz slowest/tightest, bzip2 between.

### cpio — The Other Archiver

`cpio` doesn't walk directories itself — it reads a **file list from stdin**. That's the whole exam distinction:
```
find /etc -name '*.conf' | cpio -ov > confs.cpio    # create (o = out)
cpio -iv < confs.cpio                                # extract (i = in)
```
Real-world hook: the initramfs that `dracut` builds (Week 2) is a cpio archive. This is why `cpio` still matters.

### Standalone Compression

`gzip file` **replaces** `file` with `file.gz` — it does not keep the original (use `-k` to keep). `gunzip` / `bunzip2` / `unxz` reverse. `zip`/`unzip` and `7z` are the cross-platform formats — the only ones Windows opens natively.

**Reading compressed files without extracting** — built for rotated logs:
```
zcat /var/log/dnf.log.1.gz           # cat a .gz
zgrep 'error' /var/log/*.gz          # grep across compressed logs
zless /var/log/messages-*.gz         # page through one
```
Any scenario about "searching last month's rotated logs" wants `zgrep`, not "extract them first."

### rsync — The Workhorse

```
rsync -av /home/tp-mudd/homelab/ /backup/homelab/        # local → local
rsync -avz /home/tp-mudd/homelab/ user@host:/backup/     # local → remote (same semantics, SSH transport)
```
- `-a` archive = `-rlptgoD`: recursive, links, permissions, times, group, owner, devices. The "preserve everything" flag.
- `-v` verbose, `-z` compress in transit (only worth it over a network — pointless locally)
- `-n` / `--dry-run` — show what would transfer. **Always dry-run before `--delete`.**
- `--delete` — remove files from destination that no longer exist in source (true mirror — and true deletion)
- The remote form runs over SSH by default. Every rule (trailing slash, `--delete`, deltas) is identical local or remote — the lab proves them locally where feedback is instant, and `rsync ... localhost:/tmp/...` demonstrates the remote syntax on this same laptop.

**The trailing slash rule (top exam trap for 1.6):**
- `rsync -av src/ dest/` → copies the **contents** of src into dest
- `rsync -av src dest/` → copies **src itself** into dest, producing `dest/src/`

rsync only transfers deltas — re-running against an unchanged tree transfers almost nothing. That's why it beats `scp` for repeated backups.

### dd and ddrescue

```
sudo dd if=/dev/sda of=/backup/disk.img bs=4M status=progress
```
- `if=` input, `of=` output, `bs=` block size, `count=` limit blocks. `status=progress` for live output; on an already-running dd, `kill -USR1 <pid>` makes it print progress.
- **Direction matters absolutely.** Swapping `if=` and `of=` destroys the source. There is no confirmation prompt. Triple-read every dd line before Enter — this is the command's entire reputation.
- `ddrescue` is for **failing** disks: it copies the easy sectors first, retries bad ones later, and keeps a map file so an interrupted rescue resumes instead of restarting. `dd` gives up (or hangs) on read errors; `ddrescue` is built for them.

---

## Objective 1.7 — Virtualization

### The Stack, Bottom to Top

```
Hardware (AMD-V/VT-x) → KVM (kernel module) → QEMU (device emulation) → libvirt (API/daemon) → virsh / virt-manager
```

- **KVM** — `kvm_amd` or `kvm_intel` kernel module. Turns the kernel into a type-1-style hypervisor. Verify support: `lscpu | grep -i virtualization` (you confirmed `svm` on `tp-mudd` in Week 2).
- **QEMU** — emulates the machine (disks, NICs, BIOS). With KVM it runs guest CPU instructions natively; without KVM it's pure (slow) emulation.
- **libvirt** — the management API and daemon (`libvirtd`) that everything talks to.
- **virsh** — libvirt's CLI. **virt-manager** — the GUI over the same API. Same operations, different front-end.

This exact layering — which piece is the kernel module, which is the emulator, which is the API — is a guaranteed question.

### virsh Essentials

`tp-mudd` has AMD-V — this laptop is a fully capable KVM host. The lab's stretch goal builds a throwaway VM here (`lab-vm`) so every command below can be run against something you own and can delete:

```
virsh list --all                  # all VMs, running or not
virsh dominfo lab-vm              # CPU/RAM allocation, state, autostart
virsh domblklist lab-vm           # disk image paths backing the VM
virsh start / shutdown <vm>       # shutdown = graceful ACPI signal
virsh destroy <vm>                # ⚠ hard power-off — NOT deletion. Names lie.
virsh undefine <vm>               # this is what actually removes the VM definition
virsh autostart <vm>              # start VM when host boots
virsh edit <vm>                   # edit the domain XML (uses $EDITOR)
```

**Snapshots:**
```
virsh snapshot-create-as lab-vm pre-change "before risky edit"
virsh snapshot-list lab-vm
virsh snapshot-revert lab-vm pre-change
```
Internal snapshots require **qcow2** disk images — raw images can't hold them. Migration comes in two flavors: **live** (VM keeps running, memory streamed to the new host) vs. **offline** (shut down, move, start).

### Disk Images — qemu-img

```
qemu-img create -f qcow2 practice.qcow2 5G                # create — costs ~200KB on disk
qemu-img info practice.qcow2                              # format, virtual vs actual size
qemu-img convert -f qcow2 -O raw practice.qcow2 out.raw   # convert formats
qemu-img resize practice.qcow2 +2G                        # grow (then grow partition+fs INSIDE the guest — Week 2's two-step lesson, now three steps)
```
**qcow2 vs raw:** qcow2 = thin-provisioned (grows as used), supports internal snapshots, slight overhead. raw = full size up front, fastest, no snapshot support. `qemu-img info` showing `virtual size: 50G, disk size: 12G` is thin provisioning in action.

### VM Network Types

| Type | Guest gets | Reachable from LAN? |
|---|---|---|
| **NAT** (libvirt default, `virbr0`) | Private IP, outbound via host | No — host masquerades |
| **Bridged** | IP on the real LAN, peer of the host | Yes |
| **Host-only / isolated** | Private net shared with host only | No, and no internet |
| **Routed** | Own subnet, host routes (no NAT) | Yes, if LAN has a route back |
| **Open** | Like routed, no firewall rules added | Yes |

Conceptual anchor from your own fleet: the `dell-fedora` VM sits on NAT yet is reachable — because Tailscale runs *inside* the guest and NAT permits outbound connections. You don't need to touch that machine to use the fact; being able to say *why* NAT plus an outbound mesh connection works is exactly the depth the exam wants. A `lab-vm` built here lands on the same libvirt NAT default (`virbr0`) — check it with `virsh dumpxml lab-vm | grep -A3 'interface type'`.

### VirtIO and Nested Virtualization

- **VirtIO** — paravirtualized drivers: the guest *knows* it's virtualized and uses streamlined virtual devices instead of QEMU emulating real hardware (e1000 NIC, IDE disk). Dramatically faster I/O. "Paravirtualized" on the exam = VirtIO.
- **Nested virtualization** — running a hypervisor inside a VM. Requires the host module loaded with `nested=1`; check: `cat /sys/module/kvm_amd/parameters/nested` (`1` or `Y` = enabled).

---

## Quick Recall

`/etc/nsswitch.conf` — decides resolution ORDER; `hosts: files dns` means /etc/hosts wins
`resolv.conf` rewritten mysteriously — systemd-resolved/NetworkManager/VPN owns it
`netplan try` — applies with automatic 120s rollback; the remote-change safety net
`ss -tulpn` — tcp, udp, listening, processes, numeric
`tracepath` — traceroute without root, discovers path MTU
`mtr` — continuous per-hop loss stats; finds WHERE loss happens
`dig @server name` — query a specific DNS server directly, isolates resolver vs record
`tar -f` must be last in a bundled flag group
`-z` gzip, `-j` bzip2, `-J` xz — speed and ratio both increase left to right
`cpio` reads its file list from stdin — `find | cpio -o`
`rsync src/ dest/` copies contents; `rsync src dest/` copies the directory itself
`ddrescue` — for failing disks: easy sectors first, map file, resumable
`virsh destroy` — hard power-off, NOT deletion; `undefine` deletes
Internal VM snapshots need qcow2 — raw images can't hold them
VirtIO — paravirtualized drivers; guest-aware, faster than emulated hardware
