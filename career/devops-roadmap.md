# DevOps Roadmap — Milestones From Here

The path is sysadmin-first, DevOps-second — deliberately. DevOps roles
assume operational judgment that only comes from running systems; the
homelab builds it, a first Linux role compounds it. Every milestone below
produces a repo artifact, because the operating principle of the whole
transition is: **claims need receipts.**

Rule inherited from the study system: one milestone in flight at a time.
Parallel milestones are how none of them finish.

---

## M0 — Foundation (in flight, ends Sep 14, 2026)

Linux+ passed. Everything else on this page is locked behind it — not
because the cert is precious, but because the exam date is the only
externally-fixed deadline in the whole plan, and it loses to nothing.

## M1 — Fleet Under Management (Oct 2026, ~3 weekends)

`homelab/ansible/` phases 1–4: every node answering, fleet-audit green,
bootstrap + hardening idempotent across all five nodes.
**Receipt:** `changed=0` full-fleet run committed to the repo; CLAUDE.md
security tables now provably match reality.
**Also in this window:** close the n8n `daemon.json` DNS pin — the open
step-6 item from incidents/. Small, but it closes your own loop and makes
the incident report end properly.

## M2 — CI Pipeline on Your Own Metal (Nov 2026, ~2 weekends)

You self-host Gitea; give it **Gitea Actions** (a runner on dell-ubuntu).
Pipeline v1: every push runs `bash -n` + ShellCheck over all repo scripts and
`ansible-lint` + `--syntax-check` over playbooks. Broken script = red build.
**Receipt:** a failed-then-fixed pipeline run in Gitea history.
**Why before cloud/k8s:** CI on your own infra teaches the runner, the
trigger, and the artifact flow — the part managed CI hides.

## M3 — Observability Beyond Green Lights (Dec 2026, ~2 weekends)

Netdata is per-host eyes; add fleet-level memory: **Prometheus + Grafana**
(containers on dell-fedora), node_exporter fleet-wide via a new Ansible
playbook (M1 skill compounding). One dashboard, THREE alerts that fire n8n
webhooks: disk >85%, host down 5m, failed systemd unit.
**Receipt:** screenshot of an alert firing end-to-end into a notification,
committed with the config.
**Depth rule:** resist dashboard sprawl — three alerts that page honestly
beat thirty panels nobody reads.

## M4 — IaC Against Real Cloud (Jan–Feb 2027, ~3 weekends)

**OpenTofu** managing OCI free tier (see homelab/cloud/): a second always-
free VM defined entirely in HCL — instance, VCN, security list, cloud-init.
`tofu apply` creates it, `destroy` removes it, state file understood (and
NOT committed; use a backend or .gitignore it — learning what state is,
including how it leaks secrets, is the milestone).
**Receipt:** the HCL in-repo + a plan/apply/destroy cycle documented.
mudd-cloud itself stays hand-managed and untouched — production doesn't get
experimented on, even in a homelab.

## M5 — Containers Grown Up (Mar 2027, ~2 weekends)

Migrate n8n from hand-run Docker on dell-fedora to **podman quadlets**
(systemd-native containers — where RHEL-world is actually going): unit-
managed, auto-updating, SELinux-labeled volumes, backed up. The May 2026 DNS
incident gets structurally impossible: DNS pinned in config, not inherited.
**Receipt:** the quadlet files + a written before/after of the migration.

## M6 — Kubernetes, Honestly Scoped (Apr–May 2027, ongoing)

**k3s** on dell-ubuntu (single node, or + muddpi for a real scheduling
decision). Deploy something already understood — the health-check service —
via Deployment/Service/ConfigMap. Break it on purpose; fix it with kubectl.
**Receipt:** manifests in repo + one self-written incident report of a
self-inflicted k8s failure.
**Honesty clause:** junior k8s knowledge gets you conversation, not jobs —
it's M6 because it compounds on M1–M5, not because it's the golden ticket.

---

## Certification Sequencing (opinionated)

| After | Cert | Why / Why not |
|---|---|---|
| Linux+ | **RHCSA** (next, ~Q1 2027) | The one cert hiring managers weight for Linux roles; performance-based exam suits you (the whole study system is performance-based); Fedora daily-driving = already half-prepared |
| RHCSA | Terraform Associate *or* AWS SAA | Only when targeting DevOps roles specifically; pick based on what M4 revealed you enjoy. Cheap, resume-keyword value |
| — | ~~CKA~~ | Not yet. Expensive signal that means little without professional ops experience under it |

Cert rule: never two in study at once, and never a cert over a milestone —
receipts beat badges at the junior level.

## Signal vs. Noise (the discipline that makes this a roadmap, not a wishlist)

- **Depth in one item per category** beats breadth: one config mgmt tool
  (Ansible), one cloud (OCI now — concepts transfer; AWS vocabulary comes
  via SAA if needed), one CI system, one observability stack. Interviews
  probe depth; tool-collecting reads as tourism.
- **The job hunt does not wait for the roadmap.** Applications start Oct 1
  (job-hunt/README.md) with M1 in progress. "Currently migrating my fleet
  to Ansible" is a better interview line than any completed milestone —
  it shows motion. The roadmap continues THROUGH the first job.
- **Re-scope on contact with reality:** first role lands → re-plan around
  what the team runs. This document is a compass, not rails.

## The Two-Year Picture

Late 2026: certified, fleet automated, applying. 2027: first Linux role;
milestones continue on evenings/weekends but now compound with production
exposure; RHCSA. 2028: the "junior" drops — by then the differentiator isn't
hospitality-manager-turned-admin, it's an engineer with two years of
documented operational judgment and management instincts the peers don't
have. That's the actual destination: not "DevOps engineer" as a title, but
unusual usefulness at the intersection of systems and people.
