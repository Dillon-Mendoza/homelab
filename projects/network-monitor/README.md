# MuddBuilt - Device Monitor Workflow
## Internal Homelab Documentation

---

## Overview

A hybrid n8n + bash workflow that monitors networked devices on a 15-minute schedule and delivers a Discord notification when a device becomes unreachable. Built and tested in the the Mudd Labs homelab as a repeatable client delivery template under the MuddBuilt Fiverr gig.

---

## Architecture

'''
Schedule Trigger (15 min)
            ↓
Execute Command Node
            ↓
    → sh /scripts/monitor.sh
            ↓
Code Node
    → Parse stdout, filter UNCONFIRMED lines, format for n8n
            ↓
HTTP Request Node
    → POST to Discord webhook
'''

---

## Infrastructure

- **n8n** - runnung as Docker container of Fedora KVM/QEMU VM (Dell Server 'tag:t1')
- **Docker image** - 'docker.n8n.io/n8nio/n8n1.111.0'
- **Network mode** - '--network host' (Required for Tailscale mesh access)
- **Script mount** - '/usr/loca/bin/muddbuilt' on host → '/scripts' in container (':z' SELinux flag)
- **Shell** - 'sh' (bash not available inside n8n container)
- **Tailsxale ACL** - 'tag:t1' dst updated to include 'tag:t1' and 'tag:cloud' for ICMP

---

## Docker Run Command

'''bash
docker rm -f n8n
docker run -d \
    --name n8n \
    --netowrk host \
    -e N8N_HOST=<TAILSCALE-IP> \
    -e N8N_PROTOCOL=HTTPS \
    -e WEBHOOK_URL=HTTPS://<TAILSCALE-IP> \
    -e N8N_DIAGNOSTICS_ENABLED=false \
    -e N8N_VERSION_NOTIFICATIONS_ENABLED=false \
    -e N8N_HIRING_BANNER_ENABLED=false \
    -e N8N_PERSONALIZATION_ENABLED=false \
    -v /home/<user>/.n8n:/home/node/.n8n:z \
    -v /var/log/n8n:/var/log/n8n:z \
    -v /usr/local/bin/muddbuilt:/scripts:z \
    --restart unless-stopped \
  docker.n8n.io/n8nio/n8n:1.111.0
'''

---

## Files

| File | Location (Host) | Location (Container) | Purpose |
|---|---|---|---|
| `monitor.sh` | `/usr/local/bin/muddbuilt/monitor.sh` | `/scripts/monitor.sh` | Ping check script |
| `client.conf` | `/usr/local/bin/muddbuilt/client.conf` | `/scripts/client.conf` | Device list |


### Permissions
'''bash
chmod +x /usr/local/bin/muddbuilt/monitor.sh
chmod 600 /usr/local/bin/muddbuilt/client.conf
'''

---

## monitor.sh

'''sh
#!/bin/sh

while IFS= read -r line; do
    device=$(echo $line | cut -d ',' -f 1)
    ip=$(echo $line | cut -d ',' -f 2)
    ping $ip -c 3 > /dev/null 2>&1
    if [$? -eq 0]; then
        echo "CONFIRMED | $device | $ip"
    else
        echo "UNCONFIRMED | $device | $ip"
    fi
done < /scripts/client.conf
'''

**Line by line:**
- `while IFS= read -r line` — reads `client.conf` line by line, preserving whitespace
- `cut -d ',' -f 1` — splits each line on the comma delimiter, returns field 1 (device name)
- `cut -d ',' -f 2` — returns field 2 (IP address)
- `ping $ip -c 3 > /dev/null 2>&1` — pings the IP 3 times, suppresses all output
- `$?` — captures ping's exit code (0 = success, non-zero = failure)
- `echo "CONFIRMED | $device | $ip"` — controlled stdout output for n8n to parse
---
 
## client.conf
 
```
device-name,xxx.xxx.xxx.xxx
device-name,xxx.xxx.xxx.xxx
```
 
- One device per line
- Comma-separated: `name,IP`
- No headers, no blank lines
- `chmod 600` — owner read/write only
---
 
## n8n Code Node
 
```javascript
let text = $input.first().json.stdout;
let split = text.split('\n');
let result = split.filter(line => line.includes('UNCONFIRMED'));
return result.map(line => ({ json: { message: line } }));
```
 
**Line by line:**
- Line 1 — creates the variable `text` from the Execute Command node's stdout output for manipulation
- Line 2 — splits the stdout string into an array of individual lines on the newline character
- Line 3 — passes each line through `line.includes('UNCONFIRMED')`, keeping only lines where that returns true
- Line 4 — reformats each filtered line into `{ json: { message: line } }`, the data structure n8n requires for downstream nodes
---
 
## Tailscale ACL Notes
 
ICMP is not implicitly allowed — it must be covered by an `"ip": ["*"]` rule. The following change was required to allow the Fedora VM to ping devices across the mesh:
 
```json
{
    "src": ["tag:t1"],
    "dst": ["tag:t1", "tag:t2", "tag:t3", "tag:parked", "tag:guest", "tag:cloud"],
    "ip":  ["*"],
}
```
 
`tag:t1` added to its own destination (peer-to-peer within tier), `tag:cloud` added for Oracle Cloud reachability.
 
---
 
## Known Constraints
 
- `bash` is not available inside the n8n Docker container — script must use `#!/bin/sh` and POSIX-compatible syntax
- `client.conf` path must be absolute (`/scripts/client.conf`) — relative paths fail due to n8n's working directory being outside the mount
- Script volume mount requires `:z` SELinux flag on Fedora host
---
 
## Open Items
 
- [ ] Push `monitor.sh` and `client.conf` to Gitea homelab repo
- [ ] Screenshot workflow and Discord notification for Fiverr gig gallery
- [ ] Write client delivery README
- [ ] Tiered upgrade path: persistent logging with timestamps and latency metadata
