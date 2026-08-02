# Mobile Zellij

The shared macOS and Ubuntu configuration provides compact, phone-friendly
Zellij sessions for Claude, Codex, OpenCode, and generic project shells.

## Commands

From a project directory:

```bash
zj agent claude
zj agent codex
zj agent opencode
zj agent claude --name release-fix
zj agent claude --new
zj agent claude --awake
```

Default names are `<agent>-<project-directory>`. Existing sessions attach or
resurrect; absent sessions start the matching layout.

```bash
zellij ls
zellij a [session]
zj mirror <session>
zellij d <session>
zj clean-exited
zellij --layout project
```

Normal clients have independent cursors. `zj mirror` deliberately shares focus
and cursor movement. Exited-session cleanup requires confirmation and never
deletes active or aged sessions automatically.

## Persistence and clipboard

Sessions serialize layouts and commands, but not viewport or scrollback text.
The runtime scroll buffer is 50,000 lines. Copying uses OSC 52 so text targets
the connecting terminal; no host-local `pbcopy` command is configured. Termius
must permit OSC 52 clipboard access.

The UI uses compact layouts, hidden pane frames, simplified glyphs, and native
`one-half-dark`/`dayfox` dark and light themes.

## Stay awake

On macOS, `--awake` wraps a newly launched agent in `caffeinate -dimsu` for the
life of that process, including while Zellij is detached. It does not change
global power settings, run on Ubuntu, persist after the agent exits, or guarantee
closed-lid MacBook operation.

Useful Termius shortcut-bar keys include Escape, Control, Tab, arrows, `/`, `-`,
and `|`. iOS may suspend Termius in the background; Zellij keeps the remote
process alive so it can be reattached later.
