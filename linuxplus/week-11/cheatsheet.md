# Week 11 Cheatsheet: Logging Commands & Priorities

| Command | Description | Example |
|---------|-------------|---------|
| `journalctl` | Query and display logs from journald | `journalctl -u sshd -f` |
| `logger` | A shell command interface to syslog | `logger -p local0.info "message"` |
| `rsyslogd` | The reliable system log daemon | `systemctl restart rsyslog` |
| `dmesg` | Print or control the kernel ring buffer | `dmesg | grep -i error` |
| `tail -f` | Output the last part of a file (follow) | `tail -f /var/log/messages` |

## Syslog Severity Levels
0. **emerg**: System is unusable
1. **alert**: Action must be taken immediately
2. **crit**: Critical conditions
3. **err**: Error conditions
4. **warning**: Warning conditions
5. **notice**: Normal but significant
6. **info**: Informational messages
7. **debug**: Debug-level messages

## rsyslog Forwarding Syntax
- `*.* @IP:514`: Forward all logs via **UDP**.
- `*.* @@IP:514`: Forward all logs via **TCP**.

## journalctl Filters
- `-u SERVICE`: Filter by unit (service).
- `-p LEVEL`: Filter by priority (0-7 or name).
- `-f`: Follow logs in real-time.
- `-n N`: Show last N lines.
- `--since "1 hour ago"`: Filter by time.
