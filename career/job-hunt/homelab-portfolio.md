# The Homelab as Portfolio

A repo link on a junior resume is common; a repo that reads like a
professional operation is not. An engineer who clicks through decides in
about 90 seconds. This file is about winning those 90 seconds — with what
already exists, presented deliberately.

---

## What You Have That Most Candidates Don't

Ranked by rarity — feature them in this order:

1. **Incident reports.** `incidents/` is the crown jewel. Almost no junior
   candidate has written a real postmortem: symptom → layered diagnosis →
   root cause → fix → *lessons learned* → follow-up items. The ACL outage
   writeup alone demonstrates methodology, writing ability, and honesty
   (it documents an unfixed follow-up item — that's engineering maturity).
2. **Architecture with reasoning.** A tiered default-deny ACL is a design
   *decision*, documented with the why. Most homelabs are "everything can
   reach everything."
3. **A self-designed study system** — curriculum, generation protocol,
   test-out gates, progress tracking, all in version control. This is
   process automation applied to yourself; hiring managers read it as
   "self-directed and systematic," which is the whole junior-hire question.
4. **Dual-remote Git with self-hosted Gitea.** You don't just use Git; you
   operate a Git service.
5. **Documentation-as-infrastructure culture.** CLAUDE.md's working
   agreement, device inventory, firewall tables — the repo reads like a
   team runbook, for a team of one.

## Repo Presentation Checklist (the Sep 15–30 pass)

- [ ] **Root README rewrite** — the 90-second tour: what this is, network
      diagram, links to the three best artifacts (ACL outage report, network
      architecture, ansible/). Assume the reader clicks exactly one link —
      make the first one the incident report.
- [ ] **A simple network diagram** — tiers, tags, arrows. ASCII or Mermaid
      in the README is fine; legibility beats beauty.
- [ ] **Sanitization sweep** — the week-09 audit already scans for tracked
      keys and inline credentials; run it, then also check: Tailscale IPs
      (100.x are only meaningful inside your tailnet but scrub if uneasy),
      email in configs, any employer names in incident timelines.
- [ ] **Pin the repo** on the GitHub profile; profile README = 3 lines +
      link. Recruiters check the profile, engineers check the repo.
- [ ] **Commit hygiene spot-check** — recent history tells the real story
      of how you work; make sure generated content is committed with honest
      messages (it's AI-assisted study tooling — say so plainly; the
      *system* is the impressive part, and claiming otherwise fails the
      two-questions-deep rule).

## Talking About AI Use (decide the answer now, not in the room)

The linuxplus content is Claude-generated under your review protocol. In an
interview this is an asset if framed as what it is: **you designed a
generation-and-validation pipeline with human review gates** — exactly the
4.5 objective, exactly how teams adopt AI. The line: "I use AI to generate
study material and first drafts against a curriculum I maintain; nothing
runs without my review — the repo's working agreement documents the policy."
Then point at a DRY_RUN default. What kills candidates is hiding it and
getting caught, not using it.

## Anticipate the Skeptical Questions

- *"Homelabs aren't production — no users, no stakes."* True and answerable:
  "Which is why I run it like it has stakes: default-deny networking, change
  documentation, incident reports with follow-ups. The habits transfer; the
  scale is what I'm applying to change." Then mention the 2am POS outages —
  you HAVE production experience; it just wasn't Linux.
- *"Did you actually build this or copy tutorials?"* Answer with a decision
  and its alternative: why tags-not-hostnames in the ACL, why SSH keys over
  Tailscale SSH, why the desktop is parked. Tutorial-copiers can't defend
  roads not taken.
- *"What broke recently?"* Never say "nothing." The honest answer is the
  best one you have — walk the ACL outage, end on the daemon.json item
  still open and why you track unfixed items in writing.
