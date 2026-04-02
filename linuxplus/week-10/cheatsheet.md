# Week 10 Cheatsheet: Firewall Management

| Command | Description | Example |
|---------|-------------|---------|
| `iptables -L` | List all rules in all chains | `sudo iptables -L -v -n` |
| `iptables -A` | Append a rule to the end of a chain | `sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT` |
| `iptables -I` | Insert a rule at the beginning (or position) | `sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT` |
| `iptables -D` | Delete a rule by number or specification | `sudo iptables -D INPUT 3` |
| `iptables -P` | Set the default policy for a chain | `sudo iptables -P INPUT DROP` |
| `iptables -F` | Flush (delete) all rules | `sudo iptables -F` |
| `iptables-save`| Save rules to a file | `sudo iptables-save > rules.v4` |
| `ufw enable` | Enable the Uncomplicated Firewall | `sudo ufw enable` |
| `ufw allow` | Allow a port or service | `sudo ufw allow 22/tcp` |

## iptables Rule Components
- `-p`: Protocol (tcp, udp, icmp)
- `-s`: Source IP/Network
- `-d`: Destination IP/Network
- `--sport`: Source Port
- `--dport`: Destination Port
- `-j`: Jump target (ACCEPT, DROP, REJECT)
- `-i`: Input Interface (e.g., eth0, lo)

## Targets
- **ACCEPT**: Allow the packet.
- **DROP**: Silently discard the packet.
- **REJECT**: Discard and send an error message back.
