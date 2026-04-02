# Week 16 Cheatsheet: DNF & RPM Commands

| Task | Debian/Ubuntu (APT) | Fedora/RHEL (DNF) |
|------|---------------------|-------------------|
| Update list | `apt update` | `dnf check-update` |
| Upgrade | `apt upgrade` | `dnf upgrade` |
| Install | `apt install PKG` | `dnf install PKG` |
| Remove | `apt remove PKG` | `dnf remove PKG` |
| Search | `apt search PKG` | `dnf search PKG` |
| Info | `apt show PKG` | `dnf info PKG` |
| List installed | `dpkg -l` | `rpm -qa` |
| Files in pkg | `dpkg -L PKG` | `rpm -ql PKG` |
| Which pkg owns file | `dpkg -S FILE` | `rpm -qf FILE` |
| History | `/var/log/apt/history.log`| `dnf history` |

## DNF Specific Commands
- `dnf repolist`: Show enabled repositories.
- `dnf group install "Group Name"`: Install a collection of related packages.
- `dnf history undo <ID>`: Undo a specific transaction.
- `dnf provides <file>`: Find which package provides a specific file.

## RPM Flags
- `-qa`: Query all installed packages.
- `-qi`: Query info about an installed package.
- `-ql`: List files in an installed package.
- `-qf`: Find package that owns a file.
- `-ivh`: Install, verbose, hash marks.
