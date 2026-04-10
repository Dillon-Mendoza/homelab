# Week 2 Cheatsheet: Special Permissions & ACLs

| Permission | Symbolic | Numeric | The "Why" |
|------------|----------|---------|-----------|
| **SUID**   | `u+s`    | `4000`  | Allow user to run a file with OWNER's privileges |
| **SGID**   | `g+s`    | `2000`  | Shared dirs: inherit group ownership |
| **Sticky Bit**| `+t`   | `1000`  | Shared dirs: only owner can delete files (`/tmp`) |

| Command    | Purpose | Practical Example |
|------------|---------|-------------------|
| `umask`    | Filter default perms | `umask 022` (Sets 755/644) |
| `getfacl`  | Read the ACL list | `getfacl file.txt` |
| `setfacl`  | Modify the ACL list | `setfacl -m u:mudd:rw- file.txt` |
| `chattr`   | Immutable files | `sudo chattr +i important.conf` (Root can't delete) |

## The Special "s/t" vs "S/T" Indicator
When you see `rwsr-sr-t`, the lowercase/uppercase means everything:
- **`s/t` (lowercase)**: Special bit is SET, and the execute bit (`x`) is ALSO SET. (Correct/Active)
- **`S/T` (UPPERCASE)**: Special bit is SET, but the execute bit (`x`) is NOT SET. (Inactive/Broken)

## ACL Syntax (Quick Reference)
- **Add/Modify**: `setfacl -m u:user:rwx file`
- **Remove Specific**: `setfacl -x u:user file`
- **Remove ALL ACLs**: `setfacl -b file`
- **Default ACL (for dirs)**: `setfacl -m d:u:user:rwx dir` (New files inherit this)

## Practical Pro-Tips
- **The "Find" Scrutiny**: Use `find / -perm /6000 -type f` regularly on your Pi to find all SUID/SGID files. It's the first thing an attacker looks for.
- **SGID Shared Dirs**: Always set SGID on your homelab project folders (`chmod 2775`). It prevents the "I can't edit my teammate's file" headache.
- **umask in Scripts**: Set a local `umask` inside your bash scripts to ensure they create files with the correct security level (e.g., `umask 077` for a script that generates secrets).
