# Week 4 Cheatsheet: sudo & visudo

| Command | Description | Example |
|---------|-------------|---------|
| `sudo <cmd>` | Run command with root privileges | `sudo systemctl restart sshd` |
| `sudo -l` | List allowed commands for current user | `sudo -l` |
| `sudo -u <user> <cmd>` | Run command as another user | `sudo -u www-data ls /var/www` |
| `visudo` | Safely edit `/etc/sudoers` | `sudo visudo` |
| `visudo -c` | Check sudoers file for syntax errors | `sudo visudo -c` |
| `su - <user>` | Switch to user with their environment | `su - tier1admin` |
| `sudo -i` | Interactive root shell | `sudo -i` |

## Sudoers Syntax: `user host=(runas) commands`
- **`user`**: Username or `%groupname`.
- **`host`**: Usually `ALL` (applies to this machine).
- **`(runas)`**: Which user/group the command can run as. `(ALL:ALL)` means any.
- **`commands`**: Path to specific binaries or `ALL`.

## Common Defaults
- `Defaults env_reset`: Resets environment variables for security.
- `Defaults secure_path="..."`: Sets a safe PATH for sudo commands.
- `Defaults timestamp_timeout=15`: Sudo password remains valid for 15 minutes.
- `Defaults logfile="/var/log/sudo.log"`: Enables custom logging.
