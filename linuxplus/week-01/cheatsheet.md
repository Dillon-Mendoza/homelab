# Week 1: Phase 1 — File Permissions & Ownership Pt 1

## Overview: The rwx Foundation
Permissions in Linux are the gatekeepers. If you don't understand these, you don't own the system.

### The Permission String
`ls -l` reveals the 10-character string: `-rwxr-xr-x`
- `1st char`: Type (`-` file, `d` directory, `l` link)
- `2-4`: User (Owner)
- `5-7`: Group
- `8-10`: Others (The World)

### Symbolic vs. Octal
| Mode | Symbolic | Octal | Binary | Meaning |
| :--- | :--- | :--- | :--- | :--- |
| **Read** | `r` | `4` | `100` | View content (file) / List entries (dir) |
| **Write** | `w` | `2` | `010` | Edit content (file) / Add/Delete entries (dir) |
| **Execute** | `x` | `1` | `001` | Run as program (file) / CD into (dir) |

**Example:** `chmod 755` → `rwxr-xr-x` (Owner: all, Group/Others: read/execute)

### The "Directory Trap"
- **Execute (x) on a directory:** You need this to `cd` into it or access files inside. Without `x`, `r` lets you see names but not metadata (size/owner).
- **Write (w) on a directory:** This allows **deleting** files inside, even if you don't own the files themselves.

---

## Real-World Homelab Context
- **ThinkPad (t0):** Your SSH keys in `~/.ssh/` *must* be `600` (rw-------). If they are world-readable, SSH will refuse to use them.
- **Gitea (t1):** The data directories require specific ownership (`git:git`) and permissions for the service to write logs and repos.

---

## Quick Recall (Flashcard Style)
- `chmod 644`: Standard file (Owner: rw, Group/Other: r)
- `chmod 755`: Standard directory/executable (Owner: rwx, Group/Other: rx)
- `chmod 400`: Read-only for owner (common for private keys)
- `chown user:group`: Change both owner and group at once
- `ls -ld`: View permissions of the directory itself, not its contents
- `r` on dir: Allows `ls` to work
- `x` on dir: Allows `cd` to work
- `w` on dir: Allows `rm` and `touch` to work
- `stat -c %a`: Show octal permissions of a file
- `chmod -R`: Recursive permission change (use with caution)
- `umask`: Defines default permissions for new files
- `symbolic +x`: `chmod +x script.sh` (adds execute to all)
- `symbolic u+w`: Add write only for the owner
