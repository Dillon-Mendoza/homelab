# Troubleshooting: muddcloud Exit Node and SSH Lockout
**Date:** 2026-05-03  
**Device:** muddcloud (Oracle Cloud VM)  
**Issues:** (1) Exit node not routing traffic, (2) SSH lockout after user migration  
**Status:** Exit node resolved. SSH access unresolved.
 
---
 
## Issue 1: Exit Node Not Routing Traffic
 
### Symptom
 
```bash
sudo tailscale set --exit-node=muddcloud
curl https://ifconfig.me
# Returned home IP instead of Oracle IP
```
 
Tailscale routing table confirmed exit node was set and muddcloud was an active peer.
 
---
 
### Diagnostic Steps
 
**Check if muddcloud is a reachable peer:**
```bash
tailscale status | grep muddcloud
# active; exit node; direct <ORACLE-PUBLIC-IP>:41641 ← peer active
```
 
**Check IP forwarding on muddcloud:**
```bash
sysctl net.ipv4.ip_forward
# net.ipv4.ip_forward = 1 ← forwarding enabled
```
 
**Check exit node advertisement:**
```bash
sudo tailscale status | grep "exit node"
# idle; offers exit node ← advertising correctly
```
 
**Check active exit node status on ThinkPad:**
```bash
tailscale status --json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ExitNodeStatus'))"
```
 
**Check Tailscale routing table:**
```bash
ip route show table 52
# default dev tailscale0 ← traffic going through Tailscale
# <TAILSCALE-IP> dev tailscale0 ← muddcloud peer present
```
 
---
 
### Fixes Applied
 
**Fix 1 — Oracle Security List missing UDP 41641**
 
Oracle's default ingress only allows TCP 22. Tailscale requires UDP 41641 for its WireGuard tunnel.
 
Added ingress rule:
- Source: `0.0.0.0/0`
- Protocol: UDP (not TCP)
- Port: 41641
 
**Fix 2 — Tailscale DNS split configuration**
 
Required a split DNS entry in the Tailscale admin DNS settings for proper resolution when using the exit node.
 
**Fix 3 — Re-approve routes after retagging**
 
muddcloud was retagged from `tag:t2` to `tag:cloud`. Retagging clears all route approvals silently. Required re-approving the exit node in **Tailscale Admin → Machines → muddcloud → Edit route settings**.
 
> **Rule:** Any time you retag a device, immediately check Edit route settings and re-approve legitimate routes.
 
Oracle also advertises two internal routes that appear as unapproved:
- `xx.x.x.x/24` — Oracle VCN subnet
- `xxx.xxx.xxx.xxx/32` — Oracle instance metadata service
 
Do NOT approve these. Leave them unapproved.
 
---
 
### Root Cause of False Diagnosis
 
The core confusion was IPv4/IPv6 address family mismatch:
 
| Scenario | Result |
|---|---|
| ThinkPad, no exit node | `2600:387:15:3718::5` (home IPv6) |
| ThinkPad, muddcloud exit node | <ORACLE-PUBLIC-IP> (Oracle IPv4) |
| muddcloud itself | <ORACLE-PUBLIC-IP> (Oracle IPv4) |
 
<ORACLE-PUBLIC-IP> appeared in `tailscale status` as muddcloud's direct connection address, causing it to be mistaken for the home IP. The exit node was actually working the entire time.
 
**Always force `-4` when testing exit node routing:**
```bash
# Establish baseline without exit node
sudo tailscale set --exit-node=
curl -4 https://ifconfig.me   # home IPv4 baseline
 
# Test with exit node
sudo tailscale set --exit-node=muddcloud
curl -4 https://ifconfig.me   # should differ from baseline
```
 
---
 
## Issue 2: SSH Lockout After User Migration
 
### What happened
 
1. Created `mudd` user and added to sudo group ✓
2. Expired `ubuntu` user account ✓
3. Attempted SSH as `mudd` — permission denied (no authorized_keys) ✗
4. Attempted SSH as `ubuntu` — account expired ✗
5. Locked out of instance
 
