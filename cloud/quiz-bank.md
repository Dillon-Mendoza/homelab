# Cloud Quiz Bank — Answers at Bottom
# Usage: teaching model draws 5 ("Quiz me on cloud concepts") after
# concepts.md is read; gate for starting oci-lab.md phase 2+.

## Questions

1. mudd-cloud has an unpatched kernel CVE. Whose responsibility, under
   which doctrine, and what's the one-sentence version of that doctrine?
2. A new instance's service on :8080 is unreachable despite UFW allowing
   it. Name the layer you forgot, its OCI and AWS names, and the order
   packets traverse the two firewalls inbound.
3. Block vs object vs file storage: pick one for (a) a Postgres data
   directory, (b) nightly git-bundle backups, (c) a shared config
   directory two instances must both mount. One-line justification each.
4. What is 169.254.169.254, why is it a link-local address specifically,
   and why did metadata services move to require auth headers (v2)?
5. An instance needs hourly writes to object storage. Compare: API key
   file on disk vs instance principal — and name the failure mode the
   second eliminates.
6. Why is mudd-cloud (an exit node pushing all your traffic) nearly free
   on OCI but the identical design costly on AWS? Name the billing
   concept.
7. Region vs availability domain vs fault domain — and map your
   muddpi-as-backup-exit-node design onto this vocabulary.
8. `tofu destroy` (future M4) removes a lab VCN but the console shows a
   stray block volume still billing. What operational rule did the lab
   break, and which two defenses catch it?
9. cloud-init vs Kickstart: which applies to mudd-cloud, when does it
   run, and how would you inspect on-instance what it did?
10. Your VCN is 10.0.0.0/16. Design: a public subnet for a bastion and a
    private subnet for an app tier — give example CIDRs, and name the two
    gateway types that give each its internet behavior.

## Answers

1. Yours — shared responsibility: provider secures the cloud (hardware,
   hypervisor, fabric); customer secures what's IN it (OS, patches, keys,
   data). IaaS = OS upward is yours.
2. Platform-layer firewall outside the instance: OCI Security List (or
   NSG), AWS Security Group. Inbound order: platform rules first (packet
   must be allowed into the instance's VNIC), THEN the instance's own
   UFW/firewalld. Either layer can be the blocker; check platform first
   on cloud instances.
3. (a) Block — a filesystem-capable disk with low-latency random I/O;
   databases need it. (b) Object — cheap, HTTP-addressable blobs, ideal
   for write-once backups. (c) File (NFS-style) — POSIX semantics shared
   by multiple mounters, which object can't do and block can't do
   concurrently.
4. The instance metadata service — identity, shape, user-data, credentials
   for instance principals. Link-local (RFC 3927) so it's only reachable
   from the instance itself and never routed. v2 auth (header/token)
   because SSRF vulnerabilities let attackers make apps fetch metadata —
   including credentials — via that open HTTP endpoint.
5. Key file: a long-lived secret on disk — leakable, committable,
   rotation is manual toil. Instance principal: the platform vouches for
   the instance's identity; short-lived tokens fetched at runtime, no
   stored secret. Eliminates the "credential file leaked/committed"
   failure class entirely.
6. Egress billing — data OUT of the cloud is metered, ingress free. An
   exit node is a pure egress machine. OCI's free tier includes a very
   large egress allowance (order of 10TB/mo — verify current); AWS bills
   egress from the first ~100GB, so the same traffic profile costs real
   money.
7. Region = metro area of datacenters; AD = isolated datacenter(s) within
   it (independent power/net); fault domain = rack-level separation
   inside an AD. muddpi backup exit node = surviving the loss of an
   entire "region" (the Oracle cloud) by failing over to independent
   infrastructure (home LAN) — a cross-region redundancy design in
   miniature.
8. "Everything created gets destroyed at phase end" — the volume was
   created outside the IaC state (or detached and preserved) so destroy
   didn't own it. Defenses: the budget alarm (bills the mistake into an
   email) and the end-of-phase console sweep in the exit criteria
   (cost page reads $0.00).
9. cloud-init — Kickstart automates the Anaconda INSTALLER on RHEL-family
   bare installs; cloud images boot pre-installed and run cloud-init at
   FIRST boot to inject users/keys/packages (how mudd-cloud got your SSH
   key). Inspect: `cloud-init status`, `/var/log/cloud-init-output.log`,
   and `cloud-init query userdata` (accept /var/lib/cloud inspection).
10. e.g., public 10.0.1.0/24, private 10.0.2.0/24 (any non-overlapping
    /24s inside the /16 — subnetting drill payoff). Public subnet's route
    table → Internet Gateway (bidirectional reachability); private
    subnet → NAT Gateway (outbound-only egress, no inbound initiation).
    Bastion in public, app tier in private, SSH hops through the bastion.
