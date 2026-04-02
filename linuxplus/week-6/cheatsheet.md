# Week 6 Cheatsheet: SSH Hardening

| Setting | Recommendation | Description |
|---------|----------------|-------------|
| `PasswordAuthentication` | `no` | Force key-only authentication |
| `PermitRootLogin` | `no` | Prevent direct root SSH access |
| `Port` | `2222` (example) | Move from default port 22 |
| `AllowUsers` | `user1 user2` | Limit which users can SSH |
| `MaxAuthTries` | `3` | Limit login attempts |
| `PermitEmptyPasswords`| `no` | Disable empty passwords |

## SSH Client Config (~/.ssh/config)
```ssh
Host myserver
    HostName 192.168.1.100
    User myuser
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
```

## Management Commands
- `sshd -t`: Test configuration syntax.
- `sudo systemctl restart sshd`: Restart SSH service (Fedora/RHEL).
- `sudo systemctl restart ssh`: Restart SSH service (Ubuntu/Debian).
