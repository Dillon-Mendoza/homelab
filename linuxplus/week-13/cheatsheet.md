# Week 13 Cheatsheet: Commands & Syntax

| Command | Description | Example |
|---------|-------------|---------|
| `crontab -e` | Edit your crontab file | `crontab -e` |
| `crontab -l` | List your cron jobs | `crontab -l` |
| `crontab -r` | Remove all your cron jobs | `crontab -r` |
| `at`         | Execute commands at a specified time | `echo "reboot" | at 03:00` |
| `set -e`     | Exit immediately on error | `set -e` at script start |
| `set -x`     | Print commands before executing (debug) | `set -x` in script |
| `trap`       | Catch signals and execute commands | `trap cleanup EXIT` |

## Cron Syntax
`* * * * * command`
- **Minute**: 0 - 59
- **Hour**: 0 - 23
- **Day of Month**: 1 - 31
- **Month**: 1 - 12
- **Day of Week**: 0 - 6 (Sunday=0)

## Common Cron Examples
- `0 2 * * *`: Every day at 2:00 AM
- `*/15 * * * *`: Every 15 minutes
- `0 0 * * 0`: Every Sunday at midnight
- `@reboot`: On system boot

## Bash Features
- **Functions**: `func_name() { ... }`
- **Arrays**: `arr=("val1" "val2")`
- **Accessing Arrays**: `${arr[@]}` (all), `${#arr[@]}` (count)
- **Local variables**: `local var_name`
