#!/bin/sh
# Claude Code status line script
# Inspired by p10k prompt style: user@host dir [git branch] | model | context%

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd=$(echo "$cwd" | sed "s|^$home|~|")

# Git branch (skip optional locks)
branch=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
fi

# Build prompt segments
user_host="$(whoami)@$(hostname -s)"

if [ -n "$branch" ]; then
  dir_part="$short_cwd [$branch]"
else
  dir_part="$short_cwd"
fi

if [ -n "$used_pct" ]; then
  ctx_part="ctx: ${used_pct}%"
else
  ctx_part=""
fi

# Assemble with colors using printf
# Cyan for user@host, yellow for dir/branch, blue for model, dim for context
printf "\033[36m%s\033[0m \033[33m%s\033[0m" "$user_host" "$dir_part"

if [ -n "$model" ]; then
  printf " \033[34m%s\033[0m" "$model"
fi

if [ -n "$ctx_part" ]; then
  printf " \033[2m%s\033[0m" "$ctx_part"
fi

printf "\n"
