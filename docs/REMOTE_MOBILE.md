# Mobile Remote Development

This repository supports an opt-in mobile workflow:

```text
Termius on iPhone → Tailscale → SSH or Mosh → Zellij → Claude/Codex/OpenCode
```

Nothing opens a public router port. macOS Remote Login and SSH authentication
changes are disabled by default. Ubuntu installs the server packages, but does
not change SSH authentication or firewall rules unless explicitly requested.

## 1. Connect the devices with Tailscale

1. On macOS, open the installed Tailscale app and sign in.
2. On iPhone, install Tailscale, sign in to the same tailnet, and enable its VPN.
3. On Ubuntu, the setup script installs and enables `tailscaled` from Tailscale's
   signed APT repository. Either provide an ephemeral/pre-authorized key:

   ```bash
   TAILSCALE_AUTH_KEY=tskey-auth-... ./ubuntu-setup.sh
   ```

   or run `sudo tailscale up` after provisioning.
4. In the Tailscale admin console, enable MagicDNS if you want stable hostnames.
   Otherwise find the host's tailnet IPv4 address with `tailscale ip -4`.

Do not forward TCP 22 or UDP 60000–61000 on the public router. Tailscale carries
the traffic privately between tailnet devices.

## 2. Use a device-bound SSH-ID identity

On each device, sign in to Termius, open **Settings → SSH ID**, and complete the
guided setup (including Face ID when offered). Note the public handle shown by
SSH ID. Edit the Termius host and select SSH ID in its key/credentials section;
do not select an unrelated imported key. Termius can then select that device's
device-bound key. Private keys cannot be exported; adding a device changes the
handle's public key set, so rerun the synchronization afterward. The automation
fetches public keys only from `https://sshid.io/<handle>`.

Before replacing a managed `authorized_keys` block, it downloads to a temporary
file, accepts supported SSH public-key lines, validates every line with
`ssh-keygen`, and atomically replaces only the marked block. Existing unrelated
keys are preserved. A failed download or validation leaves the last good block
untouched.

### macOS opt-in

Copy the example variables into your untracked `roles/divadvo_mac/vars/local.yml`:

```yaml
remote_access_enabled: true
sshid_handle: "your-handle"
ssh_key_only_auth: false
remote_access_allowed_users:
  - "your-macos-short-name"
```

Then run:

```bash
uv run ./playbook.yml --tags remote-access --ask-become-pass
```

This enables Remote Login, restricts SSH to the listed users, installs the
validated drop-in, and reloads OpenSSH only when the complete configuration is
valid. `remote_access_configure_firewall` deliberately does not alter the macOS
firewall; use the Tailscale address and keep public router forwarding disabled.

### Ubuntu opt-in

Run the script with the handle:

```bash
ENABLE_REMOTE_ACCESS=1 SSHID_HANDLE=your-handle ./ubuntu-setup.sh
```

By default this does not disable password login or alter firewall rules. To add
UFW allowances scoped to `tailscale0` for the effective SSH port and Mosh's UDP
range, add `TAILSCALE_FIREWALL=1`. The script preserves all existing UFW rules
and does not enable UFW automatically, so review `sudo ufw status numbered` for
pre-existing public allowances.

## 3. Verify before enabling key-only authentication

Keep the current working SSH session open. In a second Termius session:

1. Connect to the host's MagicDNS name or Tailscale IP.
2. Confirm Termius selected the SSH-ID identity.
3. Confirm login succeeds without the account password.
4. Check that `~/.ssh/authorized_keys` still contains any unrelated recovery key.
5. Validate the server before proceeding: `sudo sshd -t`.

Only after that successful second connection, set `ssh_key_only_auth: true` on
macOS or `SSH_KEY_ONLY_AUTH=1` on Ubuntu and rerun the relevant setup. The strict
mode enables public keys, disables password and keyboard-interactive login,
disables root login, limits authentication attempts, and adds keepalives.

Recovery: do not close the original session until another key-only login works.
If it fails, set the strict switch back to false and rerun, or use local/console
access to remove `/etc/ssh/sshd_config.d/99-mac-automation-remote-access.conf`.
Validate with `sshd -t` before reloading (`launchctl kickstart -k
system/com.openssh.sshd` on macOS or `systemctl reload ssh` on Ubuntu).

## 4. Configure Termius SSH and Mosh

Create a Termius host using the MagicDNS name or Tailscale IP, the actual account
username, and the SSH-ID identity. Connect with SSH first.

Mosh handles Wi-Fi/cellular changes and intermittent connectivity better than
plain SSH. Enable Mosh for the host only after SSH works. Discover the server
binary on the remote host rather than hardcoding a Homebrew architecture path:

```bash
MOSH_SERVER_PATH="$(command -v mosh-server)"
printf '%s new -s -c 256 -l LANG=en_US.UTF-8\n' "$MOSH_SERVER_PATH"
```

