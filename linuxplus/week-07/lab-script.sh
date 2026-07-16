#!/bin/bash
# Week 07 — Auth/Accounting + Account Hardening + Crypto + Compliance
# Objectives: 3.1, 3.4, 3.5, 3.6
# Run on: tp-mudd only — fully self-contained, no other devices required
# Estimated time: 45–60 min (Tasks 8 and 9 are optional stretches)
#
# Creates a throwaway GPG keypair and a LUKS2 loop device; both are destroyed
# in their own cleanup steps. The auditd rule added in Task 2 is runtime-only
# and removed in the same task.

DRY_RUN=true  # Set to false to execute. true echoes commands instead of running them.

run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

SCRATCH="/tmp/week07"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 07 Lab — Auth + Hardening + Crypto + Compliance"
echo "  Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN"
echo "════════════════════════════════════════════════════════"
echo ""

run_cmd "mkdir -p $SCRATCH && chmod 700 $SCRATCH"

# ── TASK 1: Read the PAM Stack You Log In Through ─────────────────────────────
# Why it matters: Objective 3.1 — every sudo you've typed this sprint walked
# this exact stack. Read it once with the four types and four controls in hand.
echo "── TASK 1: PAM ──"

echo ""
echo "[1a] One file per service — find the ones you use daily:"
run_cmd "ls /etc/pam.d/ | head -15"

echo ""
echo "[1b] The sudo stack — identify each line's TYPE and CONTROL as you read:"
run_cmd "cat /etc/pam.d/sudo"

echo ""
echo "[1c] It includes system-auth — the shared stack. Find one 'required', one"
echo "     'sufficient', and where pam_faillock sits relative to pam_unix:"
run_cmd "grep -E 'required|requisite|sufficient' /etc/pam.d/system-auth"

echo ""
echo "[1d] Fedora generates these files — prove you shouldn't hand-edit them:"
run_cmd "authselect current"

echo ""
echo "[1e] Account-hardening knobs, all three files:"
run_cmd "grep -E '^(PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE)' /etc/login.defs"
run_cmd "grep -vE '^\s*#|^\s*$' /etc/security/pwquality.conf || echo '  (all defaults — minlen etc. documented in the commented lines)'"
run_cmd "grep -vE '^\s*#|^\s*$' /etc/security/faillock.conf || echo '  (all defaults: deny=3, unlock_time=600 per the comments)'"
run_cmd "faillock --user \$USER"
echo "  ^ faillock is pam_tally2's living successor — the exam may use the old name."

echo ""
echo "[1f] Restricted shell — try to escape rbash (PREDICT each result):"
run_cmd "bash -r -c 'cd /tmp' 2>&1 || true"
run_cmd "bash -r -c 'echo data > /tmp/x' 2>&1 || true"
echo "  ^ no cd, no output redirection. Containment for a usable account —"
echo "  vs /sbin/nologin (Week 4), which denies the session entirely."

echo ""

# ── TASK 2: auditd — Watch a File, Catch the Change ───────────────────────────
# Why it matters: Objective 3.1 — the watch-trigger-search cycle is auditd in
# one motion, and /etc/passwd is the canonical thing to watch.
echo "── TASK 2: auditd Watch Rule ──"

echo ""
echo "[2a] Daemon state and current rules:"
run_cmd "systemctl is-active auditd"
run_cmd "sudo auditctl -l"

echo ""
echo "[2b] Watch /etc/passwd for writes and attribute changes, tagged for retrieval:"
run_cmd "sudo auditctl -w /etc/passwd -p wa -k week07-passwd"
run_cmd "sudo auditctl -l | grep week07"

echo ""
echo "[2c] Trigger it legitimately — usermod writes /etc/passwd (GECOS change on you):"
run_cmd "sudo usermod -c 'Dillon' \$USER"

echo ""
echo "[2d] The kernel saw it — find the event, read WHO (auid) did WHAT (exe):"
run_cmd "sudo ausearch -k week07-passwd --format text 2>/dev/null | tail -4 || sudo ausearch -k week07-passwd | tail -12"
echo "  ^ auid = the AUDIT uid: who you logged in as originally, surviving sudo."
echo "  That attribution is the 'accounting' in AAA."

