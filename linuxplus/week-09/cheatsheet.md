# Week 09 — Automation Tools + Git + AI
# Domain: 4.0 Automation, Orchestration, and Scripting (17%) | Objectives: 4.1, 4.4, 4.5
# Calendar: Aug 24–30 | Session A — 45 min read
# 4.4 (Git) is hands-on and you half-know it already. 4.1 is a vocabulary
# objective — wide, shallow, definitional. 4.5 is the lightest on the exam.

---

## Objective 4.1 — Automation and Orchestration

### Ansible — the One You'll Touch

**Agentless:** the control node pushes over **SSH** (nothing installs on targets — Week 3's transport is the whole architecture). Python runs the modules on the far end.

**Inventory** — which hosts, in which groups (INI or YAML):
```ini
[web]
web01 ansible_host=127.0.0.1 ansible_connection=local

[db]
db01  ansible_host=127.0.0.1 ansible_connection=local
```
`ansible_connection=local` skips SSH — how you automate the machine you're on (and this week's lab).

**Ad-hoc** — one module, one line: `ansible -i inv.ini all -m ping` | `ansible web -m setup` (collect **facts**: auto-gathered host data — OS, IPs, memory — usable as variables) | `ansible db -m copy -a "src=f dest=/tmp/f"`.

**Playbook** — YAML: plays map **hosts** to ordered **tasks**; each task calls a **module** (`ansible.builtin.copy`, `dnf`, `service`, `command`). **Collections** are the packaging for modules/roles (`ansible-galaxy collection install`).

**Idempotency — the tested property:** modules describe *desired state*, not actions. First run: `changed=1`. Second run, nothing to do: `changed=0`. A playbook that "changes" something every run is buggy by definition. The lab makes you watch the 1→0 transition.

### The Contrast Table (definitional questions live here)

| Tool | Model | Language | Key nouns |
|---|---|---|---|
| Ansible | **Agentless, push** (SSH) | YAML | inventory, playbook, module, facts, collections |
| Puppet | **Agent, pull** — agent polls the server (default every 30 min) | Ruby DSL | classes, modules, **catalog** (compiled desired state), facts, **certificates** (agent↔server trust) |
| OpenTofu (Terraform fork) | Declarative **IaC** for infrastructure itself | HCL | **provider** (talks to a platform), **resource** (a thing to exist) |

```hcl
resource "local_file" "motd" {          # OpenTofu: resource TYPE + name
  filename = "/etc/motd"
  content  = "managed"
}
```

**Unattended deployment:** **Kickstart** — answer file for Anaconda (RHEL/Fedora installers): partitioning, packages, users, zero prompts. **cloud-init** — first-boot configuration for cloud images (user-data YAML: users, keys, packages) — how `mudd-cloud` got its SSH key before anyone logged in (conceptual anchor).

### CI/CD Vocabulary

- **Pipeline** — automated stages on every push: build → test → deploy.
- **Version-control integration** — the pipeline triggers from Git events; the repo is the source of truth.
- **GitOps** — desired infrastructure state lives *in Git*; an operator reconciles reality to match the repo. Rollback = `git revert`.
- **DevSecOps / shift-left** — security testing moves earlier ("left" on the timeline): scanners in the pipeline, not audits after release.

### Container Orchestration

**Kubernetes hierarchy:** cluster → **node** (a machine) → **pod** (1+ containers sharing net/storage — the smallest deployable unit) → container.

| Object | Job |
|---|---|
| **Deployment** | Declares "N replicas of this pod"; handles rollout/rollback/self-healing |
| **Service** | Stable name/IP in front of ephemeral pods (pods die, the Service endures) |
| **ConfigMap** / **Secret** | Config data / sensitive data, injected as env vars or files |
| **Volume** | Storage attached to a pod |

**Docker Swarm** — Docker's simpler built-in orchestrator: **services** made of **tasks** (containers) spread across **nodes**; `docker service scale web=5`. Same ideas, smaller words.

**Compose** — single-host, multi-container: one `compose.yaml` declaring services/networks/volumes; `podman-compose up -d`, `logs`, `down`. The n8n stack on `dell-fedora` is the fleet's live example (conceptual anchor); the lab's optional task builds one here.

---

## Objective 4.4 — Git

### The Three Trees — Every Command Is a Move Between Them

