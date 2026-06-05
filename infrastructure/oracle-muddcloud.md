# Setup Guide: Oracle Cloud Free Tier VM (muddcloud)
**Date:** 2026-05-03  
**Purpose:** Provision a permanent free cloud server as primary Tailscale exit node  
**Instance Name:** muddcloud  
**Region:** US West (Phoenix, Arizona) — us-phoenix-1  
**Status:** Complete — exit node functional, SSH access locked (see known issues)
 
---
 
## Why Oracle Cloud
 
Oracle Cloud Free Tier offers genuinely permanent free compute. The Always Free tier persists indefinitely as long as the account is active — not a 12 month trial like AWS. This makes it the correct choice for permanent homelab infrastructure.
 
---
 
## Instance Specs
 
| Property | Value |
|---|---|
| Shape | VM.Standard.E2.1.Micro |
| Tier | Always Free-eligible |
| vCPUs | 1 core OCPU (burstable — runs at 1/8 core baseline, bursts to full core) |
| RAM | 1 GB |
| Network | 0.48 Gbps |
| OS | Canonical Ubuntu 22.04 |
| Region | US West (Phoenix) — us-phoenix-1 |
| Tag | tag:cloud |
 
---
 
## Provisioning Steps
 
### 1. Create Oracle Cloud Account
 
Go to `https://cloud.oracle.com/free`. The $300 trial credit is a 30-day bonus — ignore it. Always Free services persist after the trial regardless.
 
### 2. Create the Instance
 
**Compute → Instances → Create Instance**
 
- **Image:** Canonical Ubuntu 22.04
- **Shape:** VM.Standard.E2.1.Micro — confirm "Always Free-eligible" badge
- **SSH Keys:** Paste existing public key or generate new keypair during setup
 
### 3. Assign a Public IP
 
Oracle does not assign a public IP by default.
 
**Networking → Virtual Cloud Networks → your VCN → Subnets → Connect public subnet to internet**
 
Follow the prompts. This attaches an internet gateway to your VCN.
 
Then: **Instance details → Attached VNICs → IPv4 Addresses → Edit → Assign ephemeral public IP**
 
> **Note:** Ephemeral IPs change if the instance is stopped. Reserve a static public IP (free on Oracle) for long-term stability.
 
### 4. Configure Security List
 
**Networking → Virtual Cloud Networks → your VCN → Security Lists**
 
Add ingress rule for Tailscale:
 
| Field | Value |
|---|---|
| Stateless | No |
| Source | 0.0.0.0/0 |
| IP Protocol | **UDP** — not TCP |
| Destination Port | 41641 |
| Description | Tailscale |
 
Confirm default egress rule (`0.0.0.0/0, All Protocols`) exists.
 
---
 
## SSH Key Management
 
```bash
# Move private key to .ssh directory
mv ~/Downloads/your-key.key ~/.ssh/muddcloud.key
chmod 600 ~/.ssh/muddcloud.key
 
# If you only have the private key and need to recover the public key
ssh-keygen -y -f ~/.ssh/muddcloud.key
```
 
Add to SSH config for convenience:
 
```
Host muddcloud
    HostName <PUBLIC-IP>
    User mudd
    IdentityFile ~/.ssh/muddcloud.key
```
 
Then connect with: `ssh muddcloud`
 
---
 
## User Setup
 
### CRITICAL: Do this before expiring the default user
 
```bash
# 1. Create new user
sudo adduser mudd
sudo usermod -aG sudo mudd
 
# 2. Copy SSH keys to new user
sudo mkdir -p /home/mudd/.ssh
sudo cp /home/ubuntu/.ssh/authorized_keys /home/mudd/.ssh/
sudo chown -R mudd:mudd /home/mudd/.ssh
sudo chmod 700 /home/mudd/.ssh
sudo chmod 600 /home/mudd/.ssh/authorized_keys
 
# 3. Test SSH as new user in a NEW terminal window — keep current session open
# ssh -i ~/.ssh/muddcloud.key mudd@161.153.55.136
 
# 4. Confirm sudo works
sudo whoami
# should return: root
 
# 5. ONLY NOW expire the default user
sudo usermod --expiredate 1 ubuntu
```
 
