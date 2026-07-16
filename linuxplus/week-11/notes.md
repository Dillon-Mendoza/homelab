# Week 11 — Reference Notes
# Objectives: ALL (review) | Calendar: Sep 7–13 | Exam: Sep 14

---

## Exam Objective Mapping

No new objectives — this week is the whole map at once. What matters now is
weight, because weight decides where a marginal hour goes:

| Domain | Weight | ~Questions | Week folders |
|---|---|---|---|
| 1 System Management | 23% | ~21 | 01, 02, 03 |
| 2 Services and User Management | 20% | ~18 | 04, 05, 06 |
| 3 Security | 18% | ~16 | 06, 07 |
| 4 Automation, Orchestration, Scripting | 17% | ~15 | 08, 09 |
| 5 Troubleshooting | 22% | ~20 | 10 |

D1 + D5 = 45% of the exam. If the practice score forces triage, these two are
never the ones to cut. Exam mechanics: max 90 questions, 90 minutes, 720/900
to pass, multiple-choice plus performance-based (PBQs).

**The week's two rules, from topic-map.md:**
1. 80%+ on the practice exam before booking. Below 80% → the two lowest
   domains own every remaining day, then re-test.
2. Max 10 minutes per gap topic. No full re-reads. Targeted drilling only —
   "Quiz me on objective X.X" until 80%+ per objective.

---

## Key Man Pages

Nothing new to read — but the meta-skill matters on exam morning and in every
job interview after: you never memorized commands, you memorized where answers
live. The five pages that earned permanent bookmarks this sprint:

`man 8 lsof` (+L1), `man 5 systemd.exec` (exit codes), `man 8 vmstat` (fields),
`man 5 crontab` (field table), `man git-reset` (the three modes).

If a drill session surfaces a flag you can't place: `man -k <topic>` /
`apropos <topic>` finds the page; `type -a <cmd>` confirms what would actually
run. Those two reflexes are worth more this week than any single fact.

---

## Video Timestamps

**Theory Course (12hr — nGPK6YBbKpg):**
Do NOT rewatch the course. Its one week-11 use: after the practice exam names
a weak objective, jump to that objective's segment at 1.5x as a 10-minute
refresher — the course is organized by objective number, so the score report
is the index. Anything more is comfort-watching disguised as study.

**Labs Course (7hr — JXIaR23OdB8):**
Same rule, one exception: if PBQs felt shaky on the practice exam, watch one
troubleshooting lab end-to-end the day before the exam — not for content, but
to re-groove the rhythm of reading output under time pressure.

---

## Book Reference — How Linux Works, 3rd Ed. (Ward)

Per the topic-map: none this week — review mode only. The book's job is done
unless the gap analysis names a *mechanism* you can't explain (not a flag you
forgot — a mechanism). Then, and only then: storage → Ch. 4, boot → Ch. 5–6,
processes → Ch. 8, network → Ch. 9. Ten minutes on the relevant section, back
to drilling. Don't read ahead of the gaps.

---

## Things That Trip People Up — Exam-Day Edition

**1. The clock is the real opponent: 60 seconds per question**
90 questions, 90 minutes, and PBQs eat 3–5 minutes each. Budget: first pass
answers everything answerable in under a minute and flags the rest; second
pass works the flags. Never stand still on a question — a flagged skip costs
nothing, a five-minute stall costs five questions.

**2. Handle PBQs deliberately**
They usually front-load the exam. Give each one honest effort while you're
fresh — but set a hard ceiling (~5 min), and if it's fighting you, flag it and
bank the multiple-choice points first. PBQs are often partially credited;
abandoned multiple-choice questions are not.

**3. BEST / FIRST / NEXT are three different questions**
CompTIA's favorite trick is four true answers. "FIRST" and "NEXT" are
methodology questions — the answer is the next step in identify → theory →
test → plan → implement → verify → document, not the eventual fix. "BEST"
wants the least-drastic sufficient option. Read the capitalized word twice.

**4. Eliminate before you select**
Every question has one or two answers that are wrong on their face (deprecated
tool, wrong distro family, wrong layer). Cutting them first turns a 25% guess
into 50% — that margin, across 90 questions, is a passing score.

**5. Your first answer is usually right**
Change an answer only when you can name the specific fact that proves the
first one wrong. "It felt off on review" is how correct answers die.

**6. The night before is for sleep, not synthesis**
One pass of week-11/cheatsheet.md, then stop. Cramming past that point trades
working memory (which the PBQs need) for facts you already know. This is the
same discipline as the Sunday ritual: trust the system you built.

---

## Connect to the Homelab

Eleven weeks ago this exam was a topic list; now it's a lap around systems you
already run. The practice exam will describe scenarios you've lived: its DNS
question is the n8n container incident, its routing question is `ip route show
table 52` cracking the ACL outage, its unit-failure question is the 203/EXEC
you injected yourself in week 10, its Git questions are the dual-remote repo
this file is committed to. Walking in on September 14, the honest inventory
is: a tiered zero-trust network designed and documented, two incidents
diagnosed methodically and written up, ten weeks of labs executed on real
hardware, and a study system that survived its own known failure point — the
Sunday ritual — for eleven consecutive weeks. The certification validates
that; it doesn't create it. After the exam, two threads are already queued:
the Ansible inventory from week 9 waiting to manage the actual fleet, and the
n8n `daemon.json` DNS pin still flagged open in incidents/ — the first
post-cert project is closing your own step-6 loop.
