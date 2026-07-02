# Tailscale ACL Update — tag:dns Addition and tag:t3 Cleanup
**Date:** July 2026
**Scope:** ACL restructure to support Pi-hole DNS node on Pi Zero 2W

---

## Summary of Changes

Two categories of changes were made in this update:

1. **Added `tag:dns`** — a new purpose-built tag for the Pi Zero 2W running
   Pi-hole, with a narrow, explicitly scoped ruleset
2. **Removed `tag:t3`** — a previously planned tag that was never implemented,
   cleaned from all locations it had been referenced

---

## Why tag:dns Instead of Reusing an Existing Tag

The Pi Zero 2W was previously untagged (default deny, no defined role).
Rather than assigning it to an existing tier or creating a patchy fix,
`tag:dns` was created as a dedicated tag — same rationale as `tag:cloud`.

Purpose-built tags make the ACL readable as documentation, not just access
control. The ruleset is narrow, the role is defined, and troubleshooting has
a clean starting point.

---

## tag:dns Ruleset

### tagOwners
```json
"tag:dns": ["autogroup:admin"]  // Pi Zero 2W — dedicated Pi-hole DNS node
```

### Grants

**Inbound DNS from active mesh tiers:**
```json
{
    "src": ["tag:t0", "tag:t1", "tag:t2", "tag:cloud"],
    "dst": ["tag:dns"],
    "ip":  ["tcp:53", "udp:53"]
}
```
Only active, working tiers granted DNS access. `tag:parked` and `tag:guest`
excluded intentionally — parked devices have no defined use case, guest
devices are lower trust and don't need access to the internal resolver.

**Admin UI access (ThinkPad only):**
```json
{
    "src": ["tag:t0"],
    "dst": ["tag:dns"],
    "ip":  ["tcp:80"]
}
```
Pi-hole admin UI locked to management tier only. Not exposed to the full mesh.

**Internet egress for upstream resolution:**
```json
{
    "src": ["tag:dns"],
    "dst": ["autogroup:internet"],
    "ip":  ["*"]
}
```
Pi-hole needs to reach upstream resolvers (Cloudflare 1.1.1.1) to answer
queries. Separate grant from the inbound DNS rule — two distinct journeys.

### SSH Access
`tag:dns` added to the `tag:t0` SSH accept block only:
```json
{
    "action": "accept",
    "src":    ["tag:t0"],
    "dst":    ["tag:t1", "tag:t2", "tag:dns", "tag:parked", "tag:guest", "tag:cloud"],
    "users":  ["mudd", "mudd-fedora"]
}
```
SSH to `tag:dns` from `tag:t0` only. Consistent with the principle that
every access grant is narrow and intentional.

---

## tag:t3 Cleanup

`tag:t3` was a previously planned tier for the Pi Zero 2W that was never
implemented in `tagOwners`. It existed only as references in grants and SSH
rules. With the Pi Zero now carrying `tag:dns`, all `tag:t3` references were
removed.

**Locations cleaned:**

| Location | Change |
|----------|--------|
| Tier 1 grant `dst` array | Removed `tag:t3` |
| Tier 2 grant `dst` array | Removed `tag:t3` (left only `tag:parked`, `tag:guest`) |
| Exit node grant `src` array | Replaced `tag:t3` with `tag:dns` |
| SSH block — `tag:t0` dst | Replaced `tag:t3` with `tag:dns` |
| SSH block — `tag:t1` dst | Removed `tag:t3` |
| SSH block — `tag:t2` dst | Removed entirely; replaced with comment |
| Tier 3 comment in grants | Removed |

**Lesson:** A tag rename must be treated as a global find-and-replace across
the entire ACL file, not a targeted edit. Referencing an undefined tag in a
grant does not fail silently in all cases — validate the full file before
applying.

---

## tag:t2 SSH Block

With `tag:t3` removed, `tag:t2` had no remaining SSH destinations. Rather
than leaving an empty `dst` array (ambiguous — looks like an error, not
intent), the block was replaced with a comment:

```json
// Tier 2 Muddpi — Default Deny
```

Consistent with the existing pattern used elsewhere in the ACL for
intentional default-deny documentation.

---

## ACL Review Protocol

This update surfaced a pattern worth documenting: changes were applied
without a full file review, causing `tag:t3` to persist in multiple locations
after the initial fix.

**Before applying any ACL change:**
1. Make the targeted edit
2. Search the entire file for any related references (`tag:t3`, old IPs,
   stale comments)
3. Read the full file top to bottom
4. Apply only after the full review is complete

The review step is not optional — it's the difference between a clean ACL
and one that quietly has dangling references that may cause validation errors
or unexpected behavior.