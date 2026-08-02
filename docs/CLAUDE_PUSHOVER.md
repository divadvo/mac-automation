# Claude Pushover Notifications

Claude Code can send metadata-only Pushover alerts for questions, permission or
idle prompts, and completed turns. Messages contain only hostname, project
directory name, and event category. Prompt text, questions, options, commands,
tool input, and completion content are never sent. Codex and OpenCode are not
integrated.

Actionable alerts use normal priority, completion alerts use low priority, and
both respect quiet hours. The hook applies bounded TTLs, a ten-second duplicate
window, a five-second HTTP timeout, generic secret-free logging, and always exits
successfully.

## macOS

Create a Pushover application and store its application token and user key in a
1Password item. Put only secret references in untracked Ansible variables:

```yaml
pushover_notifications_enabled: true
pushover_app_token_ref: "op://Your Vault/Pushover/app token"
pushover_user_key_ref: "op://Your Vault/Pushover/user key"
pushover_device: ""
```

Run the `notifications` tag while 1Password CLI is unlocked. Both reads must
succeed before the mode-0600 cache is atomically replaced, so a locked session
cannot erase the last valid credentials.

## Ubuntu

Interactive runs securely prompt for missing values. Non-interactive runs use:

```bash
ENABLE_PUSHOVER=1 \
PUSHOVER_APP_TOKEN=... \
PUSHOVER_USER_KEY=... \
PUSHOVER_DEVICE=... \
./ubuntu-setup.sh
```

Existing non-empty cache values are preserved when corresponding environment
values are absent. The directory is mode 0700 and the file mode 0600.

## Maintainer dry run

```bash
printf '%s\n' '{"cwd":"/tmp/example"}' \
  | ~/.claude/pushover-notify.sh --dry-run Stop
```
