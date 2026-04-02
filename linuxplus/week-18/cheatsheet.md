# Week 18 Cheatsheet: SELinux Commands

| Command | Description |
|---------|-------------|
| `sestatus` | Display SELinux status |
| `getenforce` | Show current mode (Enforcing, Permissive, Disabled) |
| `sudo setenforce [0\|1]` | Set mode (0=Permissive, 1=Enforcing) |
| `ls -Z <file>` | View file security context |
| `ps -Z <pid>` | View process security context |
| `sudo restorecon -Rv <dir>` | Restore default security contexts recursively |
| `sudo chcon -t <type> <file>` | Temporarily change file context |
| `sudo semanage fcontext -a -t <type> "path(/.*)?"` | Add permanent context rule |
| `getsebool -a` | List all SELinux booleans |
| `sudo setsebool -P <bool> [on\|off]` | Set boolean persistently |

## Common Context Types
- `httpd_sys_content_t`: Web content (read-only)
- `httpd_sys_rw_content_t`: Web content (read-write)
- `user_home_t`: User home directories
- `ssh_home_t`: SSH-related files in home directory

## Troubleshooting Tools
- `ausearch -m avc -ts recent`: Search for recent denials.
- `audit2why`: Translate audit messages into descriptions of why access was denied.
- `sealert -a /var/log/audit/audit.log`: Get detailed suggestions for fixing denials.