### Why it happened
 
The `ubuntu` user was expired before copying its SSH authorized_keys to the `mudd` user. Both the new user (no keys) and the old user (expired) were now inaccessible via SSH.
 
### Recovery Attempts
 
**Tailscale SSH** — requires `--ssh` flag when running `tailscale up`. Was not enabled on muddcloud. Returned `Permission denied (publickey)` because it fell back to standard key auth.
 
**Oracle Cloud Shell** — browser terminal on Oracle's network, not inside the instance. No access to instance filesystem or private keys.
 
**Oracle Run Command** — requires "Compute Instance Run Command" plugin. Not supported on VM.Standard.E2.1.Micro shape.
 
**Oracle Bastion** — managed SSH jump service. Attempted multiple sessions with both generated and existing keys. All connections closed by remote host. Ubuntu account expiration likely blocking Bastion auth despite certificate-based approach.
 
**Oracle Console Connection** — not available in current Oracle UI layout for this account/shape.
 
### Current Status
 
SSH access unresolved. muddcloud continues to function as a Tailscale exit node. Cannot be accessed for maintenance.
 
### Prevention
 
Always run Tailscale with `--ssh` on cloud nodes:
```bash
sudo tailscale up --advertise-exit-node --ssh
```
 
Always follow this sequence when migrating users on a cloud VM:
 
```bash
# 1. Create new user
sudo adduser mudd
sudo usermod -aG sudo mudd
 
# 2. Copy SSH keys BEFORE touching the old user
sudo mkdir -p /home/mudd/.ssh
sudo cp /home/ubuntu/.ssh/authorized_keys /home/mudd/.ssh/
sudo chown -R mudd:mudd /home/mudd/.ssh
sudo chmod 700 /home/mudd/.ssh
sudo chmod 600 /home/mudd/.ssh/authorized_keys
 
# 3. Test in a NEW terminal window while keeping current session open
# ssh -i ~/.ssh/muddcloud.key mudd@161.153.55.136
 
# 4. Confirm sudo
sudo whoami   # must return: root
 
# 5. ONLY THEN expire old user
sudo usermod --expiredate 1 ubuntu
```
 
---
 
## Commands Reference
 
| Command | Purpose |
|---|---|
| `ip route show table 52` | Tailscale routing table — first diagnostic to run |
| `tailscale status \| grep muddcloud` | Check peer connection and exit node status |
| `sysctl net.ipv4.ip_forward` | Verify IP forwarding enabled on exit node |
| `sudo tailscale set --exit-node=NAME` | Set active exit node |
| `sudo tailscale set --exit-node=` | Remove exit node |
| `curl -4 https://ifconfig.me` | Get public IPv4 (always use -4 when testing exit nodes) |
| `curl -6 https://ifconfig.me` | Get public IPv6 |
| `ssh-keygen -y -f ~/.ssh/key.key` | Extract public key from existing private key |
| `sudo tailscale up --advertise-exit-node --ssh` | Bring up Tailscale with exit node and SSH enabled |
 
---
 
## Lessons Learned
 
1. Always use `curl -4` when testing exit nodes — mixed address families produce misleading results.
2. Oracle security lists block UDP 41641 by default — always add this rule for Tailscale.
3. Retagging a device clears route approvals — re-approve immediately after any tag change.
4. Oracle internal routes (`10.0.0.0/24`, `169.254.169.254/32`) appear as unapproved on every Oracle VM — never approve them.
5. Always enable `--ssh` when bringing Tailscale up on cloud nodes — it's your emergency access path.
6. Never expire the default cloud user until the new user is fully verified with SSH tested in a separate terminal.
7. VM.Standard.E2.1.Micro does not support Run Command or Console Connection — Tailscale SSH is your only recovery option if locked out.
 
---
 
*Filed under: homelab/troubleshooting/tailscale*