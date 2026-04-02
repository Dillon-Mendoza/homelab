# Week 17 Cheatsheet: Nmap & Lynis

| Nmap Command | Description |
|--------------|-------------|
| `nmap <IP>` | Basic port scan |
| `nmap -sV <IP>` | Service version detection |
| `nmap -p <ports> <IP>` | Scan specific ports (e.g., `-p 22,80`) |
| `nmap -p- <IP>` | Scan all 65535 ports |
| `nmap -A <IP>` | Aggressive scan (OS, versions, scripts) |
| `nmap -F <IP>` | Fast scan (top 100 ports) |
| `nmap -oN <file> <IP>` | Save output to normal text file |

## Common Ports
- **21**: FTP
- **22**: SSH
- **25**: SMTP
- **53**: DNS
- **80**: HTTP
- **443**: HTTPS
- **3306**: MySQL

## Lynis Commands
- `sudo lynis audit system`: Perform full system audit.
- `sudo lynis show settings`: Show Lynis configuration.
- `sudo lynis show version`: Show Lynis version.
