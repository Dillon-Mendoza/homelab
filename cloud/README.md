# Cloud — Concepts and Practice, Anchored to mudd-cloud

You already run cloud infrastructure: `mudd-cloud` is an OCI compute
instance doing production duty as the tailnet's primary exit node. This
directory turns that single VM from "a thing that exists" into a working
understanding of the platform underneath it.

## Standing Rule — Read First

**mudd-cloud is production.** Every exercise in this directory is additive:
new instances, new volumes, new buckets — created, studied, destroyed.
Nothing modifies mudd-cloud, its VCN's existing rules, or anything the exit
node depends on. The `destroy` half of every exercise is part of the
exercise — free tier stays free because nothing is left running by accident.

## Files

| File | What | When |
|---|---|---|
| `concepts.md` | The vocabulary and mental models, mapped OCI ↔ AWS ↔ homelab | Post-exam reading; one sitting |
| `oci-lab.md` | Hands-on phases against the free tier, CLI-first | After concepts.md; feeds roadmap M4 |

## Invocation

- `"Explain [cloud concept] using my homelab as the analogy"`
- `"Quiz me on cloud concepts"` — after concepts.md
- `"Walk me through oci-lab phase [N]"` — commands explained before run,
  same as everywhere else in this repo

## Where This Leads

This directory deliberately stops at fundamentals + one platform. The
OpenTofu/IaC layer on top is roadmap milestone M4; an AWS vocabulary pass
(if DevOps postings demand it) is a cert decision documented in
career/devops-roadmap.md. Concepts transfer; consoles don't — learn the
ideas here, rent the other consoles when a job requires them.
