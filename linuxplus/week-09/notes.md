# Week 09 — Reference Notes
# Objectives: 4.1, 4.4, 4.5 | Calendar: Aug 24–30

---

## Exam Objective Mapping

**4.1 — Summarize use cases and techniques of automation and orchestration**
- Ansible: playbooks, inventory, modules, ad hoc, agentless, collections, facts
- Puppet: classes, modules, certificates, facts, agent/agentless
- OpenTofu: provider, resource
- Unattended deployment: Kickstart, cloud-init
- CI/CD: version-control integration, pipelines, GitOps, DevSecOps, shift-left
- Kubernetes: pods, deployments, services, ConfigMaps, volumes, secrets
- Docker Swarm: services, nodes, tasks, networks, scale
- Docker/Podman Compose: compose file, up/down, logs

**4.4 — Given a scenario, implement version control using Git**
- Setup: `git init`, `git config`, `.gitignore`
- Daily: `add`, `commit`, `status`, `diff`
- Branching: `branch`, `checkout`, `merge` (squash), `rebase`
- Remote: `clone`, `fetch`, `pull`, `push`, `remote`
- Advanced: `log`, `stash`, `tag`, `reset`

**4.5 — Summarize best practices and responsible uses of AI**
- Use cases: code/IaC generation, docs, security review, compliance, regex, linting
- Best practices: always review, no blind copy/paste, verify output
- Data governance: training-data risk, human review, local vs cloud, policy
- Prompt engineering basics

---

## Key Man Pages

`man git-reset` — the top of the page is the soft/mixed/hard table in official language, including the sentence about `--hard` discarding changes. Read the three mode paragraphs once after doing lab Task 3.

`man git-rebase` — just the first two paragraphs plus the "Recovering from upstream rebase" warning box: that box IS the golden rule, stated by the tool's own authors.

`man gittutorial` — Git ships its own tutorial in section 7 (also `man gitglossary` for any term the exam uses). Knowing these exist is worth more than any single fact in them.

`ansible-doc` — Ansible's man-page equivalent: `ansible-doc ansible.builtin.copy` documents every module parameter, with examples. `ansible-doc -l | wc -l` shows the scale of the module library.

`man git-log` — the PRETTY FORMATS section; `--oneline --graph --all` was this week's x-ray, and this page is where its variants live.

---

## Video Timestamps

**Theory Course (12hr — nGPK6YBbKpg):**
"Automation and Orchestration" (4.1) is definition-dense — treat it as a vocabulary pass and keep the contrast table (agentless/push vs agent/pull) in front of you. The "Git" section (4.4) will demo commands you've now run in a sandbox; watch it at 1.5x as reinforcement. If there's a short AI-use section (4.5), it's likely five minutes — matching its exam weight.

**Labs Course (7hr — JXIaR23OdB8):**
The Git lab is the valuable one — watch their branching demo AFTER your sandbox run and diff their workflow against yours (they'll likely merge without --no-ff; can you predict how their graph differs?). If Ansible gets lab coverage, note whether their inventory targets remote hosts — yours used `ansible_connection=local`, and spotting that one-line difference proves you understand the transport.

---

## Book Reference — How Linux Works, 3rd Ed. (Ward)

**Ch. 9 — Understanding Your Network (background only)**
The topic-map's note is right: this week's tools aren't in the book. Ch. 9's relevance is one fact — Ansible's entire transport is SSH, so everything you know about Week 3's connection model applies verbatim to the control-node/managed-node relationship.

**Not covered, by design:** Git, Ansible, Kubernetes, CI/CD. The primary sources this week are `man gittutorial`/`git-reset`/`git-rebase`, `ansible-doc`, and the tools themselves. By now that pattern — objectives outline, man pages as text, lab as proof — should feel like the default rather than a fallback; that's deliberate.

---

## Things That Trip People Up

**1. reset's three modes — anchor them to what survives**
`--soft`: everything survives, staged. `--mixed`: everything survives, unstaged. `--hard`: nothing survives. Lab Task 3 ran all three against sacrificial commits; on the exam, map the question's "changes still staged / still present / gone" phrasing straight onto the table.

**2. pull is fetch + merge — and fetch alone is always safe**
`fetch` updates `origin/main` (a remote-tracking ref) and touches nothing you've written; `pull` immediately merges it into your branch. When a question hints at "see what changed upstream *without* affecting local work," the answer is fetch. Task 4's two-clone setup made the gap visible as "behind by 1."

**3. The rebase golden rule**
Rebase rewrites commits (new hashes — you watched it happen in Task 2b). Rewriting *published* history forces everyone downstream into conflict hell. Safe: rebasing your local, unpushed branch. Unsafe: rebasing anything others may have pulled. The exam phrases it as "after a force-push, teammates report errors."

**4. .gitignore does not untrack files**
It only prevents *untracked* files from being noticed. A file already committed keeps being tracked no matter what .gitignore says — `git rm --cached <file>` untracks it (keeping the disk copy). The audit script checks for exactly this gap in the real repo.

**5. Idempotency means the second run is a no-op**
`changed=0` on an unchanged system isn't a failure — it's the definition of correct. Conversely, a playbook that reports `changed` every run (e.g., using `command` where a state module exists) is the buggy option in the question. Task 5e's double run is the memory to reach for.

**6. Agentless/push vs agent/pull — one axis, two tools**
Ansible: nothing on the target, control node pushes over SSH, runs when you run it. Puppet: agent installed on the target, *pulls* a compiled catalog from the server every 30 minutes, enforces continuously. Certificates authenticate Puppet's agent↔server pair. Most 4.1 tool questions are this axis wearing different clothes.

---

## Connect to the Homelab

This week's objectives are unusual: two of them describe things you already do every day. The homelab repo *is* 4.4 in production — dual-remote push to Gitea and GitHub (which the audit script now verifies on every run), a commit history documenting every infrastructure change, and now sandbox-proven fluency in the recovery tools (reset, stash, rebase) for when something goes sideways. And 4.5 is quite literally this study system: every cheatsheet, lab, and audit script in `linuxplus/` is AI-generated content operating under the exact governance the objective describes — a standing human-review policy (CLAUDE.md: "if I can't explain it, it doesn't get implemented"), verification before execution (DRY_RUN defaults, `bash -n` checks), and Task 7's planted-bug exercise as proof the review habit has teeth. The genuinely new capability is Ansible: today it manages two aliases of localhost, but the inventory format you documented is the exact file where `dell-ubuntu`, `muddpi`, and the rest would slot in after exam day — agentless over SSH means your existing key infrastructure is already the hard part, solved. That fleet-automation project is the natural first post-exam build.
