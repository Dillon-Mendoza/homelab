# Week 2: Special Permissions & ACLs
**Date:** March 16, 2026
**Estimated Time:** 5-8 hours

## Objectives
- Understand and implement special permissions: SUID, SGID, and Sticky Bit.
- Manage default permissions using `umask`.
- Introduction to Access Control Lists (ACLs) for granular control.
- Apply permissions to Gitea server infrastructure (Exam Objective 2.4).

## The Thing Beneath the Thing: The Fourth Octet
We often think of permissions in three digits (e.g., `755`), but there is a hidden fourth octet at the front.
- **SUID**: 4 (binary `100`)
- **SGID**: 2 (binary `010`)
- **Sticky Bit**: 1 (binary `001`)

**Why this matters:** When you see `4755`, that `4` is the SUID bit. Understanding this prefix is the key to mastering `chmod`'s numeric mode for advanced security configurations.

## Key Concepts
### 1. SUID (Set User ID)
- **Symbolic**: `u+s` (e.g., `-rwsr-xr-x`)
- **Function**: The file executes with the permissions of the **owner**, not the user running it.
- **Classic Example**: `/usr/bin/passwd` (Needs root to modify `/etc/shadow`).
- **The Craft Warning**: SUID on a shell script is a massive security hole. If you find one, investigate immediately.

### 2. SGID (Set Group ID)
- **Symbolic**: `g+s` (e.g., `-rwxr-sr-x`)
- **On Files**: Executes with the group's permissions.
- **On Directories (Crucial)**: New files created inside **inherit the group of the parent directory**, rather than the creator's primary group.

### 3. Sticky Bit
- **Symbolic**: `+t` (e.g., `drwxrwxrwt`)
- **Function**: Only the file owner, directory owner, or root can delete files.
- **Use Case**: `/tmp`—everyone can write, but nobody can delete your stuff.

### 4. ACLs (Access Control Lists)
Standard rwx isn't enough when you have User A, User B, and Group C needing different access to the same file.
- `getfacl`: View the list.
- `setfacl`: Modify the list.

## Practical Homelab Scenarios
### Scenario: The Shared Dev Folder (SGID)
Setting up a folder where everyone in the `devs` group can collaborate without manual `chown` calls.
1. `sudo mkdir /srv/dev-share`
2. `sudo chgrp devs /srv/dev-share`
3. `sudo chmod 2775 /srv/dev-share`
**Result:** Any file Dillon creates here will automatically belong to the `devs` group.

### Scenario: Granular Access for a Backup Script (ACLs)
You have a `backup.sh` script owned by `root`. You want the `backup-bot` user to *only* be able to read it, without changing the group ownership.
**Command:** `setfacl -m u:backup-bot:r backup.sh`

## Exam Insights (XK0-005)
- **The "s" vs "S"**: If you see a capital `S` (e.g., `rwSr--r--`), it means SUID/SGID is set, but the execute bit (`x`) is **missing**. This is usually a configuration error.
- **Finding Special Perms**: Know how to find them: `find /usr/bin -perm /4000` (SUID).

## Resources
- [CompTIA Linux+ XK0-005 Objectives](https://partners.comptia.org/docs/defaultsource/resources/comptia-linux-xk0-005-exam-objectives-(3-0))
- Chapter 3: Special Permissions (SUID, SGID, sticky bit)
- Search: "Linux Permissions Special", "SUID SGID sticky bit"