```
working directory  --add-->  staging (index)  --commit-->  local repo  --push-->  remote
                  <--restore--            <--reset--                  <--fetch/pull--
```

| Command | What moves |
|---|---|
| `git init` / `init --bare` | New repo / repo with no working tree (what a "remote" server is) |
| `git config user.name` (`--global` or per-repo) | Identity on commits |
| `.gitignore` | Untracked files Git won't see — **does NOT untrack already-tracked files** (`git rm --cached` does) |
| `git status` / `git diff` / `git diff --staged` | Where things are / unstaged changes / staged changes |
| `git add -p` | Stage hunk-by-hunk — review while staging |
| `git log --oneline --graph --all` | History as a picture |
| `git stash` / `stash pop` | Shelve dirty work / bring it back — the "urgent interruption" tool |
| `git tag v1.0` | Human name pinned to a commit (releases) |
| `git clone` / `remote -v` / `push` / `fetch` / `pull` | Remote lifecycle — **pull = fetch + merge** |

### Branching — merge vs rebase vs squash

- `git branch fix` + `git checkout fix` (or `git checkout -b fix`, modern: `git switch -c fix`).
- **merge** — ties two histories with a merge commit; truthful, non-linear. (Fast-forward happens when the target hasn't moved — no merge commit at all.)
- **rebase** — replays your commits *on top of* the target: linear history, **rewritten commits** (new hashes).
- **squash** — N commits become 1: `git merge --squash fix` or interactive `git rebase -i HEAD~2` (mark commits `squash`).
- **The golden rule:** never rebase commits that have been pushed/shared — rewriting published history breaks everyone who pulled it.

### reset — the Three-Mode Table (memorize cold)

| Command | HEAD moves | Staging | Working dir |
|---|---|---|---|
| `git reset --soft HEAD~1` | ✓ | kept (changes staged) | kept |
| `git reset --mixed HEAD~1` (default) | ✓ | cleared (changes unstaged) | kept |
| `git reset --hard HEAD~1` | ✓ | cleared | **DESTROYED** |

Mnemonic: soft touches nothing but HEAD; mixed also clears the index; hard takes everything. `--hard` is the only one that destroys work.

---

## Objective 4.5 — Responsible AI Use

**Sanctioned use cases (know the list):** code generation, IaC generation, documentation, security review, compliance recommendations, regex generation, code linting.

**Best practices — one rule wearing seven costumes:** always review output; never copy/paste without QA; **verify before use**. AI output is a *draft from an unverified contributor* — it gets the same review a human PR gets. (Your CLAUDE.md already states this policy: "if I can't explain it, it doesn't get implemented." That sentence is a 4.5 model answer.)

**Data governance:** prompts may become training data — never paste secrets/proprietary code into external tools; **local models** keep data on-premises, **cloud models** trade that for capability; **corporate policy** decides which tools/data are permitted; **human review** stays in the loop for consequential output.

**Prompt engineering basics:** specific beats vague; provide context and constraints; iterate on results; ask for the *reasoning*, not just the answer.

**Hallucination risk:** models produce confident falsehoods — nonexistent flags, invented module names. The countermeasure is the verification habit above (and Session B hands you a buggy "AI-generated" script to catch this with).

---

## Quick Recall

Ansible — agentless push over SSH; Puppet — agent pulls a catalog every 30 min
Idempotent — second run reports changed=0; a run that always "changes" is broken
Facts — auto-collected host variables (`setup` module)
OpenTofu — provider talks to a platform; resource declares a thing
Kickstart — installer answer file; cloud-init — first-boot config for cloud images
GitOps — Git holds desired state; reconciler makes reality match
Shift-left — security testing moved earlier in the pipeline
Pod — smallest K8s unit; Deployment keeps N replicas; Service = stable front door
ConfigMap plain config; Secret sensitive config
pull = fetch + merge (fetch alone changes no local branch)
`git diff` unstaged; `git diff --staged` staged
.gitignore won't untrack tracked files — `git rm --cached`
reset: --soft keep staged / --mixed keep unstaged / --hard destroy
Never rebase pushed history
`git merge --squash` — N commits land as 1
stash → pop — shelve dirty work across a branch switch
AI output = unverified draft; review like a PR; never paste secrets into prompts
