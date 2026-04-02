# Week 7 Cheatsheet: Systemd & Journalctl

| Command | Description |
|---------|-------------|
| `systemctl start SERVICE` | Start a service |
| `systemctl stop SERVICE` | Stop a service |
| `systemctl restart SERVICE` | Restart a service |
| `systemctl enable SERVICE` | Enable service at boot |
| `systemctl disable SERVICE` | Disable service at boot |
| `systemctl status SERVICE` | Check service status |
| `systemctl list-units --type=service` | List all services |
| `systemctl daemon-reload` | Reload systemd configuration |

## Journalctl Commands
- `journalctl -u SERVICE`: View logs for a specific service.
- `journalctl -f`: Follow logs in real-time.
- `journalctl -n 50`: View last 50 lines.
- `journalctl --since today`: View logs since today.
- `journalctl -p err`: View error-level logs only.

## Service States
- **active (running)**: Service is currently running.
- **inactive (dead)**: Service is not running.
- **enabled**: Service will start automatically at boot.
- **disabled**: Service will NOT start at boot.
- **failed**: Service encountered an error.
