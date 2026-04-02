# Week 15 Cheatsheet: Commands & Syntax

| Command | Description | Example |
|---------|-------------|---------|
| `apt update` | Update package index | `sudo apt update` |
| `apt upgrade` | Upgrade all packages | `sudo apt upgrade` |
| `apt install` | Install a package | `sudo apt install pkg` |
| `apt remove` | Remove a package | `sudo apt remove pkg` |
| `apt purge` | Remove package & configs | `sudo apt purge pkg` |
| `apt search` | Search for packages | `apt search pkg` |
| `apt show` | Show package details | `apt show pkg` |
| `apt-cache depends` | Show dependencies | `apt-cache depends pkg` |
| `dpkg -l` | List installed packages | `dpkg -l | grep pkg` |
| `dpkg -L` | List files in package | `dpkg -L pkg` |
| `dpkg -S` | Find package for file | `dpkg -S /path/to/file` |
| `add-apt-repository` | Add PPA | `sudo add-apt-repository ppa:name` |

## APT vs APT-GET
- `apt`: Recommended for end-users (pretty output, progress bars).
- `apt-get`: Recommended for scripts (stable interface, more verbose).

## Important Paths
- `/etc/apt/sources.list`: Main repository list.
- `/etc/apt/sources.list.d/`: Additional repo files.
- `/var/cache/apt/archives/`: Downloaded `.deb` files.
- `/var/lib/dpkg/status`: Low-level package status database.
