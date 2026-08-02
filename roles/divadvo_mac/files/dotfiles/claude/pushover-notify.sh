#!/usr/bin/env bash
# Metadata-only Pushover notifications for Claude Code hooks.
# Hook failures must never block or alter Claude Code behavior.
set -u
umask 077

config_file="${AI_NOTIFY_CONFIG:-$HOME/.config/ai-notify/pushover.env}"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ai-notify"
log_file="$cache_dir/pushover.log"
dry_run=0

log_error() {
  mkdir -p "$cache_dir" 2>/dev/null || return 0
  printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$1" >> "$log_file" 2>/dev/null || true
}

if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=1
  shift
fi
event="${1:-}"
payload="$(cat 2>/dev/null || true)"

if ! command -v jq >/dev/null 2>&1; then
  log_error "jq is unavailable; notification skipped"
  exit 0
fi

cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
notification_type="$(printf '%s' "$payload" | jq -r '.notification_type // empty' 2>/dev/null || true)"
project="$(basename "${cwd:-unknown}" 2>/dev/null || printf 'unknown')"
[[ -n "$project" && "$project" != "/" ]] || project="unknown"
host="$(hostname -s 2>/dev/null || hostname 2>/dev/null || printf 'host')"

category=""
priority=0
ttl=86400
case "$event" in
  PreToolUse) category="Input required" ;;
  Notification)
    case "$notification_type" in
      permission_prompt) category="Permission required" ;;
      idle_prompt) category="Input required" ;;
      *) exit 0 ;;
    esac
    ;;
  Stop)
    category="Turn completed"
    priority=-1
    ttl=3600
    ;;
  *) exit 0 ;;
esac

title="Claude · ${project}"
message="${host} · ${category}"

if (( dry_run )); then
  jq -n \
    --arg event "$event" \
    --arg title "$title" \
    --arg message "$message" \
    --argjson priority "$priority" \
    --argjson ttl "$ttl" \
    '{event: $event, title: $title, message: $message, priority: $priority, ttl: $ttl}'
  exit 0
fi

if [[ ! -r "$config_file" ]]; then
  # No cache is the expected state when notifications are disabled.
  exit 0
fi
# shellcheck disable=SC1090
source "$config_file"

if [[ ! "${PUSHOVER_APP_TOKEN:-}" =~ ^[A-Za-z0-9]{30}$ || ! "${PUSHOVER_USER_KEY:-}" =~ ^[A-Za-z0-9]{30}$ ]]; then
  log_error "credential file is incomplete or invalid; notification skipped"
  exit 0
fi

mkdir -p "$cache_dir" 2>/dev/null || { exit 0; }
chmod 700 "$cache_dir" 2>/dev/null || true
state_slug="$(printf '%s-%s-%s' "$host" "$project" "$category" | tr -cs 'A-Za-z0-9._-' '_')"
state_file="$cache_dir/${state_slug}.last"
now="$(date +%s)"
if [[ -r "$state_file" ]]; then
  last="$(cat "$state_file" 2>/dev/null || printf '0')"
  if [[ "$last" =~ ^[0-9]+$ ]] && (( now - last < 10 )); then
    exit 0
  fi
fi

curl_args=(
  --silent --show-error --fail --max-time 5
  --data-urlencode "token=${PUSHOVER_APP_TOKEN}"
  --data-urlencode "user=${PUSHOVER_USER_KEY}"
  --data-urlencode "title=${title}"
  --data-urlencode "message=${message}"
  --data-urlencode "priority=${priority}"
  --data-urlencode "ttl=${ttl}"
)
if [[ -n "${PUSHOVER_DEVICE:-}" ]]; then
  curl_args+=(--data-urlencode "device=${PUSHOVER_DEVICE}")
fi

if curl "${curl_args[@]}" https://api.pushover.net/1/messages.json >/dev/null 2>>"$log_file"; then
  printf '%s\n' "$now" > "$state_file"
else
  log_error "Pushover API request failed"
fi
exit 0
