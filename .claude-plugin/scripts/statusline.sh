#!/usr/bin/env bash
# sloptrough statusline — context fill bar + session info
# Called by Claude Code with JSON session data on stdin
# Configure in settings.json:
#   "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
# Or symlink this file to ~/.claude/statusline.sh

input=$(cat)

# --- Parse session data ---
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
dir=$(basename "$(echo "$input" | jq -r '.workspace.current_dir // "."')")

# --- Identity ---
user=$(whoami)
host=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "localhost")

# --- Git status ---
work_dir=$(echo "$input" | jq -r '.workspace.current_dir // "."')
git_info=""
if cd "$work_dir" 2>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git diff --quiet 2>/dev/null; then
        git_info=$'\033[32m✓\033[0m'
    else
        git_info=$'\033[31m✗\033[0m'
    fi
fi

# --- Context fill bar ---
# 20-char bar: ▓ filled, ░ empty
# Green <50%, yellow 50-75%, red >=75%
bar_width=20
filled=$((ctx_pct * bar_width / 100))
empty=$((bar_width - filled))

if [ "$ctx_pct" -ge 75 ]; then
    bar_color="\033[31m"
elif [ "$ctx_pct" -ge 50 ]; then
    bar_color="\033[33m"
else
    bar_color="\033[32m"
fi

bar="${bar_color}$(printf '%*s' "$filled" '' | tr ' ' '▓')\033[38;5;240m$(printf '%*s' "$empty" '' | tr ' ' '░')\033[0m"

# --- Output ---
printf '\033[32m●\033[0m \033[34m%s\033[0m@\033[36m%s\033[0m in \033[35m%s\033[0m' "$user" "$host" "$dir"
[ -n "$git_info" ] && printf ' %s' "$git_info"
printf ' | %s | %b %s%%' "$model" "$bar" "$ctx_pct"
