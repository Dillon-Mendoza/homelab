# Week 5 Cheatsheet: SSH Keys

| Command | Description | Example |
|---------|-------------|---------|
| `ssh-keygen` | Generate SSH key pair | `ssh-keygen -t ed25519` |
| `ssh-copy-id` | Copy public key to server | `ssh-copy-id user@server` |
| `ssh-add` | Add private key to agent | `ssh-add ~/.ssh/id_ed25519` |
| `ssh-agent` | Authentication agent | `eval "$(ssh-agent -s)"` |
| `ssh -v` | Verbose SSH output | `ssh -v user@server` |

## SSH Files & Permissions
- **~/.ssh/**: `700` (drwx------)
- **authorized_keys**: `600` (-rw-------)
- **id_ed25519**: `600` (-rw-------) - Private Key
- **id_ed25519.pub**: `644` (-rw-r--r--) - Public Key

## Recommended Key Types
- **Ed25519**: Modern, fast, secure (Recommended)
- **RSA 4096**: Older but widely compatible and secure
- **ECDSA**: Good alternative, but Ed25519 is preferred