echo ""
echo "[2e] The aggregate view, then remove the rule (runtime-only, like firewalld):"
run_cmd "sudo aureport --summary 2>/dev/null | head -12"
run_cmd "sudo auditctl -W /etc/passwd -p wa -k week07-passwd && sudo auditctl -l"
echo "  Persistence would mean a file in /etc/audit/rules.d/ — deliberately not done."

echo ""

# ── TASK 3: Logging Plumbing — journald, rsyslog, logrotate ──────────────────
# Why it matters: Objective 3.1 — know which layer owns what, and read a
# logrotate config before the exam asks what 'rotate 4' means.
echo "── TASK 3: Logging ──"

echo ""
echo "[3a] Which loggers exist on this host? (PREDICT: is rsyslog even installed?)"
run_cmd "systemctl is-active systemd-journald"
run_cmd "systemctl is-active rsyslog 2>/dev/null || echo '  rsyslog not active — Fedora is journald-native; rsyslog is the text-file + central-forwarding layer you ADD'"

echo ""
echo "[3b] What logrotate manages here, and one real config decoded:"
run_cmd "ls /etc/logrotate.d/ | head -8"
run_cmd "grep -vE '^\s*#|^\s*$' /etc/logrotate.conf | head -10"

echo ""
echo "[3c] Dry-run the rotation logic — see decisions without touching a file:"
run_cmd "sudo logrotate -d /etc/logrotate.conf 2>&1 | grep -E 'considering|rotating|log does not' | head -8"

echo ""

# ── TASK 4: GPG — Encrypt, Decrypt, Sign, Verify, TAMPER ──────────────────────
# Why it matters: Objective 3.5 — the public/private role split only sticks
# once you've done all four operations and watched verification catch a forgery.
echo "── TASK 4: GPG Lifecycle ──"

echo ""
echo "[4a] Throwaway keypair (no passphrase — lab-grade only, never for real keys):"
run_cmd "gpg --batch --passphrase '' --quick-generate-key 'Week07 Lab <week07@lab.local>' default default never 2>&1 | tail -2"
run_cmd "gpg --list-keys week07@lab.local"

echo ""
echo "[4b] Encrypt a secret TO yourself (in real use: TO the recipient's public key):"
run_cmd "echo 'the muddroom launch codes' > $SCRATCH/secret.txt"
run_cmd "gpg -e -r week07@lab.local --output $SCRATCH/secret.gpg $SCRATCH/secret.txt"
run_cmd "file $SCRATCH/secret.gpg && grep -c 'launch' $SCRATCH/secret.gpg || echo '  plaintext not found in ciphertext — as it should be'"

echo ""
echo "[4c] Decrypt with your PRIVATE key:"
run_cmd "gpg -d -q $SCRATCH/secret.gpg"

echo ""
echo "[4d] Sign (YOUR private key), verify (your public key):"
run_cmd "gpg --batch --detach-sign --output $SCRATCH/secret.sig $SCRATCH/secret.txt"
run_cmd "gpg --verify $SCRATCH/secret.sig $SCRATCH/secret.txt 2>&1 | grep -E 'Good|BAD'"

echo ""
echo "[4e] NOW TAMPER — one byte changes, verification must fail:"
run_cmd "echo ' ' >> $SCRATCH/secret.txt"
run_cmd "gpg --verify $SCRATCH/secret.sig $SCRATCH/secret.txt 2>&1 | grep -E 'Good|BAD'"
echo "  ^ BAD signature = integrity AND origin protection in one mechanism."

echo ""
echo "[4f] Key cleanup — delete secret then public:"
run_cmd "FPR=\$(gpg --list-keys --with-colons week07@lab.local | awk -F: '/^fpr/{print \$10; exit}'); gpg --batch --yes --delete-secret-and-public-key \$FPR && echo '  keypair destroyed'"

echo ""

# ── TASK 5: Hash vs HMAC vs TLS — and the System Crypto Policy ────────────────
# Why it matters: Objective 3.5 — three integrity mechanisms, one distinction
# each; plus Fedora's one-command answer to 'remove weak algorithms'.
echo "── TASK 5: Hashing + Transit Crypto ──"

echo ""
echo "[5a] SHA-256 — one byte flips, the fingerprint changes completely:"
run_cmd "echo 'version 1' > $SCRATCH/hash.txt && sha256sum $SCRATCH/hash.txt"
run_cmd "echo 'version 2' > $SCRATCH/hash.txt && sha256sum $SCRATCH/hash.txt"

