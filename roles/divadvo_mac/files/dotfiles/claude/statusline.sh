#!/bin/sh
# Claude Code status line: model + context window usage

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // ""')
size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')

# Format token counts as "15.2k" style
fmt_tokens() {
  if [ "$1" -ge 1000000 ] 2>/dev/null; then
    printf "%.1fM" "$(echo "$1 / 1000000" | bc -l)"
  elif [ "$1" -ge 1000 ] 2>/dev/null; then
    printf "%.1fk" "$(echo "$1 / 1000" | bc -l)"
  else
    printf "%s" "${1:-0}"
  fi
}

parts=""
[ -n "$model" ] && parts="$model"

if [ -n "$input_tokens" ] && [ -n "$size" ]; then
  parts="$parts | $(fmt_tokens "$input_tokens")/$(fmt_tokens "$size") tokens (${used_pct:-0}%)"
fi

printf "%s\n" "$parts"
