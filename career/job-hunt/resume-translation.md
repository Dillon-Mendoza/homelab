# Resume Translation — Hospitality Management → Linux Operations

The resume's job is to survive a 15-second skim by a recruiter who has never
run Linux, then a 2-minute read by an engineer who has. Structure and
translation below serve both readers.

---

## Structure for a Career-Changer (order matters)

1. **Summary** — 3 lines max. Career changer framed as fact, not apology.
2. **Technical Skills** — grouped, keyword-honest (ATS reads this block)
3. **Technical Projects** — the homelab, written like work experience. For
   this resume it IS the experience section that matters.
4. **Certifications** — Linux+ with date
5. **Professional Experience** — hospitality, translated (below)
6. Education last, brief.

Never lead with hospitality titles and hope the reader keeps going. Lead
with what you can do now.

### Summary (draft to iterate on, not to copy blind)

> Linux systems administrator (CompTIA Linux+) with nine years of operations
> management experience. Designed and operate a multi-node production
> homelab — tiered zero-trust networking, configuration management,
> monitoring, and documented incident response. Seeking a junior Linux/
> infrastructure role.

Note what it does NOT say: "aspiring," "passionate," "transitioning,"
"eager to learn." State capabilities; let the reader conclude.

## Technical Skills Block (honest as of Sept 2026 — update as true)

```
Linux:        Fedora, Ubuntu Server, Debian/RPi OS — administration, systemd,
              SELinux, LVM, firewalld/UFW/nftables
Networking:   Tailscale/WireGuard mesh (zero-trust ACLs), DNS, SSH hardening,
              tcpdump, subnetting
Automation:   Bash, Python (basics), Ansible, Git (Gitea self-hosted + GitHub)
Containers:   Podman, Docker, compose
Monitoring:   Netdata, journald/rsyslog, health-check scripting, n8n workflows
Cloud:        Oracle Cloud (compute, VCN basics)
```

Rule: every item must survive "tell me about how you've used X." Python says
"(basics)" because that's what's defensible — an interviewer who hits honest
scoping trusts everything else on the page more.

---

## The Translation Table — Nine Years, Re-Languaged

Hospitality management IS operations. Same job, different stack. Translate
the function, never the title:

| You did (hospitality) | The resume says (ops language) |
|---|---|
| Ran shifts during rushes, handled the night everything broke | Incident response under pressure; triage, delegation, and communication during service-impacting events |
| Scheduled staff against forecasted demand | Resource planning against variable load; capacity forecasting |
| Trained new hires, wrote how-tos for staff | Authored operational runbooks and SOPs; onboarded and mentored staff |
| Managed vendors (suppliers, POS support, contractors) | Vendor management and escalation, including SLA-bound support contracts |
| Kept POS/reservation systems running, dealt with outages | Frontline system reliability: first responder for POS and booking-platform outages, coordinating vendor escalation |
| Managed inventory/ordering | Managed procurement pipelines; balanced cost against availability |
| Handled guest complaints/escalations | Stakeholder management; de-escalation and expectation-setting under time pressure |
| Responsible for P&L / labor cost | Budget ownership; cost optimization without service degradation |
| Health/safety inspections, compliance paperwork | Regulatory compliance and audit preparation |

**The bullet formula:** *Accomplished [X] as measured by [Y] by doing [Z].*
Numbers survive skims — even conservative ones: team size, covers per night,
budget size, years, retention. "Managed a team of 12 across a 7-day schedule"
beats "responsible for staff management" in any stack.

### Worked examples

- Weak: "Responsible for restaurant operations."
- Strong: "Directed daily operations for a $2M/yr venue — 12 staff, 300+
  covers/night; first responder for POS and reservation-system outages,
  including vendor escalation and workaround comms."

- Weak: "Trained employees."
- Strong: "Built the training program and wrote the operational runbook that
  cut new-server ramp-up from 4 weeks to 2; documentation habit carried
  directly into infrastructure work (see incident reports, portfolio)."

---

## Homelab as "Technical Projects" — write it like a job

> **Homelab Infrastructure — Designer/Operator** (2025–present)
> - Operate a 6-node environment (Fedora, Ubuntu Server, RPi OS, Oracle
>   Cloud): KVM virtualization, containers (Podman/Docker), self-hosted Git
>   (Gitea) with dual-remote replication to GitHub
> - Designed tiered default-deny zero-trust network ACLs over a WireGuard-
>   based mesh (Tailscale); documented, then diagnosed and resolved a
>   network-wide outage caused by an ACL policy gap — full incident report
>   in repo
> - Automated fleet configuration with Ansible (bootstrap, hardening, health
>   audits); hardened SSH and SELinux-enforcing hosts; monitoring via Netdata
>   with n8n webhook alerting
> - Maintain infrastructure-as-documentation: every config decision,
>   incident, and architecture choice committed to version control

Each bullet is checkable in the public repo. That's the point — see
`homelab-portfolio.md` for making the repo interview-ready.

## ATS Notes (the robot reads first)

- Mirror the posting's exact tokens once each where true: they search "Red
  Hat"/"RHEL" not "Fedora" — "(RHEL-family)" after Fedora is honest and
  matches. Same for "Ubuntu", "bash", "scripting", "troubleshooting".
- No tables/columns/graphics in the actual resume file — single column,
  standard headings, PDF. (Tables are for THIS doc, not the resume.)
- One page. Nine years + career change is still one page — density is the
  proof of editing skill.

## Do Not

- Do not apologize for the transition anywhere. Not in the summary, not in
  the cover letter, not in interviews. "Career change" framed as decision,
  demonstrated by eighteen months of receipts.
- Do not inflate: "designed zero-trust network" is defensible; "network
  engineer" as a title is not. The interview always finds the seam.
- Do not bury the homelab under hospitality history — it's the top half of
  the page or the resume fails its one job.
- Do not list every tool ever touched. The skills block is what you can
  defend, not what you can spell.
