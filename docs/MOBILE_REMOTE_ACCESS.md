# Mobile Remote Access

Use this private path without public router forwarding:

```text
Termius on iPhone → Tailscale → SSH or Mosh → macOS or Ubuntu
```

## Tailscale and Termius

Sign in to the same Tailscale tailnet on macOS, Ubuntu, and iPhone. Use the
host's MagicDNS name or `tailscale ip -4` address in Termius. On Ubuntu,
`TAILSCALE_AUTH_KEY` can authenticate non-interactively; otherwise run
`sudo tailscale up` after setup.

In Termius, open **Settings → SSH ID**, complete the device-bound setup, and
record the public handle. Select SSH ID in the host's credentials. Private keys
remain on the device; rerun synchronization after adding another device.

## macOS

Set these untracked Ansible variables:

```yaml
remote_access_enabled: true
sshid_handle: "your-handle"
ssh_key_only_auth: false
remote_access_allowed_users:
  - "your-macos-short-name"
```

Run the `remote-access` tag with become credentials. Remote Login is enabled
only after SSH configuration validation.

## Ubuntu

```bash
ENABLE_REMOTE_ACCESS=1 SSHID_HANDLE=your-handle ./ubuntu-setup.sh
```

Add `TAILSCALE_FIREWALL=1` only to create UFW allowances scoped to
`tailscale0`. Existing rules are preserved and UFW is not enabled automatically.
UDP 60000–61000 is never opened publicly.

## Key-only rollout and recovery

Keep the current session open and verify SSH-ID login from a second Termius
session before setting `ssh_key_only_auth: true` or `SSH_KEY_ONLY_AUTH=1`.
The strict mode disables passwords, keyboard-interactive authentication, and
root login. If login fails, use the original session or local console to revert
the switch or remove the managed drop-in, then validate before reload.

SSH-ID downloads are validated before only the marked `authorized_keys` block
is replaced. Unrelated keys remain intact and failed downloads preserve the last
valid block.

## Mosh and forwarding

Discover the server command rather than hardcoding a Homebrew path:

```bash
MOSH_SERVER_PATH="$(command -v mosh-server)"
printf '%s new -s -c 256 -l LANG=en_US.UTF-8\n' "$MOSH_SERVER_PATH"
```

Paste it into Termius's Mosh server-command field. Mosh survives network changes
but does not support SSH port forwarding; use a separate Termius SSH forwarding
entry over Tailscale for development servers.

iOS can suspend Termius in the background even with Live Activities enabled.
Useful shortcut-bar keys include Escape, Control, Tab, arrows, `/`, `-`, and `|`.
