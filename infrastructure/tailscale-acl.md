# Tailscale ACL Architecture
*Mudd Labs | Last Updated: May 2026*

---

## Overview

The Mudd Labs Tailscale mesh runs a tiered default-deny ACL. No device can
reach another by default — all access is explicitly granted. The trust
hierarchy flows in one direction: downward. Higher-tier devices can reach
lower ones, but not the reverse.

The tier model was designed intentionally — access is granted based on the
role and trustworthiness of each device, not convenience.

---

## Device Tag Reference

| Tag | Device | Role |
|---|---|---|
| `tag:t0` | ThinkPad T14 | Primary dev machine — full mesh access |
| `tag:t1` | Dell Server (Ubuntu host + Fedora VM) | Service host — scoped downward access |
| `tag:t2` | Raspberry Pi 4 | Backup exit node, monitoring — limited downward access |
| `tag:t3` | Raspberry Pi Zero 2 W | Netdata node — no outbound access |
| `tag:cloud` | Oracle Cloud VM (muddcloud) | Primary exit node — internet routing only |
| `tag:parked` | Desktop (Win11) | Inactive — no access granted |
| `tag:guest` | Guest devices | Gitea read access only |

---

## Trust Hierarchy

```
tag:t0  →  entire mesh (unrestricted)
tag:t1  →  tag:t2, tag:t3, tag:parked, tag:guest
tag:t2  →  tag:t3, tag:parked, tag:guest
tag:t3  →  nothing
tag:cloud  →  nothing (exit node only)
tag:parked  →  nothing (default-deny, devices inactive)
tag:guest  →  tag:t1 tcp:3000 only (Gitea)
```

Traffic flows downward only. No device can initiate a connection to a
higher-tier device.

---

## Internet Access via Exit Node

`autogroup:internet` controls which devices can route traffic through an
exit node to reach the public internet. This is separate from mesh
peer-to-peer access — a device can be on the mesh and still be blocked
from internet routing without this grant.

The following tags are permitted internet routing:

```json
{
    "src": ["tag:t0", "tag:t1", "tag:t2", "tag:t3", "tag:cloud"],
    "dst": ["autogroup:internet"],
    "ip":  ["*"],
}
```

`tag:guest` and `tag:parked` are intentionally excluded. Guest devices
have no legitimate need to route internet traffic through the exit node.
If a specific device requires this capability, a dedicated rule will be
added for that device only.

---

## SSH Access

Tailscale SSH is configured separately from peer grants. It allows SSH
using Tailscale hostnames instead of IP addresses.

```json
{
    "action": "accept",
    "src":    ["tag:t0"],
    "dst":    ["tag:t1", "tag:t2", "tag:t3", "tag:parked", "tag:guest", "tag:cloud"],
    "users":  ["mudd", "mudd-fedora"],
},
```

Only `tag:t0` (ThinkPad) can initiate SSH to any other device on the mesh.

---

## Full ACL

```json
"grants": [
    {
        "src": ["tag:t0"],
        "dst": ["*"],
        "ip":  ["*"],
    },
    {
        "src": ["tag:t1"],
        "dst": ["tag:t2", "tag:t3", "tag:parked", "tag:guest"],
        "ip":  ["*"],
    },
    {
        "src": ["tag:t2"],
        "dst": ["tag:t3", "tag:parked", "tag:guest"],
        "ip":  ["*"],
    },
    {
        "src": ["tag:t0", "tag:t1", "tag:t2", "tag:t3", "tag:cloud"],
        "dst": ["autogroup:internet"],
        "ip":  ["*"],
    },
    {
        "src": ["tag:guest"],
        "dst": ["tag:t1"],
        "ip":  ["tcp:3000"],
    },

    {
        "src": ["tag:cloud"],
		"dst": ["autogroup:internet"],
		"ip":  ["*"],
    }
],
"ssh": [
    {
        "action": "accept",
        "src":    ["tag:t0"],
        "dst":    ["tag:t1", "tag:t2", "tag:t3", "tag:parked", "tag:guest", "tag:cloud"],
        "users":  ["<PRIMARY-USER>", "<FEDORA-USER>"],
    },
],
```

---

## Known Issues

### tag:parked access scope
`tag:parked` currently relies on default-deny for isolation rather than
an explicit restrictive grant. The intended policy is `tag:t0` access only.
This will be tightened when the Desktop is brought back online.

---

## Design Decisions

- **Default-deny** — nothing is permitted unless explicitly granted. Safer
  baseline than allowlist pruning.
- **Unidirectional trust** — lower-tier devices cannot initiate connections
  upward. A compromised Pi cannot reach the ThinkPad or Dell Server.
- **Guest isolation** — guests can access Gitea on port 3000 only. No mesh
  visibility, no internet routing.
- **Exit node separation** — `tag:cloud` has no peer grants. It exists solely
  to route internet traffic. It cannot reach or be reached by other devices
  outside of that role.