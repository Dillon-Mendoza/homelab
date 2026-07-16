# Week 07 — Reference Notes
# Objectives: 3.1, 3.4, 3.5, 3.6 | Calendar: Aug 10–16

---

## Exam Objective Mapping

**3.1 — Summarize authorization, authentication, and accounting methods**
- Auth frameworks: PAM, Polkit, SSSD/Winbind realm
- Directory services: LDAP, Kerberos, Samba
- Logging: `rsyslog`, `journalctl`, `logrotate`, `/var/log`
- System audit: `auditd`, `audit.rules`

**3.4 — Explain account hardening techniques and best practices**
- Password policy: complexity, length, expiration, history, reuse
- MFA concepts; breach list checking
- Restricted shells: `/sbin/nologin`, `/bin/rbash`
- `pam_tally2` (deprecated → pam_faillock); avoid running as root

**3.5 — Explain cryptographic concepts and technologies in a Linux environment**
- Data at rest: GPG, LUKS2, Argon2
- Data in transit: OpenSSL, WireGuard, LibreSSL, TLS versions
- Hashing: SHA-256, HMAC
- Certificates: trusted root CAs, Let's Encrypt, avoiding self-signed
- Remove weak algorithms

**3.6 — Explain the importance of compliance and audit procedures**
- Threat detection: anti-malware, IoC
- Vulnerability scanning: CVE, CVSS, backporting, misconfigs, port scanners, protocol analyzers
- OpenSCAP, CIS Benchmarks; AIDE, rkhunter, signed package verification
- Secure destruction: `shred`, `badblocks -w`, `dd urandom`, cryptographic destruction
- Software supply chain; banners: `/etc/issue`, `/etc/issue.net`, `/etc/motd`

---

## Key Man Pages

`man 5 pam.d` (or `man pam`) — the section defining the four types and four control values. Ten minutes here covers 3.1's most-tested table straight from the source.

`man auditctl` — the `-w`/`-p`/`-k` trio you used in the lab, plus `-W` for removal. Note the line stating rules are not persistent — the exam's runtime-vs-config pattern again.

`man cryptsetup` — enormous; read only `luksFormat`, `luksAddKey`, `luksDump`, `luksHeaderBackup`, and `erase`. The luksHeaderBackup paragraph is the "header is everything" warning in official words.

`man gpg` — skim OPERATIONS for `-e`/`-d`/`--detach-sign`/`--verify`. The EXAMPLES section near the bottom mirrors lab Task 4 almost exactly.

`man update-crypto-policies` — short, Fedora/RHEL-specific, and the cleanest statement of what DEFAULT/LEGACY/FUTURE/FIPS each permit. "Remove weak algorithms" as one page.

---

## Video Timestamps

**Theory Course (12hr — nGPK6YBbKpg):**
Four sections this week — "Authentication & Authorization" (3.1), "Account Hardening" (3.4), "Cryptography" (3.5), and "Compliance & Auditing" (3.6), the back half of the Domain 3 block. 3.5 and 3.6 are almost purely conceptual on the exam, which makes video an efficient format for them; 3.1's PAM section is worth watching twice.

**Labs Course (7hr — JXIaR23OdB8):**
Look for GPG and LUKS demo segments — they map to Tasks 4 and 6. If the LUKS demo uses a real spare partition, note that your loop-device version is identical in every command and safer. auditd rarely gets lab-course coverage; your Task 2 may be the only hands-on version you see anywhere.

---

## Book Reference — How Linux Works, 3rd Ed. (Ward)

**Ch. 7 — System Configuration (PAM section)**
The one solid book asset this week. Ward walks through what happens when login consults PAM — the stack as a *sequence of questions* rather than a config syntax. Read before Session A; it makes the required/requisite/sufficient table feel inevitable instead of arbitrary.

**Coverage gap, by design:** LUKS, GPG internals, auditd, and OpenSCAP are beyond the book's scope. This week the primary sources are the five man pages above — treat that as practice for the real skill of working from primary documentation. The exam objectives (curriculum.md) are the outline; the man pages are the text.

---

## Things That Trip People Up

**1. `required` vs `requisite` — both fail, different timing**
`requisite` failure stops the stack immediately; `required` failure is remembered but the remaining modules still run (hiding *which* check failed from an attacker). If a question emphasizes "processing stopped immediately," it's requisite; "authentication failed but all modules executed" is required.

**2. Encrypt with THEIR public key; sign with YOUR private key**
The two operations use opposite keys, and every GPG exam question is some costume over this fact. Decrypt = your private. Verify = their public. If you can fill that 2×2 grid cold, 3.5's GPG questions are free points.

**3. The LUKS header is the single point of total loss**
Passphrases unlock key slots; key slots unlock the master key; the master key lives in the header. Corrupt the header (or `cryptsetup erase` the slots, as in lab 6g) and the correct passphrase opens nothing, forever. Production discipline: `luksHeaderBackup` at creation, stored off-device. Exam angle in both directions — accidental loss = catastrophe; deliberate destruction = instant, SSD-proof sanitization.

**4. `shred` quietly stopped working when filesystems went CoW**
shred's guarantee assumes overwriting a file hits the same physical blocks. Journaled fs weaken it; btrfs (this laptop) and SSD wear-leveling break it outright. Modern answer: encrypt from day one, destroy the key at end-of-life ("cryptographic destruction" — the objective lists it by name). If the question mentions SSDs, overwrite-based answers are bait.

**5. Backported patches make version-matching scanners lie**
A distro fixes CVE-2026-X in openssh-9.6p1-5 without shipping 9.7. Scanner sees "9.6 = vulnerable"; `rpm -q --changelog openssh-server | grep CVE` sees the truth. The exam phrases it as "scan reports a patched system as vulnerable — why?" Backporting. Every time.

**6. pam_tally2 is on the objective list but not on your system**
It was replaced by pam_faillock (RHEL 8+/Fedora). Expect the exam to name either; expect real systems to have only faillock. Same for the concept pair: `faillock --user X` shows the counter, `--reset` clears the lockout — that command pair is the practical answer to "user locked out after failed attempts."

---

## Connect to the Homelab

The cryptography objective reads like this fleet's design document. Data in transit: every packet between your six devices rides **WireGuard** — Tailscale is a control plane over exactly the protocol objective 3.5 names — and your SSH-key-only posture is asymmetric crypto exercised dozens of times a day (key on disk = private half; `authorized_keys` fleet-wide = the public half distributed). Certificates: Tailscale Serve fetched **Let's Encrypt** certs for n8n and Muddroom, meaning you've already operated the free-CA workflow the objective contrasts with self-signed. The accounting layer is live here too: SELinux enforcing feeds auditd (Week 6's `ausearch -m AVC` and this week's watch rules are the same log), and `journalctl _COMM=sudo` closes the AAA loop with attribution. Two genuinely open items surfaced by this week's audit script: this laptop's disk carries the study system, homelab docs, and SSH keys to the entire fleet, but has no LUKS volume — data-at-rest is the one 3.5 technology not yet deployed here, worth a deliberate decision (it's an install-time choice, so the practical path is enabling it at the next Fedora reinstall). And the optional OpenSCAP scan makes `tp-mudd` the first formally benchmarked host in the fleet — read three failures, agree or write the reasoned exception; that judgment call is the actual skill 3.6 describes.
