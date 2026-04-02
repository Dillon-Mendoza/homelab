# Week 3 Cheatsheet: User & Group Management

| Command | Description | Example |
|---------|-------------|---------|
| `useradd` | Create a new user | `sudo useradd -m -s /bin/bash user` |
| `usermod` | Modify a user account | `sudo usermod -aG group user` |
| `userdel` | Delete a user account | `sudo userdel -r user` |
| `groupadd` | Create a new group | `sudo groupadd groupname` |
| `passwd` | Change user password | `sudo passwd username` |
| `chage` | Change user password expiry | `sudo chage -l username` |
| `id` | Print real and effective IDs | `id username` |
| `groups` | Print the groups a user is in | `groups username` |
| `whoami` | Print effective userid | `whoami` |

## useradd/usermod Flags
- `-m`: Create home directory
- `-s`: Specify login shell (e.g., `/bin/bash` or `/sbin/nologin`)
- `-G`: Supplementary groups (use `-aG` with `usermod` to append)
- `-u`: Specify UID
- `-r`: Create a system account

## Important Files
- **/etc/passwd**: User account info.
- **/etc/shadow**: Secure user account info (hashes).
- **/etc/group**: Group account info.
- **/etc/skel/**: Template files for new users' home directories.
