# RHCSA (EX200) — Curriculum Seed
# Status: SEED. Do not build out until Linux+ is passed and ansible M1 is
# done (career/devops-roadmap.md gates RHCSA at ~Q1 2027). This file exists
# so the next subject starts with zero latency: objectives captured,
# architecture decided, bootstrap instructions written.

---

## Why RHCSA Next (from the roadmap, restated for the future session)

Performance-based exam — no multiple choice, a live RHEL system and a task
list. That's the format the whole homelab study system already trains for:
every Linux+ Session B was a small EX200 rehearsal. Fedora daily-driving
means the tooling (dnf, systemd, SELinux, firewalld) is already muscle
memory; the delta is RHEL-specific packaging (streams/modules),
exam-specific tasks (boot-target interrupts, LUKS, autofs, NFS), and speed.

## Exam Facts (verify at redhat.com before building the full system —
EX200 tracked RHEL 9 as of mid-2026; a RHEL 10 version may exist by 2027)

- ~2.5 hours, live system(s), all tasks must survive a REBOOT (the exam
  grades the persistent state — the single most important habit difference
  from casual admin work).
- No internet, but full man pages and /usr/share/doc — documentation-
  navigation IS an exam skill (TEACHING.md's meta-skill, now graded).
- Practice environment: RHEL via free Red Hat Developer subscription, as
  VMs on tp-mudd (KVM — week-03 skills). Two VMs minimum: one to break,
  one to practice server roles against. This satisfies the ThinkPad-only
  constraint naturally.

## Objective Domains (EX200/RHEL 9 — re-verify at build-out)

1. **Essential tools** — shell, redirection, grep/regex, ssh, users/switch,
   tar/gzip/bzip2, file ops, hard/soft links, permissions, man/doc lookup.
   *Linux+ overlap: weeks 1, 3, 4 — high. Mostly a speed pass.*
2. **Simple shell scripts** — conditionals, loops, script inputs, using
   command output. *Week 8 — high overlap.*
3. **Operate running systems** — boot/reboot, boot targets,
   **interrupt boot to reset root password** (new, guaranteed exam task),
   process priorities/kill, tuning profiles (tuned — new), journals incl.
   **persistent journald** (new-ish), systemd services, scp/sftp transfer.
4. **Local storage** — partitions, LVM, **LUKS-encrypted volumes mounted
   persistently at boot** (new combination), swap creation, fstab by
   UUID/label. *Weeks 2, 7 supply the parts; the persistent-LUKS assembly
   is new.*
5. **File systems** — ext4/xfs, **NFS client mounts + autofs** (new),
   LVM extend, **set-GID collaboration directories** (week-6 permission
   theory, applied), diagnosing permission issues.
6. **Deploy/configure/maintain** — at/cron, default target, **chrony time
   sync** (new), dnf incl. **module streams** (new, RHEL-specific), local
   repos, bootloader modification.
7. **Basic networking** — nmcli static config IPv4/**IPv6** (IPv6 config
   depth is new), hostname resolution, services at boot, firewalld
   restriction.
8. **Users and groups** — create/modify, aging, **sudo/superuser config**.
   *Week 4 + 6 — high overlap.*
9. **Security** — firewalld, default permissions/umask, key-based SSH,
   SELinux modes/contexts/booleans, **diagnose routine SELinux
   violations**. *Weeks 6, 7 — high overlap; RHCSA grades doing it fast.*
10. **Containers** — podman images (find/inspect/skopeo), rootless vs
    rootful, **containers as systemd services with persistent storage**
    (quadlet/generate — converges with roadmap M5!). *Week 6 + M5.*

**Net-new list (the real study surface):** boot interrupt/root reset,
tuned profiles, persistent LUKS at boot, NFS+autofs, module streams,
chrony, nmcli IPv6 depth, set-GID collab dirs, container-as-service.
Everything else is Linux+ material at higher speed under reboot-survival
discipline.

## Bootstrap Instructions (for the session that builds this out)

1. Verify current EX200 objectives against Red Hat's page; correct the
   list above in place.
2. Replicate the linuxplus architecture in this directory:
   `curriculum.md` (expand this seed) → `topic-map.md` (suggest 8-week
   sprint — the overlap is large; weight weeks toward the net-new list)
   → `study-protocol.md` (copy linuxplus version, change: labs run in the
   RHEL practice VMs, every lab task ends with a reboot-survival check,
   and test-outs are TASK-based, not question-based — "here are 6 tasks,
   45 minutes, system must survive reboot" — matching the exam format).
3. Build a question/task bank the same way test-out-bank.md was built,
   but as gradeable task lists with verification commands per task.
4. First lab is always: build the two practice VMs with virt-install
   (week-03 stretch goal, now load-bearing) and snapshot them clean —
   every session starts from snapshot, breaks freely, reverts.
