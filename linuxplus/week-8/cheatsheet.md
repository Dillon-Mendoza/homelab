# Week 8 Cheatsheet: Custom Unit Files

## Unit File Structure (/etc/systemd/system/myservice.service)
```ini
[Unit]
Description=Service Description
After=network.target

[Service]
Type=simple
User=username
WorkingDirectory=/home/username
ExecStart=/path/to/script.sh
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

## Management Commands
- `systemctl daemon-reload`: Reload all unit files.
- `systemctl cat SERVICE`: Show the content of a unit file.
- `systemctl edit SERVICE`: Create an override (drop-in) for a service.
- `systemctl enable --now SERVICE`: Enable and start immediately.

## Service Types
- **simple**: Default. `ExecStart` is the main process.
- **forking**: Main process starts a child process and exits.
- **oneshot**: For tasks that run once and exit.
- **notify**: Process sends a notification when ready.
