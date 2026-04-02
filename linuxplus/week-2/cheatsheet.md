# Week 2 Cheatsheet: Special Permissions & umask

| Permission | Symbolic | Numeric | Description |
|------------|----------|---------|-------------|
| SUID       | `u+s`    | `4000`  | Run with owner's privileges |
| SGID       | `g+s`    | `2000`  | Run with group's privileges / inherit group |
| Sticky Bit | `+t`     | `1000`  | Only owner can delete files |

| Command    | Description | Example |
|------------|-------------|---------|
| `umask`    | Display or set default permissions | `umask 022` |
| `getfacl`  | Get file access control lists | `getfacl file` |
| `setfacl`  | Set file access control lists | `setfacl -m u:user:rwx file` |

## Common Special Modes
- **4755**: SUID + `rwxr-xr-x`
- **2775**: SGID + `rwxrwxr-x`
- **1777**: Sticky Bit + `rwxrwxrwx` (typical for `/tmp`)

## Character Representation
- `s` (User): SUID is set and owner has execute permission.
- `S` (User): SUID is set but owner DOES NOT have execute permission.
- `s` (Group): SGID is set and group has execute permission.
- `t` (Others): Sticky bit is set and others have execute permission.
- `T` (Others): Sticky bit is set but others DO NOT have execute permission.
