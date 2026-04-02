# Week 9 Cheatsheet: Networking Commands

| Command | Description | Example |
|---------|-------------|---------|
| `ip addr` | Show/manipulate network interfaces | `ip addr show` |
| `ip route` | Show/manipulate routing table | `ip route show` |
| `ping` | Send ICMP ECHO_REQUEST to network hosts | `ping 8.8.8.8` |
| `traceroute` | Print the route packets trace to network host | `traceroute google.com` |
| `ss` | Another utility to investigate sockets | `ss -tulpn` |
| `netstat` | Print network connections (legacy) | `netstat -tulpn` |
| `ifconfig` | Configure network interface (legacy) | `ifconfig eth0` |
| `route` | Show/manipulate routing table (legacy) | `route -n` |

## Common Ports
- **22**: SSH
- **80**: HTTP
- **443**: HTTPS
- **3000**: Gitea
- **514**: Syslog
- **53**: DNS

## Private IP Ranges
- **10.0.0.0/8**: 10.0.0.0 - 10.255.255.255
- **172.16.0.0/12**: 172.16.0.0 - 172.31.255.255
- **192.168.0.0/16**: 192.168.0.0 - 192.168.255.255
- **100.64.0.0/10**: Tailscale/CGNAT
