# Week 1 Cheatsheet: Commands & Syntax

| Command | Description | Example |
|---------|-------------|---------|
| `chmod` | Change file modes or permissions | `chmod 755 file` |
| `chown` | Change file owner and group | `sudo chown user:group file` |
| `chgrp` | Change group ownership | `chgrp group file` |
| `ls -l` | List directory contents with detailed info | `ls -l /path/to/dir` |
| `stat`  | Display file or file system status | `stat file.txt` |
| `umask` | Display or set file mode creation mask | `umask 022` |

## Permission Modes
- **777**: `rwxrwxrwx` (Full access - AVOID)
- **755**: `rwxr-xr-x` (Standard executable)
- **644**: `rw-r--r--` (Standard file)
- **600**: `rw-------` (Private file)

## Symbolic Notation
- `u`: User
- `g`: Group
- `o`: Others
- `a`: All
- `+`: Add
- `-`: Remove
- `=`: Set exactly