> **Hard rule:** Never expire the default cloud user until the new user is fully verified — SSH key copied, login tested, sudo confirmed. Expiring ubuntu before copying keys locks you out permanently on the free tier.
 
---
 
## Tailscale Installation and Exit Node Setup
 
### Install Tailscale
 
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```
 
### Enable IP Forwarding
 
Run this on muddcloud only — not on client devices like the ThinkPad:
 
```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```
 
### Advertise as Exit Node and Enable Tailscale SSH
 
```bash
sudo tailscale up --advertise-exit-node --ssh
```
 
> **Note:** `--ssh` enables Tailscale SSH which bypasses traditional key auth. Essential for emergency access if normal SSH breaks.
 
### Approve in Tailscale Admin Console
 
**Tailscale Admin → Machines → muddcloud → Edit route settings → approve exit node**
 
> **Note:** Re-tagging a device clears route approvals. Re-approve after any tag change.
 
---
 
## Tailscale ACL Updates
 
Add to `tagOwners`:
```json
"tag:cloud": ["autogroup:admin"],
```
 
Add to SSH rules:
```json
{
    "action": "accept",
    "src":    ["tag:t0"],
    "dst":    ["tag:t1", "tag:t2", "tag:t3", "tag:parked", "tag:guest", "tag:cloud"],
    "users":  ["mudd", "mudd-fedora"],
},
```
 
The `autogroup:internet` grant covers muddcloud via the existing rule — no additional grant needed.
 
---
 
## Verification
 
```bash
# Confirm muddcloud's actual public IP (run on muddcloud with no exit node set)
sudo tailscale set --exit-node=
curl https://ifconfig.me
# Should return 161.153.55.136
 
# Confirm ThinkPad routing through muddcloud
sudo tailscale set --exit-node=muddcloud
curl -4 https://ifconfig.me
# Should return 161.153.55.136 (Oracle Phoenix IP)
 
# Remove and compare to home IP
sudo tailscale set --exit-node=
curl -4 https://ifconfig.me   # home IPv4
curl -6 https://ifconfig.me   # home IPv6
```
 
---
 
## Network Architecture
 
```
ThinkPad (on untrusted networks)
    └── Primary exit node: muddcloud (Oracle Phoenix)
    └── Backup exit node: muddpi / Pi 4
 
Home devices (Dell, Inspiron, Pi Zero)
    └── No exit node — route directly through home router
    └── Pi 4 exit node available if needed
```
 
---
 
## Known Issues
 
### SSH Access Locked
 
During initial setup the `ubuntu` user was expired before copying SSH keys to the `mudd` user. This locked out all SSH access. The VM.Standard.E2.1.Micro shape does not support Oracle's Console Connection or Run Command plugins, leaving no remote recovery path outside of Oracle Bastion.
 
**Current state:** muddcloud is functional as a Tailscale exit node but cannot be accessed via SSH for maintenance.
 
**Resolution options:**
1. Leave as-is — continues working as exit node until something requires maintenance
2. Terminate and rebuild — free tier availability in Phoenix not guaranteed
3. Upgrade to paid tier temporarily — unlocks Console Connection for recovery
 
**Prevention:** Always run `--ssh` flag when bringing Tailscale up on cloud nodes. Tailscale SSH uses Tailscale identity auth and bypasses traditional SSH keys — emergency access even if key auth breaks.
 
---
 
## E2.1.Micro Plugin Limitations
 
The following Oracle Cloud Agent plugins are NOT supported on VM.Standard.E2.1.Micro:
- Custom Logs Monitoring
- Compute Instance Run Command
 
This means remote script execution via the Oracle console is unavailable on this shape. Plan accordingly — Tailscale SSH is your emergency access path.
 
---
 
*Filed under: homelab/infrastructure/oracle-muddcloud.md
 
