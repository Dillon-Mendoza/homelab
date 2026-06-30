# Week 2 — Phase 1: Foundation Revisit
## Topic: File Permissions & Ownership Pt 2 (Special Bits & Umask)

This week focuses on special permissions and the default permission mask (umask). These are critical for system security and multi-user environments.

---

### Special Permissions

| Bit | Symbol (Octal) | Name | Effect on Files | Effect on Directories |
|-----|----------------|------|-----------------|-----------------------|
| **SUID** | `u+s` (4000) | Set User ID | File executes with owner's privileges (e.g., `/usr/bin/passwd`). | No common effect. |
| **SGID** | `g+s` (2000) | Set Group ID | File executes with group's privileges. | New files/dirs created inside inherit the parent's group ID. |
| **Sticky**| `o+t` (1000) | Sticky Bit | No common effect. | Only the file owner, directory owner, or root can delete/rename files. |

#### Syntax & Examples
- **SUID:** `chmod u+s file` or `chmod 4755 file`
- **SGID:** `chmod g+s dir` or `chmod 2775 dir` (Crucial for shared project folders)
- **Sticky Bit:** `chmod +t dir` or `chmod 1777 dir` (Standard for `/tmp`)

---

### Umask (User File-Creation Mask)

Umask defines the default permissions for *newly created* files and directories. It is a "mask" that *subtracts* from the base permissions.

- **Base Directory Permissions:** 777 (`rwxrwxrwx`)
- **Base File Permissions:** 666 (`rw-rw-rw-`)

#### Calculation
If `umask` is `0022`:
- **Dir:** `777 - 022 = 755` (`rwxr-xr-x`)
- **File:** `666 - 022 = 644` (`rw-r--r--`)

If `umask` is `0002` (Common for shared groups):
- **Dir:** `777 - 002 = 775`
- **File:** `666 - 002 = 664`

#### Setting Umask
- Temporary: `umask 0077`
- Permanent: Edit `~/.bashrc` or `/etc/profile`.

---

### Finding Special Permissions
Use `find` to identify potentially dangerous files:
- **Find SUID:** `find / -perm /4000 -type f 2>/dev/null`
- **Find SGID:** `find / -perm /2000 -type f 2>/dev/null`
- **Find World-Writable:** `find / -perm -0002 -type d 2>/dev/null`

---

### Quick Recall
1. `chmod 4755`: Set SUID on a file.
2. `chmod 2775`: Set SGID on a directory.
3. `chmod 1777`: Set Sticky Bit on a directory.
4. `u+s`: Symbolic representation of SUID.
5. `g+s`: Symbolic representation of SGID.
6. `+t`: Symbolic representation of Sticky Bit.
7. `umask 022`: Default mask for most systems (644/755).
8. `umask 077`: Restrictive mask (600/700).
9. `find -perm /4000`: Search for any SUID bit set.
10. `s` in owner field: SUID is active (e.g., `rwsr-xr-x`).
11. `S` in owner field: SUID is set but owner lacks execute permission.
12. `t` in other field: Sticky Bit is active (e.g., `rwxrwxrwt`).
13. `2>/dev/null`: Redirect errors (permission denied) when searching.
14. `/etc/login.defs`: Where default UMASK can be system-wide.
15. `id`: Check current user/group context.
