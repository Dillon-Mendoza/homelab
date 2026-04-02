# Week 12 Cheatsheet: logrotate, grep, and awk

| Command | Description | Example |
|---------|-------------|---------|
| `logrotate` | Rotates, compresses, and mails system logs | `sudo logrotate -f /etc/logrotate.conf` |
| `grep` | Search file(s) for lines that match a pattern | `grep -r "error" /var/log/` |
| `awk` | Pattern scanning and processing language | `awk '{print $1, $NF}' file` |
| `sort` | Sort lines of text files | `sort -nr` (numeric, reverse) |
| `uniq` | Report or omit repeated lines | `uniq -c` (count) |
| `wc` | Print newline, word, and byte counts | `wc -l` (lines) |

## logrotate Configuration Keywords
- **daily/weekly/monthly**: Rotation frequency.
- **rotate N**: Keep N old log files.
- **compress**: Gzip old logs.
- **delaycompress**: Don't compress the most recent rotation.
- **missingok**: Don't error if the log file is missing.
- **notifempty**: Don't rotate if the file is empty.
- **create MODE OWNER GROUP**: Set permissions for new files.
- **postrotate/endscript**: Run commands after rotation.

## grep Flags
- `-i`: Case-insensitive.
- `-r`: Recursive.
- `-v`: Invert match (exclude).
- `-c`: Count matches.
- `-C N`: Show N lines of context.
- `-E`: Extended regex (e.g., "p1|p2").

## awk Basics
- `$1, $2, ...`: Fields (columns).
- `$NF`: Last field.
- `$0`: Entire line.
- `-F:`: Set field separator (e.g., colon for /etc/passwd).