Paste the printed command into Termius's Mosh server-command field. This works
for Intel Homebrew, Apple Silicon Homebrew, and Ubuntu without a hardcoded path.
Mosh uses SSH for authentication, then UDP for the session. It does **not**
support SSH port forwarding. For a development server, create a separate
Termius SSH host/port-forward entry over Tailscale and keep the Zellij terminal
in Mosh.

On iPhone, allow Termius Live Activities if offered so a live connection is
easier to resume. iOS can still suspend network activity in the background;
Zellij is what preserves the remote process when that happens. Useful
shortcut-bar keys include Escape, Control, Tab, arrow
keys, `/`, `-`, and `|`; arrange them around the commands you use most. A
phone-friendly font with ordinary Unicode glyph coverage is safer than relying
on icon-only Nerd Font UI, which is why Zellij's simplified UI is enabled.

## 5. Use Zellij sessions

The repository keeps tmux and adds a mobile-oriented Zellij configuration. It
uses a compact UI, hidden pane frames, a 50,000-line runtime scroll buffer,
OSC 52 clipboard copying, and native `one-half-dark`/`dayfox` dark/light themes.

From a project directory:

```bash
zj agent claude
zj agent codex
zj agent opencode
zj agent claude --name release-fix
zj agent claude --new
zj agent claude --awake       # macOS only
```

The default name is `<agent>-<project-directory>`. Existing live or exited
sessions are attached/resurrected; otherwise the matching layout starts. Other
commands are:

```bash
zj list
zj attach [session]
zj mirror <session>
zj delete <session>
zj clean-exited
zellij --layout project
```

Normal laptop and phone clients have independent cursors. `zj mirror` is the
explicit true-mirroring mode where clients share focus/cursor movement. Session
resurrection stores layouts and commands but deliberately excludes pane viewport
and scrollback content. `zj clean-exited` requires interactive confirmation;
there is no automatic age-based cleanup.

OSC 52 asks the connecting terminal to receive copied text. It does not call
the remote Mac's `pbcopy`; Termius must permit OSC 52 clipboard access. Terminal
applications may impose their own clipboard-size or permission limits.

`--awake` wraps a newly launched macOS agent with `caffeinate -dimsu`. It remains
effective while that agent process lives, even if Zellij detaches, and stops when
the process exits. It does not change global power settings, run on Ubuntu, or
guarantee operation with a MacBook lid closed (clamshell behavior still depends
on power, display, and macOS hardware policy).

## 6. Enable Claude Pushover notifications

Create a Pushover application and record its 30-character application token and
your 30-character user key. Alerts include only hostname, project directory
name, and event category. Questions, prompts, answer choices, commands, tool
input, and response text are never sent. Codex and OpenCode do not receive push
hooks.

### macOS with 1Password

Create a 1Password item with fields for the application token and user key. Put
only their secret references in untracked local variables:

```yaml
pushover_notifications_enabled: true
pushover_app_token_ref: "op://Your Vault/Pushover/app token"
pushover_user_key_ref: "op://Your Vault/Pushover/user key"
pushover_device: "" # optional Pushover device name
```

Sign in/unlock 1Password CLI, then refresh the protected cache:

```bash
uv run ./playbook.yml --tags notifications
```

Both `op read` calls must succeed before Ansible atomically replaces
`~/.config/ai-notify/pushover.env`. A locked 1Password session cannot erase the
last good cache. Ansible suppresses resolved values from its output.

### Ubuntu local cache

For non-interactive setup, provide both values in the environment:

```bash
ENABLE_PUSHOVER=1 \
PUSHOVER_APP_TOKEN=... \
PUSHOVER_USER_KEY=... \
PUSHOVER_DEVICE=... \
./ubuntu-setup.sh
```

Interactive setup securely prompts for missing values. Existing non-empty
credentials are retained when the corresponding environment values are absent.
The cache directory is mode `0700` and the environment file mode `0600`.

Test parsing without contacting Pushover:

```bash
printf '%s\n' '{"cwd":"/tmp/example"}' \
  | ~/.claude/pushover-notify.sh --dry-run Stop
```

Actionable alerts use normal priority and completion alerts use low priority.
The hook respects Pushover quiet hours, gives alerts a bounded TTL, suppresses
duplicate project/event alerts for ten seconds, times out HTTP after five
seconds, logs failures without credentials, and always exits successfully.

## Further reading

- [Control Claude Code from iPhone with SSH + Zellij](https://tonydehnke.com/blog/claude-code-iphone-ssh-zellij/)
- [Push Notifications for Claude Code with ntfy + Hooks](https://tonydehnke.com/blog/claude-code-notifications-ntfy-hooks/)
- [Phone-to-laptop terminal mirroring guide](https://www.mpt.solutions/complete-phone-to-laptop-terminal-mirroring-setup-guide/)
