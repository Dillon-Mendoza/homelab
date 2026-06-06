# Week 2 — Reference & Links

### Key Man Pages
- `man chmod` — Look for the "SETUID AND SETGID BITS" section.
- `man umask` — Understand the subtraction logic and bitmask.
- `man find` — Pay attention to the `-perm` flag syntax (`/` vs `-` vs exact).
- `man 5 login.defs` — Configuration for system defaults.

### Curated Resources
- [LearnLinuxTV: Special Permissions (SUID, SGID, Sticky Bit)](https://www.youtube.com/watch?v=k_n7xR9o83c)
- [Professor Messer: Linux File Permissions (XK0-005)](https://www.professormesser.com/)
- [Arch Wiki: File permissions and attributes](https://wiki.archlinux.org/title/File_permissions_and_attributes)

### Exam Objective Mapping
- **2.1**: Given a scenario, manage files and directories (Special bits and umask).

### Things That Trip People Up
1. **Octal vs Symbolic:** In the exam, you might see `4755`. Remember: 4=SUID, 2=SGID, 1=Sticky.
2. **Capital 'S' vs Lowercase 's':** A capital `S` (in `rws`) means the bit is set, but the underlying execute bit is NOT. Lowercase `s` means both are set.
3. **Umask Math:** It's not always simple subtraction. It's a bitwise NOT-AND operation. For most exam scenarios, subtraction works, but if you have a umask of `007` and try to subtract from `666`, the result is `660` (not `659`).
4. **SGID on Dirs:** People forget that SGID on a directory is about *inheritance* for new files, not about running a directory with group privileges.

### Connect to the Homelab
In your homelab, **SGID** is vital for the Gitea service or any shared folder on your Dell Server (t1) where multiple users might be contributing code or assets. Without it, you'll constantly be fighting permission errors when one user creates a file that another can't edit. The **Sticky Bit** is already protecting your `/tmp` directories on every node from PiZero to ThinkPad.
