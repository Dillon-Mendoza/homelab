# Cloud Concepts — Mapped to What You Already Run

Cloud is other people's datacenters plus an API. Every concept below exists
in your homelab in miniature; the mapping is the fastest way to own the
vocabulary.

---

## Service Models — Who Manages What

| Model | You manage | Provider manages | Your example |
|---|---|---|---|
| **IaaS** | OS upward: packages, config, security | Hardware, hypervisor, network fabric | mudd-cloud — you patch that Ubuntu, Oracle owns the box |
| **PaaS** | Code + data | Runtime, OS, scaling | (none — you self-host instead; Gitea *as a service* would be PaaS-ish SaaS) |
| **SaaS** | Your usage/config | Everything | Tailscale's coordination plane — you run nodes, they run the control plane |
| **FaaS** | Functions | Everything incl. runtime lifecycle | an n8n workflow is the self-hosted cousin: event in, logic runs, no server *you think about* |

**Shared responsibility** — the exam-and-interview phrase: the provider
secures the cloud (physical, hypervisor); you secure what's IN it (OS,
firewall, keys, data). mudd-cloud's UFW and sshd config were always your
job; no cloud tier changes that.

## Geography and Failure Domains

- **Region** — a metro area of datacenters (your OCI region).
- **Availability Domain (AD)** / AWS **AZ** — isolated datacenter(s) within
  a region: independent power/cooling/network. Design rule: survive an AD
  loss by running in two.
- **Fault Domain** — OCI's sub-AD grouping: different racks within one AD.
- Homelab analog: dell-ubuntu vs mudd-cloud is a two-"region" design —
  the ACL outage was effectively a region-level network failure, and your
  muddpi backup exit node is a failover plan across failure domains.

## Compute

- **Instance = a VM** — same KVM/QEMU idea as dell-fedora, industrialized.
  **Shapes** (OCI) / instance types (AWS) = CPU/RAM presets; OCI's flexible
  shapes let you dial OCPU/RAM independently.
- **Image** = the template (Ubuntu 22.04 image → mudd-cloud); custom images
  = your qemu-img/snapshot knowledge with a catalog.
- **cloud-init** — how mudd-cloud got your SSH key before first login
  (week-09 vocabulary, now with a live example): user-data YAML runs at
  first boot — users, keys, packages, scripts.
- **Metadata service** — `curl http://169.254.169.254/opc/v2/instance/`
  from inside an instance: identity, shape, user-data. Link-local address,
  answered by the platform, basis of machine identity (and a classic
  attack surface — why v2 requires an auth header).

## Storage — Three Kinds, Three Jobs

| Kind | Looks like | Homelab analog | Use |
|---|---|---|---|
| **Block** (Block Volume / EBS) | A disk: attach, `lsblk`, mkfs, mount | Your loop devices and LVM practice — identical workflow | Databases, filesystems |
| **Object** (Object Storage / S3) | HTTP API: PUT/GET blobs in buckets, no filesystem | Nothing local — genuinely new; closest is "a Git remote for arbitrary files" | Backups, artifacts, static sites |
| **File** (File Storage / EFS) | NFS mount, shared across instances | Linux+ 1.3's network mounts, managed | Shared config/home dirs |

Boot volumes are block storage — mudd-cloud's "disk" is a network-attached
block volume, which is why cloud VMs can resize/detach/snapshot disks in
ways your laptop can't.

## Networking — the VCN

- **VCN** (OCI) / **VPC** (AWS) = your own private network in their fabric:
  a CIDR block you choose, subdivided into **subnets** (subnetting drills
  cash in here — a /16 VCN split into /24 subnets is drill A10 verbatim).
- **Public vs private subnet**: public = routes to an **Internet Gateway**;
  private = egress only via **NAT Gateway** (their managed masquerade —
  your 3.2 SNAT knowledge, productized).
- **Security Lists / NSGs** (OCI) / Security Groups (AWS) = stateful
  firewall rules at the platform layer, OUTSIDE the instance. mudd-cloud is
  therefore double-firewalled: security list first, UFW second. A blocked
  port can be blocked in either — remember the layer order when debugging
  (this is 5.3's "misconfigured firewall" with an extra floor).
- **Route tables** decide subnet egress — `ip route` for the fabric.
- Default VCN CIDRs are RFC 1918 space; the same collision reasoning as the
  libvirt drill (subnetting set B4) applies when VPNs enter the picture.

## Identity — IAM

Users, **groups**, **policies** (statements granting groups verbs on
resource types in **compartments** — OCI's resource-organizing containers).
The load-bearing concepts:

- **Principle of least privilege** — your tiered ACL philosophy, applied to
  API calls instead of packets. Same instinct, new nouns.
- **Instance principals** (OCI) / instance roles (AWS): the INSTANCE itself
  gets an identity and calls APIs with **no stored credentials** — the
  answer to "how does a VM use the API without a key file on disk."
- API keys/tokens are the cloud's SSH keys: scope them, rotate them, never
  commit them (the week-09 audit's secrets scan already patrols this).

## Cost Model — the Part That Bites

- Compute billed per-time, storage per-GB-month, and — the classic surprise
  — **egress** (data OUT) billed per-GB while ingress is free. An exit node
  is *an egress machine*: OCI's free tier includes a large egress allowance
  (10TB/mo historically — verify current numbers), which is why mudd-cloud
  is free and the same design on AWS would cost real money.
- **Always Free** (OCI) vs 12-month trials (AWS) — know which resources are
  which before creating anything; oci-lab.md phase 0 inventories yours.
- The two defenses, always: a **budget alarm** (lab exercise) and the habit
  of destroying what you finish with.

---

## Self-Test (out loud, no notes)

1. Whose job is patching mudd-cloud's kernel — yours or Oracle's? Why?
2. A service on a new instance is unreachable on :8080; UFW says allowed.
   What's the other floor to check, and in which order do packets hit them?
3. Block vs object storage — which for a Postgres data dir, which for
   nightly homelab backups, and why?
4. What is 169.254.169.254, and why is it link-local?
5. Why is mudd-cloud free on OCI but the same exit-node design expensive on
   AWS?
6. An instance needs to write to object storage every hour. Where do its
   credentials live? (Best answer contains "no stored credentials.")