echo ""
echo "[5b] HMAC — same hash, now keyed. Different secret = different MAC:"
run_cmd "openssl dgst -sha256 -hmac 'secret-key-1' $SCRATCH/hash.txt"
run_cmd "openssl dgst -sha256 -hmac 'secret-key-2' $SCRATCH/hash.txt"
echo "  ^ hash proves content; HMAC proves content + possession of the key."

echo ""
echo "[5c] Watch a real TLS negotiation (public internet target, no homelab devices):"
run_cmd "echo | openssl s_client -connect anthropic.com:443 2>/dev/null | grep -E 'Protocol|Cipher' | head -3"
echo "  ^ expect TLSv1.3 — 1.0/1.1 are the 'weak' generation the objective bans."

echo ""
echo "[5d] The system-wide algorithm switch — Fedora's crypto-policies:"
run_cmd "update-crypto-policies --show"
echo "  ^ DEFAULT already excludes TLS<1.2, SHA-1 signatures, small keys. LEGACY"
echo "  loosens for old peers; FUTURE/FIPS tighten. One knob, whole OS."

echo ""
echo "[5e] WireGuard is not hypothetical here — it's your mesh's transport:"
run_cmd "lsmod | grep wireguard || tailscale status --peers=false 2>/dev/null | head -2 || echo '  (tailscaled runs userspace-wireguard if the module is absent)'"

echo ""

# ── TASK 6: LUKS2 on a Loop Device — Full Data-at-Rest Lifecycle ──────────────
# Why it matters: Objective 3.5 — encrypt, unlock, use, lock, PROVE the
# ciphertext, manage key slots, and finish with cryptographic destruction
# (3.6's secure-erase answer for the SSD era). Zero risk: the 'disk' is a file.
echo "── TASK 6: LUKS2 ──"

echo ""
echo "[6a] A 100MB 'disk' and a passphrase file (lab-grade handling):"
run_cmd "dd if=/dev/zero of=$SCRATCH/crypt.img bs=1M count=100 status=none && sudo losetup -f $SCRATCH/crypt.img"
run_cmd "CDEV=\$(losetup -j $SCRATCH/crypt.img | cut -d: -f1); echo \"device: \$CDEV\""
run_cmd "printf 'week07-passphrase' > $SCRATCH/pass1 && chmod 600 $SCRATCH/pass1"

echo ""
echo "[6b] Encrypt it (luksFormat DESTROYS existing contents — the warning is real):"
run_cmd "sudo cryptsetup luksFormat --type luks2 --batch-mode \$(losetup -j $SCRATCH/crypt.img | cut -d: -f1) $SCRATCH/pass1"

echo ""
echo "[6c] Read the header — cipher, Argon2 KDF, key slots (1 of 32 used):"
run_cmd "sudo cryptsetup luksDump \$(losetup -j $SCRATCH/crypt.img | cut -d: -f1) | grep -E 'Version|cipher|PBKDF|Keyslots|luks2' | head -8"

echo ""
echo "[6d] Unlock -> filesystem -> mount -> write a secret -> lock:"
run_cmd "sudo cryptsetup open \$(losetup -j $SCRATCH/crypt.img | cut -d: -f1) week07crypt --key-file $SCRATCH/pass1"
run_cmd "sudo mkfs.ext4 -q /dev/mapper/week07crypt && sudo mkdir -p /mnt/week07 && sudo mount /dev/mapper/week07crypt /mnt/week07"
run_cmd "echo 'top secret payload' | sudo tee /mnt/week07/secret.txt >/dev/null && ls -l /mnt/week07/"
run_cmd "sudo umount /mnt/week07 && sudo cryptsetup close week07crypt"

echo ""
echo "[6e] PROVE it's ciphertext — search the raw device for your plaintext:"
run_cmd "sudo grep -a 'top secret' \$(losetup -j $SCRATCH/crypt.img | cut -d: -f1) || echo '  not found: every block on the device is ciphertext'"

