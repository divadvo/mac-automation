#!/bin/bash
# Claude Code status line: model + context window with colors and icons

RST='\e[0m'
DIM='\e[2m'
CYAN='\e[38;5;111m'
GREEN='\e[38;5;114m'
YELLOW='\e[38;5;214m'
ORANGE='\e[38;5;208m'
RED='\e[38;5;196m'

input=$(cat)

eval "$(echo "$input" | jq -r '
  @sh "model=\(.model.display_name // "")",
  @sh "size=\(.context_window.context_window_size // 200000)",
  @sh "used_pct=\(.context_window.used_percentage // "")"
' 2>/dev/null)"

# --- Helpers ---
fmt_tokens() {
  local t=$1
  if [[ $t -ge 1000000 ]] 2>/dev/null; then
    echo "$((t / 1000000))m"
  elif [[ $t -ge 1000 ]] 2>/dev/null; then
    echo "$((t / 1000))k"
  else
    echo "${t:-0}"
  fi
}

semantic_color() {
  local pct=$1
  [[ ! "$pct" =~ ^[0-9]+$ ]] && pct=0
  if [[ $pct -le 50 ]]; then echo "$GREEN"
  elif [[ $pct -le 75 ]]; then echo "$YELLOW"
  elif [[ $pct -le 90 ]]; then echo "$ORANGE"
  else echo "$RED"; fi
}

# --- Model ---
out="${CYAN} ${model}${RST}"

# --- Context window ---
if [[ -n "$used_pct" && "$used_pct" != "null" ]]; then
  pct=${used_pct%.*}
  [[ ! "$pct" =~ ^[0-9]+$ ]] && pct=0
  [[ $pct -gt 100 ]] && pct=100

  estimated=$((pct * size / 100))
  color=$(semantic_color "$pct")

  # Progress bar (8 chars)
  filled=$((pct * 8 / 100))
  [[ $filled -gt 8 ]] && filled=8
  bar=""
  for ((i=0; i<filled; i++)); do bar+="▰"; done
  for ((i=filled; i<8; i++)); do bar+="▱"; done

  out+=" ${DIM}|${RST} ${color}${bar} $(fmt_tokens "$estimated")/$(fmt_tokens "$size") (${pct}%)${RST}"
fi

printf "%b\n" "$out"
