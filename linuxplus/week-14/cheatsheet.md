# Week 14 Cheatsheet: Commands & Syntax

| Command | Description | Example |
|---------|-------------|---------|
| `crontab -e` | Edit crontab | `crontab -e` |
| `crontab -l` | List jobs | `crontab -l` |
| `set -e`     | Exit on error | `set -e` |
| `set -u`     | Error on unset vars | `set -u` |
| `set -o pipefail` | Exit if pipe fails | `set -o pipefail` |
| `trap`       | Trap signals | `trap 'command' SIGNAL` |

## Cron Time Format
`MIN HOUR DOM MON DOW`
- `DOM`: Day of Month (1-31)
- `MON`: Month (1-12)
- `DOW`: Day of Week (0-6, 0=Sunday)

## Bash Array Syntax
- `declare -a arr`: Declare indexed array
- `arr=("a" "b")`: Initialize
- `${arr[0]}`: Access first element
- `${arr[@]}`: All elements
- `${#arr[@]}`: Length of array
- `arr+=("c")`: Append element