echo ""
echo "[6f] Key slots — add a second key (recovery key pattern), see slot 1 fill:"
run_cmd "dd if=/dev/urandom of=$SCRATCH/recovery.key bs=64 count=1 status=none && chmod 600 $SCRATCH/recovery.key"
run_cmd "sudo cryptsetup luksAddKey \$(losetup -j $SCRATCH/crypt.img | cut -d: -f1) $SCRATCH/recovery.key --key-file $SCRATCH/pass1"
run_cmd "sudo cryptsetup luksDump \$(losetup -j $SCRATCH/crypt.img | cut -d: -f1) | grep -A1 'Keyslots'"
echo "  Production rule you'd apply next: luksHeaderBackup — lose the header, lose it all."

echo ""
echo "[6g] CRYPTOGRAPHIC DESTRUCTION — erase the key slots; data is gone forever"
echo "     even though 100MB of ciphertext still sits right there:"
run_cmd "sudo cryptsetup erase --batch-mode \$(losetup -j $SCRATCH/crypt.img | cut -d: -f1)"
run_cmd "sudo cryptsetup open \$(losetup -j $SCRATCH/crypt.img | cut -d: -f1) week07crypt --key-file $SCRATCH/pass1 2>&1 || echo '  ^ correct passphrase now USELESS — this is crypto-erase, the SSD-proof wipe'"

echo ""
echo "[6h] Teardown:"
run_cmd "sudo losetup -d \$(losetup -j $SCRATCH/crypt.img | cut -d: -f1) && rm -f $SCRATCH/crypt.img $SCRATCH/pass1 $SCRATCH/recovery.key && sudo rmdir /mnt/week07"

echo ""

# ── TASK 6b: Trigger an AVC Denial on Purpose + audit2allow ───────────────────
# Why it matters: Objectives 3.1 + 3.3 meet — you cause a confined-domain
# denial deliberately (the Week 6 no-:Z mistake), find it in the audit log,
# and read what audit2allow WOULD permit. Reading without applying is the skill.
echo "── TASK 6b: Deliberate AVC + audit2allow ──"

echo ""
echo "[6b-1] The trigger — bind mount WITHOUT :Z; container_t may not read user tmp files:"
run_cmd "mkdir -p $SCRATCH/avc && echo 'forbidden fruit' > $SCRATCH/avc/file.txt"
run_cmd "podman run --rm -v $SCRATCH/avc:/data:ro docker.io/library/alpine:latest cat /data/file.txt 2>&1 || echo '  ^ Permission denied — chmod would NOT fix this; the label is wrong, not the mode'"

echo ""
echo "[6b-2] Find the denial the kernel just logged:"
run_cmd "sudo ausearch -m AVC -ts recent 2>/dev/null | grep -E 'denied|comm=' | tail -4 || echo '  (no AVC found — some container-selinux versions silently remap; re-run 6b-1 with a file in ~ instead of /tmp)'"

echo ""
echo "[6b-3] What WOULD fix it, according to audit2allow — read, do NOT apply:"
run_cmd "sudo ausearch -m AVC -ts recent 2>/dev/null | audit2allow 2>/dev/null | head -8 || echo '  (audit2allow lives in policycoreutils-python-utils — install if missing)'"
echo "  ^ It generates an allow rule for EXACTLY what was denied. Blindly applying"
echo "  these is how SELinux gets hollowed out one denial at a time. The right fix"
echo "  here was :Z (correct labeling), not new policy. audit2allow output is a"
echo "  diagnosis to evaluate, not a patch to apply."
run_cmd "rm -rf $SCRATCH/avc"

echo ""

# ── TASK 7: Compliance Toolbox — shred, Backports, Banners ────────────────────
# Why it matters: Objective 3.6 — three small proofs: overwrite-deletion,
# the backported-patch reality that breaks version scanners, and banner files.
echo "── TASK 7: Compliance Odds and Ends ──"

echo ""
echo "[7a] shred — overwrite then unlink (and why it's not enough on this laptop):"
run_cmd "echo 'sensitive' > $SCRATCH/shredme.txt && shred -vu -n 3 $SCRATCH/shredme.txt 2>&1 | tail -4"
echo "  ^ On btrfs (CoW) and SSDs, overwrites may land on NEW physical blocks —"
echo "  shred can't guarantee the old ones died. Task 6g is the modern answer."

echo ""
echo "[7b] Backported patches — the version number lies; the changelog doesn't:"
run_cmd "rpm -q openssh-server"
run_cmd "rpm -q --changelog openssh-server | grep -i CVE | head -5"
echo "  ^ CVEs fixed WITHOUT a version bump. A scanner matching versions alone"
echo "  would flag this host as vulnerable. That's the backporting question."

