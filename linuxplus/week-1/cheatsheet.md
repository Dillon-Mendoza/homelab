# Week 1 Cheatsheet: Commands & Syntax

| Command | Why it matters | Example |
|---------|----------------|---------|
| `chmod` | Sets the rwx bitmask on files/dirs | `chmod 755 script.sh` |
| `chown` | Establishes the owner and group | `sudo chown mudd:devs project/` |
| `chgrp` | Change ONLY group ownership | `chgrp devs file.txt` |
| `ls -l` | Classic detailed list | `ls -l /etc/passwd` |
| `stat`  | Deep metadata, including numeric mode | `stat -c "%a %n" *` (just mode and name) |
| `umask` | Filters default permissions | `umask 002` (sets new files to 664) |
| `id`    | Verify your UID/GID and groups | `id tp-mudd` |

## Permission Modes (Numeric)
- **777**: `rwxrwxrwx` (**STOP:** Never use unless you're intentionally making it world-writable)
- **755**: `rwxr-xr-x` (Default for binaries/scripts)
- **644**: `rw-r--r--` (Default for config/data files)
- **600**: `rw-------` (Sensitive files: SSH keys, secrets)

## Symbolic Notation Reference
| Target | Symbol | Action | Symbol | Perm | Symbol |
|--------|--------|--------|--------|------|--------|
| User   | `u`    | Add    | `+`    | Read | `r`    |
| Group  | `g`    | Remove | `-`    | Write| `w`    |
| Others | `o`    | Set    | `=`    | Exec | `x`    |
| All    | `a`    |        |        |      |        |

## Pro-Tips: Avoiding the "Lazy chmod 777"
- **The Issue:** People use `777` when they hit a permission error.
- **The Craft Fix:** Identify the group (`id`), change ownership (`chown :group`), and set permissions to `775` or `664` instead.
- **Recursive Warning:** `chmod -R` or `chown -R` can be dangerous. Always `ls` or `find` before you apply recursively.
