# MuddBuilt — Device Monitor
## Client Delivery Rundown

---

## What You're Getting

A fully configured device monitoring system that runs on your network and sends a Discord notification the moment a device goes unreachable. Set it up once — it runs automatically from there.

**What's included:**
- Configured n8n workflow (Schedule → Monitor → Notify)
- Bash monitoring script (`monitor.sh`)
- Device configuration file (`client.conf`)
- Discord webhook integration
- Tested and verified in your environment

---

## How It Works

On a 15-minute schedule, the system pings every device in your configuration file. If a device responds — nothing happens. If a device is unreachable, you receive a Discord notification immediately identifying the device by name and IP address.

**Discord message format:**
```
UNCONFIRMED | device-name | xxx.xxx.xxx.xxx
```

---

## What You Need to Provide

Before setup begins, you'll need to supply the following via the Fiverr intake form:

1. **Device list** — name and IP address for every device you want monitored
2. **Environment details** — operating system, whether n8n is already installed, network type (local, VPN, cloud)
3. **Discord webhook URL** — generated from your Discord server settings

---

## Your Configuration File

Your devices are stored in a plain text file (`client.conf`) with one device per line:

```
Living Room NAS,192.168.1.50
Office Desktop,192.168.1.51
Security Camera Hub,192.168.1.52
```

**To add or remove a device** — edit this file. No changes to the workflow required.

**Important:** This file contains your device IPs. Permissions are set to owner read/write only (`chmod 600`). Do not share this file.

---

## Requirements

- **n8n** installed and accessible (self-hosted or cloud)
- **Linux-based host** for running the monitoring script (Ubuntu, Debian, Fedora, or similar)
- **Discord server** with webhook permissions
- Devices reachable by IP from the machine running the script

---

## What Gets Installed and Where

| File | Location | Purpose |
|---|---|---|
| `monitor.sh` | `/usr/local/bin/muddbuilt/` | Ping check script |
| `client.conf` | `/usr/local/bin/muddbuilt/` | Your device list |

The n8n workflow is imported directly into your n8n instance — no additional software required beyond what's listed above.

---

## Monitoring Interval

Default: every 15 minutes. This can be adjusted in the n8n Schedule Trigger node to any interval you prefer.

---

## Upgrade Path

The base gig covers monitoring and Discord notification. Future tiers include:

- **Persistent logging** — timestamped log file with full run history
- **Latency metadata** — response time tracked per device per run
- **Multi-channel alerting** — Slack, email, or SMS in addition to Discord

---

## Support

If a device is showing as unreachable and you believe it should be reachable, verify the following:

1. The IP address in `client.conf` is correct
2. The device is powered on and connected to the network
3. The machine running the script can reach the device (test with `ping <IP>` from the terminal)
4. No firewall rules are blocking ICMP (ping) traffic between the monitoring host and the target device