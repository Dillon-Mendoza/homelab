# Week 1 Reference & Notes

## Exam Objective Mapping
- **CompTIA Linux+ XK0-005: 2.1** — Given a scenario, manage files and directories.
  - Permissions (rwx)
  - Ownership (chown)
  - Directory permissions vs. file permissions

## Essential Man Pages
- `man chmod` — Pay attention to the "SETUID AND SETGID BITS" section.
- `man chown` — Review the `--reference` flag for copying ownership between files.
- `man ls` — Review `-i` (inodes) and `-d` (directory info).

## Curated Resources
- [LearnLinuxTV: Linux Permissions Explained](https://www.youtube.com/watch?v=yYfI79UvOXY)
- [Professor Messer: Linux Permissions (XK0-005)](https://www.professormesser.com/)
- [Arch Wiki: File Permissions](https://wiki.archlinux.org/title/File_permissions_and_attributes)

## Things That Trip People Up (Gotchas)
1. **The 'w' on Dirs:** If a user has `w` and `x` on a directory, they can delete any file in it, even if they don't own the file and have no permissions on the file itself. This is why `/tmp` uses the "Sticky Bit" (more on that in Week 2).
2. **Read vs. Execute on Dirs:** If you have `r` but no `x`, you can `ls` the directory but you'll get errors for file sizes and types (displayed as `?`). You cannot `cd` or open files inside.
3. **Octal Math:** It's easy to flip 4 (read) and 2 (write) under pressure. Remember: Read=4, Write=2, Execute=1. (4-2-1).

## Connect to the Homelab
You are already using these concepts on the **Pi Zero 2 W (t3)** bastion host. To keep that device secure as the "gatekeeper," we ensure that log files are only readable by the root or specialized audit groups. Your work here in Week 1 is what ensures that a compromise of a low-privilege user doesn't immediately result in a read of the entire system's history.
