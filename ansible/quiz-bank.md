# Ansible Quiz Bank — Answers at Bottom
# Usage: teaching model draws 5 per session ("Quiz me on ansible"), Dillon
# answers before scrolling. Post-exam material — gate for roadmap M1.

## Questions

1. A playbook run reports `changed=4` on its third consecutive run against
   an unchanged host. What does this tell you about those tasks, and which
   two module choices most commonly cause it?
2. `ansible muddpi -m ping` returns UNREACHABLE, but `ssh muddpi` from the
   same terminal works. Name the three most likely inventory/config causes
   in the order you'd check them.
3. Your bootstrap playbook uses `state: present`, not `state: latest`. A
   teammate calls that a bug — packages won't get updates. Defend the
   choice, and describe where updates SHOULD happen.
4. What does `--check` NOT catch? Give a concrete example where a playbook
   passes `--check` clean and still fails a real run.
5. Explain what a handler is, when it runs, and the failure mode of putting
   `service restarted` as a regular task instead.
6. Why does 02-hardening validate sshd config with `validate: /usr/sbin/sshd
   -t -f %s` instead of just restarting and checking? What's the blast
   radius difference?
7. `become: true` at play level vs `-K` on the command line — what does
   each actually provide, and what error do you get with the first but not
   the second?
8. The fleet-audit playbook uses `changed_when: false` on command tasks.
   What lie does this correct, and why does it matter for reading run
   summaries?
9. A task must run only on Debian-family hosts. Show the conditional, and
   name where the fact it tests comes from.
10. Order of precedence puzzle: a variable is set in inventory, in
    group_vars/all.yml, and with `-e` on the command line. Which wins, and
    what's the practical rule to keep this from ever mattering?

## Answers

1. They're not idempotent — they act every run instead of declaring state.
   Usual suspects: `command`/`shell` (Ansible can't know if they changed
   anything → always "changed") and templates/copies with changing content
   (timestamps). Fixes: state modules, `creates:`/`changed_when`.
2. (a) `ansible_user` wrong/missing for that host — ssh CLI uses your
   ~/.ssh/config, Ansible doesn't read that user by default; (b) wrong
   inventory hostname/typo → resolving differently; (c) python interpreter
   missing/misdetected on target (shows differently but checked third).
   `-vvv` shows the exact ssh line Ansible ran — the fast diagnostic.
3. present = "installed at some version" — idempotent and stable; latest
   makes every run a potential upgrade → uncontrolled change coupled to
   playbook runs. Updates belong in a dedicated update playbook run
   deliberately (serial, with reboot handling), not as a side effect.
4. Check mode doesn't execute, so anything depending on a PRIOR task's
   real result lies: e.g., task 1 installs a package, task 2 starts its
   service — in --check the package never installed, but check-mode
   "would have started" often passes; conversely registered command output
   is empty → templates/conditionals using it behave differently. Also
   command/shell tasks skip entirely by default.
5. A handler runs once, at the end of the play, only if notified by a
   changed task. As a regular task, the service restarts EVERY run even
   when nothing changed — needless disruption and a false "changed" — and
   restarts happen mid-play before dependent config lands.
6. validate runs the syntax check against the temp file BEFORE replacing
   the target — a bad config never lands, sshd never sees it, current
   sessions and future ones unaffected. Restart-then-check lands the bad
   config first: sshd fails to start, and every new SSH connection to that
   host is dead until fixed via console — on a remote box, that's the
   lockout.
7. `become: true` says "escalate with sudo"; `-K` supplies the sudo
   PASSWORD. With become but no -K on hosts lacking NOPASSWD, you get
   "Missing sudo password" — escalation was requested but couldn't
   authenticate.
8. command/shell report changed=true always (Ansible can't inspect their
   effect). On a read-only audit that's false signal — a "changed" audit
   looks like it modified the fleet. changed_when: false makes the summary
   truthful: ok=N, changed=0 for pure reads.
9. `when: ansible_facts['os_family'] == 'Debian'` — from gather_facts
   (the setup module) running automatically at play start.
10. `-e` (extra-vars) wins — highest precedence; group_vars/all beats
    inventory vars for groups... practical rule: define each variable in
    exactly ONE place, use precedence only as an emergency override (-e),
    and treat needing the precedence table as a design smell.
