# Week 1: Linux Permissions & Basics
**Date:** March 9, 2026
**Estimated Time:** 5-8 hours

## Objectives
- Understand rwx permissions and basic `chmod`/`chown` usage.
- Manage files and directories (Exam Objective 2.4).
- Summarize Linux fundamentals (Exam Objective 1.1).

## The Thing Beneath the Thing: Binary Representation
Permissions aren't just letters; they are a bitmask.
- **Read (r)**: 4 (binary `100`)
- **Write (w)**: 2 (binary `010`)
- **Execute (x)**: 1 (binary `001`)

**Why this matters:** When you run `chmod 755`, you're setting `111` (7) for user, `101` (5) for group, and `101` (5) for others. Understanding the binary helps when you encounter advanced masking or troubleshooting complex access issues.

## Key Concepts
### 1. The rwx Triad
- **Files**:
  - `r`: View content
  - `w`: Modify content
  - `x`: Execute as a script/binary
- **Directories** (Often confused):
  - `r`: List files (`ls`)
  - `w`: Add/remove files (Needs `x` to enter)
  - `x`: Enter the directory (`cd`)

### 2. chmod: Numeric vs. Symbolic
- **Numeric**: Best for absolute settings (`chmod 644 file.txt`).
- **Symbolic**: Best for surgical changes (`chmod g+w shared_dir/`).

### 3. umask: The Default Filter
The `umask` *subtracts* from the maximum possible permissions (777 for dirs, 666 for files).
- Default `022` results in `755` for dirs and `644` for files.
- **Pro Tip:** In the homelab, if you're sharing a folder on the Dell server for Gitea, a `umask 002` (allowing group write) might be more appropriate.

## Practical Homelab Scenarios
### Scenario: The "Audit for 777"
You suspect a script has been set to 777 (world-writable) on your Pi.
**Command:** `find /path/to/scripts -perm 777`
**The Fix:** `chmod 755 script.sh` (or 644 if it doesn't need to be executed).

### Scenario: Shared Team Directory
Setting up a directory for multiple users on the Dell server.
1. `sudo mkdir /srv/projects`
2. `sudo chown :devs /srv/projects`
3. `chmod 775 /srv/projects`

## Exam Insights (XK0-005)
- **ls -l Breakdown**: Know exactly what each character in `-rwxr-xr-x` means (The first `-` is the file type).
- **Stat vs. ls**: Use `stat` when you need the numeric mode (e.g., `0644`) quickly without mental math.

## Resources
- [CompTIA Linux+ XK0-005 Objectives](https://partners.comptia.org/docs/defaultsource/resources/comptia-linux-xk0-005-exam-objectives-(3-0))
- Chapter 3: File Modes and Permissions section
- Search: "Linux File Permissions", "Linux+ Permissions"
