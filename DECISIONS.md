# Decisions

## agent skills
- Own skills live in `skills/` and are symlinked, not copied — the `skills` CLI copies, so repo edits would need a reinstall to take effect
- `~/.agents/skills` holds the one on-disk copy; Codex and OpenCode read it directly, Claude Code symlinks into it
- Third-party setup is additive — Claude plugin installs are never replaced, because plugins carry hooks and slash commands that the `skills` CLI drops
- ponytail installed as a native plugin on all three agents — full hook tier on Codex and OpenCode, not skill-only
- caveman on Codex is skill-only, per-session `/caveman` — upstream ships no Codex plugin build; native installer used for OpenCode where one exists
- `skills` CLI used only where the source is remote and has no plugin build: cloudflare, caveman-on-Codex
- Rejected: replacing all plugin installs with the `skills` CLI — one mechanism, but loses every hook
- Third-party skills reinstall on every run rather than skipping when present — a presence check freezes them at the first version installed and never picks up skills added upstream
- Optional installs warn on failure instead of aborting, but never fail silently — a no-op install and a working one look identical until the skill turns up missing

## repos
- houserules skill lives in this repo rather than its own — fewer repos to clone and wire per machine, and nothing in it is private
- Clone tasks use `creates` rather than filtering "already exists" out of the failure — a red rc=1 per existing repo every run trains you to skim past errors that matter