echo ""
echo "[7c] Signed-package supply chain — the keys dnf trusts (Week 5 tie-in):"
run_cmd "rpm -q gpg-pubkey --qf '%{name}-%{version} %{summary}\n' | head -4"

echo ""
echo "[7d] Banners — which file shows when:"
run_cmd "cat /etc/issue"
run_cmd "cat /etc/motd 2>/dev/null || echo '  (motd empty)'"
run_cmd "sudo sshd -T 2>/dev/null | grep -i '^banner' || echo '  banner none — issue.net is not wired to sshd here'"

echo ""

# ── TASK 8 (OPTIONAL): AIDE — File Integrity Baseline ─────────────────────────
# Why it matters: Objective 3.6 — build the database, change a file, catch it.
# The init scan takes several minutes; start it and take a break.
echo "── TASK 8 (OPTIONAL): AIDE ──"

echo ""
echo "[8a] Install, initialize (slow — hashes large parts of the filesystem):"
run_cmd "sudo dnf install -y aide >/dev/null && sudo aide --init 2>&1 | tail -2"
run_cmd "sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz"

echo ""
echo "[8b] Change something it watches, then catch it:"
run_cmd "sudo touch /etc/week07-aide-canary"
run_cmd "sudo aide --check 2>&1 | grep -A3 'added entries' | head -6"
run_cmd "sudo rm /etc/week07-aide-canary"
echo "  (Real usage: re-run --init after intentional changes, store the DB"
echo "   off-host — an attacker who can edit files can edit the database too.)"

echo ""

# ── TASK 9 (OPTIONAL): OpenSCAP — Scan This Laptop Against CIS ────────────────
# Why it matters: Objective 3.6 — an actual compliance scan of tp-mudd,
# producing the HTML report format the objective describes.
echo "── TASK 9 (OPTIONAL): OpenSCAP ──"

echo ""
echo "[9a] Install scanner + content, list available profiles:"
run_cmd "sudo dnf install -y openscap-scanner scap-security-guide >/dev/null"
run_cmd "oscap info /usr/share/xml/scap/ssg/content/ssg-fedora-ds.xml 2>/dev/null | grep -A1 'Profiles' | head -8"

echo ""
echo "[9b] Evaluate against a CIS-derived profile, HTML report out:"
run_cmd "oscap xccdf eval --profile cis_workstation_l1 --report $SCRATCH/scap-report.html /usr/share/xml/scap/ssg/content/ssg-fedora-ds.xml 2>/dev/null | tail -5; echo \"  report: $SCRATCH/scap-report.html — open it, read three failures, decide if you AGREE\""
echo "  (Benchmarks are recommendations, not law — e.g. it may want password-auth"
echo "  rules this key-only laptop deliberately doesn't need. Reasoned exceptions"
echo "  ARE compliance work.)"

echo ""

# ── CLEANUP CHECK ─────────────────────────────────────────────────────────────
echo "── Cleanup Check ──"
echo "  sudo auditctl -l                       # no week07 rules"
echo "  gpg --list-keys week07@lab.local       # no such key"
echo "  losetup -a | grep week07               # nothing"
echo "  keep or delete: $SCRATCH (scap report lives there)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Week 07 Lab Complete"
echo ""
echo "  Practiced (all on tp-mudd):"
echo "  ✓ PAM stack read with types+controls; authselect; faillock; rbash escapes denied"
echo "  ✓ auditd watch rule: set, triggered via usermod, retrieved by key, removed"
echo "  ✓ journald/rsyslog division of labor; logrotate config + dry run"
echo "  ✓ GPG all four operations + tampered signature caught"
echo "  ✓ SHA-256 vs HMAC distinction; live TLS 1.3 negotiation; crypto-policies"
echo "  ✓ LUKS2 full lifecycle on a loop device + key slots + CRYPTO-ERASE finale"
echo "  ✓ AVC denial triggered on purpose; audit2allow read and deliberately NOT applied"
echo "  ✓ shred (and its SSD/CoW limits); backported-CVE changelog proof; banners"
echo "  ✓ (optional) AIDE baseline catching a planted file; OpenSCAP CIS scan of this host"
echo ""
echo "  Objectives covered: 3.1, 3.4, 3.5, 3.6"
echo "════════════════════════════════════════════════════════"
