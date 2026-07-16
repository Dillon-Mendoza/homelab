# Interview Prep — Junior Linux / NOC / Support Engineer

Three interview layers: recruiter screen (can you communicate), technical
(can you actually do it), behavioral (will you be good to work with). You are
unusually strong on 1 and 3 — nine years of talking to humans under pressure.
The prep budget goes mostly to layer 2.

Practice loop: `"Mock interview me for a [role] position"` — answers out
loud, not in your head. Out loud is a different skill and the one that gets
scored.

---

## The 90-Second Homelab Answer (memorize the skeleton, not the words)

Every interview opens some version of "tell me about your setup." Skeleton:
**scale → design decision → incident → automation.**

> "Six nodes — Fedora and Ubuntu servers, Pis, a cloud VM — on a WireGuard-
> based mesh with tiered default-deny ACLs I designed. Everything's in Git:
> configs, architecture decisions, and incident reports. The most useful
> thing in it is a network-wide outage I caused with an ACL change and then
> diagnosed layer by layer down to Tailscale's policy routing table — the
> writeup's in the repo. Currently moving fleet management to Ansible."

Under 90 seconds, three follow-up hooks planted (ACLs, the outage, Ansible)
— you choose the terrain they'll probe.

## Technical Questions You Already Own (map, don't memorize)

| They ask | You have |
|---|---|
| "Walk me through debugging a service that won't start" | week-10: status → journalctl -u → 203/EXEC → daemon-reload trap. Narrate the layer order, not just commands |
| "Users say the app is slow — go" | week-10 5.5: load vs nproc, vmstat columns, the high-load-idle-CPU trap, PSI |
| "Disk is full but we deleted the logs" | lsof +L1, deleted-but-open — you've BUILT this failure |
| "DNS is broken — how do you approach it" | Two real incidents + the layered stack: getent vs dig, @1.1.1.1 isolation, stale caches |
| "What happens when you type a URL and hit enter" | DNS chain → TCP handshake (seen in tcpdump) → TLS → HTTP. Walk it bottom-up, note where you'd look when each stage fails |
| "Explain SSH keys" | Daily practice + deliberate architecture choice (keys over Tailscale SSH) — give the tradeoff, not the definition |
| "How do you approach a problem you've never seen" | The 7-step methodology, then the ACL outage as proof it's practice, not a poster |
| "Permissions look right but access denied" | noexec mounts, SELinux contexts, ACLs — the week-10 unfixable-permission station |

Preparation for each: whiteboard it cold once, out loud, with a timer. If a
row wobbles, that's a targeted drill request away from solid.

## Answer Pattern for Unknowns (this gets scored higher than knowledge)

You WILL get questions you can't answer. The junior-role rubric scores the
response to "I don't know" above most correct answers:

> "I haven't run that. Here's how I'd approach it: [nearest thing you do
> know] — and I'd start with the man page / docs for [specific thing]."

Never bluff. Interviewers are calibrated bluff detectors, and one detected
bluff invalidates every real answer that preceded it.

## Behavioral Bank — STAR Format, Pre-Built From Hospitality

Prepare each as Situation (1 sentence) → Task → Action (the meat) → Result
(a number if possible). Write them in this file's margins after drafting out
loud:

1. **Pressure/outage:** the worst service night — POS down mid-rush.
   (Direct NOC/incident-response analog. This is your best story; polish it.)
2. **Conflict:** de-escalating a guest or staff conflict where you didn't
   have the authority to just decide.
3. **Mistake:** a call you got wrong and what changed after. (Pair it with
   the ACL outage for a technical version — you have a documented one.)
4. **Teaching:** ramping a struggling new hire — maps to runbooks and
   knowledge transfer.
5. **Process improvement:** something you systematized that outlived your
   shift. (The study system is the technical twin.)
6. **Why this transition** — the one only you can write. Requirements: it's
   a move TOWARD something (evidence: eighteen months of receipts), zero
   apology, and it ends on what hospitality gave you that the team gets for
   free.

## Your Questions for Them (asking none reads as no interest)

- "What does the first month look like — and what would a great first 90
  days have accomplished?"
- "How does the team handle incidents — is there a postmortem culture?"
  (You genuinely care, and it signals you know what postmortems are.)
- "What's the on-call structure?" (Ask it plainly — you've done nights for
  nine years; their answer tells you about the team's health.)
- "What separates the juniors who grow fast here from the ones who don't?"

## Logistics Notes

- NOC/support interviews often include a live triage exercise — think out
  loud the whole time; silence reads as flailing even when it's thinking.
- Have the repo open and know the path to the ACL writeup without searching.
- Salary question deflect (until they name a number): "I'm focused on the
  right first role in Linux infrastructure — what's the range budgeted?"
  Never anchor first against nine years of non-tech salary history.
