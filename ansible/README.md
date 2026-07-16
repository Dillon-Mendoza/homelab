# Ansible — Fleet Automation

The post-exam project, pre-built. Week 9 of the Linux+ sprint proved the
mechanics against localhost; this directory points the same mechanics at the
real fleet. The hard part — SSH key infrastructure over Tailscale — was solved
months ago. Ansible is just those keys with a YAML steering wheel.

**Control node:** `tp-mudd` (never in the inventory — Ansible runs FROM here).
**Transport:** SSH over `tailscale0`, exactly as today. `tag:t0` has full
access to every tier, so the existing ACL already permits everything Ansible
needs. No new firewall rules, no agents, nothing installed on targets.

---

## Rules of Engagement

1. **Nothing here runs until Linux+ is passed.** This directory exists so the
   week after the exam has a project waiting, not so exam weeks lose Sundays.
2. **Every playbook runs `--check --diff` first.** Same policy as everything
   else in this homelab: no change without understanding what will change.
3. **One tier at a time.** First runs use `--limit muddpi` (Tier 2, lowest
   blast radius with a real OS). Never first-run against `dell-ubuntu` — it
   hosts Gitea, and `mudd-cloud` is the production exit node.
4. If a task can't be explained, it doesn't run — a playbook is a script with
   better manners, and CLAUDE.md's rule applies to YAML too.

## Invocation

- `"Explain ansible playbook [name] task by task"` — before first run of anything
- `"Extend the [bootstrap|hardening|fleet-audit] playbook to also [X]"`
- `"Write a new playbook for [X]"` — after the three shipped ones are mastered
- `"Debug this ansible output: [paste]"`

---

## Learning Path — Phased

**Phase 0 — done.** Week-09 lab: inventory format, ad-hoc, facts, idempotency
proof against localhost. If that's fuzzy, rerun `linuxplus/week-09/lab-script.sh`.

**Phase 1 — first contact (post-exam week 1).**
```bash
sudo dnf install -y ansible-core
ansible-galaxy collection install ansible.posix community.general
ansible -i inventory.ini fleet -m ping          # keys + inventory sanity
ansible -i inventory.ini fleet -m setup -a 'filter=ansible_distribution*'
```
Every host answers `pong` → the fleet is under management. That's the whole
milestone. Debug per-host with `ansible -i inventory.ini muddpi -m ping -vvv`.

**Phase 2 — read-only trust building.**
```bash
ansible-playbook -i inventory.ini playbooks/03-fleet-audit.yml
```
The audit playbook changes nothing — it's the linuxplus audit-script habit
promoted to fleet scale. Run it until the output feels boring.

**Phase 3 — first real change.**
```bash
ansible-playbook -i inventory.ini playbooks/01-bootstrap.yml --check --diff --limit muddpi
ansible-playbook -i inventory.ini playbooks/01-bootstrap.yml --limit muddpi
ansible-playbook -i inventory.ini playbooks/01-bootstrap.yml --limit muddpi   # changed=0 or it's buggy
```
Then widen: `--limit tier2,tier3`, then the rest. Cloud last.

**Phase 4 — hardening as code.**
`02-hardening.yml` encodes the security posture that's currently hand-applied
and documented in CLAUDE.md. When it runs clean with `changed=0` across the
fleet, the documented state and the actual state are provably identical —
which is the entire point of configuration management.

**Phase 5 — beyond (see career/devops-roadmap.md).** Netdata deployment,
scheduled runs via systemd timers, secrets with ansible-vault, then roles.

---

## Layout

```
ansible/
├── README.md            # this file
├── inventory.ini        # the real fleet, grouped by tier and family
├── group_vars/
│   └── all.yml          # fleet-wide variables
└── playbooks/
    ├── 01-bootstrap.yml    # baseline packages + hygiene, both families
    ├── 02-hardening.yml    # sshd + firewall posture as code
    └── 03-fleet-audit.yml  # read-only health sweep (run this first, always)
```

## Gotchas Waiting to Happen (read before Phase 1)

- **Raspberry Pi OS is Debian** — it takes the `apt` path everywhere; only
  `dell-fedora` is RHEL-family. The inventory's family groups handle this.
- **`ansible_user` differs per host** — set per-host in the inventory, not
  globally. Wrong user = key refused = misleading "unreachable" error.
- **Privilege escalation:** plays that change state need `become: true`;
  passwordless sudo isn't configured fleet-wide, so run with `-K`
  (ask-become-pass) until that decision is made deliberately.
- **firewalld module needs `ansible.posix`, ufw needs `community.general`** —
  both installed in Phase 1, both will bite if skipped.
- **A hardening playbook can lock you out.** 02-hardening never touches
  `tailscale0` interface rules and validates sshd config before restarting —
  read those tasks and understand why before running.
