# OCI Free-Tier Lab — Hands-On Phases

Practice plan against the Oracle Cloud account that already runs mudd-cloud.
CLI-first: the console teaches clicking, the CLI teaches the resource model
— and phase 4 of the roadmap (OpenTofu) sits on the same model.

**The standing rule applies to every phase: additive only, mudd-cloud
untouched, everything created gets destroyed at phase end.** Free-tier
limits are real; verify current Always Free terms in the console before
phase 2 — numbers here reflect mid-2026 and drift.

---

## Phase 0 — Inventory What Exists (read-only, ~1 hour)

Console session, notebook open. Find and write down:

1. mudd-cloud's **compartment**, **shape**, **AD/fault domain**, and image.
2. Its **VCN**: CIDR block, subnets, which subnet mudd-cloud sits in,
   public or private, the route table's entries (find the Internet Gateway).
3. The **security list** rules actually protecting it — compare with its
   UFW rules. Which layer allows SSH? Both? (Draw the two floors.)
4. The **boot volume**: size, whether it's Always Free-tagged.
5. Billing → cost analysis: confirm the account has spent $0, and find
   where egress usage appears (the exit node's consumption is visible!).
6. **Create a budget alarm now**: $1 threshold, email notification. Two
   minutes of clicking; converts every future mistake from a bill into an
   email.

Deliverable: a paragraph in this file's margin — "mudd-cloud actually is:
…" — written from the platform's point of view for the first time.

## Phase 1 — CLI From tp-mudd (~1 hour)

```bash
sudo dnf install -y oci-cli          # or the pip installer in a venv
oci setup config                     # interactive: creates ~/.oci/config + API keypair
# upload the public key to your user in the console (it walks you through it)
oci iam region list --output table                    # first authenticated call
oci compute instance list --compartment-id <ocid> --output table
oci network vcn list --compartment-id <ocid> --output table
```

- **OCIDs** — every resource's globally-unique ID; the CLI runs on them.
  Save the compartment OCID into an env var in `~/.bashrc.d/oci` — you'll
  type it constantly.
- `--output table` for humans, default JSON for scripts — pipe through `jq`
  and it's week-08 skills against cloud state.
- Security note: `~/.oci/` now holds an API private key — 600 perms (the
  CLI sets it; verify anyway), and it never enters a repo. The week-09
  audit's pattern scan would catch it; don't give it the chance.

Deliverable: phase 0's inventory reproduced entirely from the CLI.

## Phase 2 — Second Instance: Create, Study, Destroy (~2 hours)

The core rep. Always Free allows multiple micro instances (2× AMD micro +
ARM allowance historically — **verify yours**, and check nothing conflicts
with mudd-cloud's own allocation before creating).

```bash
# reuse mudd-cloud's VCN/subnet for the lab instance — one less thing to build
oci compute instance launch \
  --compartment-id "$C" \
  --availability-domain "<AD from phase 0>" \
  --shape VM.Standard.E2.1.Micro \
  --image-id "<current Ubuntu image OCID>" \
  --subnet-id "<subnet OCID>" \
  --assign-public-ip true \
  --metadata '{"ssh_authorized_keys": "<your pubkey>"}' \
  --display-name lab-01
```

Then the study sequence:
1. Watch state: `oci compute instance get ... | jq '.data."lifecycle-state"'`
   (PROVISIONING → RUNNING).
2. SSH in (public IP from `oci compute instance list-vnics`). You're on a
   machine that didn't exist five minutes ago — inspect it with week-01
   eyes: `lsblk` (network block volume presented as a disk), `cloud-init
   status`, `sudo cat /var/log/cloud-init-output.log` (your key arriving).
3. Query the metadata service from inside (concepts.md's 169.254.169.254).
4. **Destroy it**: `oci compute instance terminate --instance-id ... `
   — then `list` to prove it's gone, and check the boot volume went with it
   (`--preserve-boot-volume false` is the default; confirm, don't assume).

Deliverable: the full launch→inspect→terminate cycle logged in the margin,
including one thing that surprised you.

## Phase 3 — Block Volume: the LVM Bridge (~1 hour)

Create a 50GB block volume, attach to a fresh lab instance (paravirtualized
attachment), then on-instance:

```bash
lsblk                                    # the new disk appears — /dev/sdb or /dev/oracleoci/oraclevdb
sudo pvcreate /dev/sdb && sudo vgcreate lab_vg /dev/sdb
sudo lvcreate -L 20G -n data lab_vg && sudo mkfs.xfs /dev/lab_vg/data
sudo mount /dev/lab_vg/data /mnt && df -h /mnt
```

Week-02's loop-device drills, except the "disk" is a datacenter SAN. Then
the cloud twist the laptop could never do: **resize it live** (console or
CLI volume update → rescan → `pvresize` → `lvextend` → `xfs_growfs`) — the
week-02 two-step trap, third step added. Detach, delete volume, terminate
instance.

## Phase 4 — Object Storage + a Real Backup (~1 hour, keep-able)

```bash
oci os bucket create --compartment-id "$C" --name homelab-backup
cd ~/homelab && git bundle create /tmp/homelab.bundle --all
oci os object put --bucket-name homelab-backup --file /tmp/homelab.bundle
oci os object list --bucket-name homelab-backup --output table
```

A `git bundle` is the whole repo (history included) as one file — restore =
`git clone homelab.bundle`. This gives the repo a THIRD, off-site copy
beyond Gitea+GitHub, and it's the one artifact this lab is allowed to keep:
object storage at this size is pennies-to-free. Optional graduation:
schedule it — a systemd timer on tp-mudd, or an n8n workflow (M3 energy).
Round-trip test the restore once before trusting it; an unverified backup
is a hope, not a backup (1.6 doctrine).

## Exit Criteria

- [ ] Budget alarm exists and has emailed you at least once (trigger it or trust it)
- [ ] Can explain mudd-cloud's full stack: compartment → VCN → subnet →
      security list → instance → boot volume, from memory
- [ ] Launch→terminate cycle done entirely from the CLI without notes
- [ ] Block volume LVM cycle done, including the live resize
- [ ] Bundle backup exists in object storage AND restored successfully once
- [ ] Console cost page still reads $0.00

When all six boxes check, roadmap M4 (OpenTofu) starts from standing —
same resources, declared instead of commanded.
