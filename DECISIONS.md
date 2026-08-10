# Decisions

## agent skills
- Own skills live in `skills/` and are symlinked, not copied — the `skills` CLI copies, so repo edits would need a reinstall to take effect
- `~/.agents/skills` holds the one on-disk copy; Codex and OpenCode read it directly, Claude Code symlinks into it
- Third-party setup is additive — Claude plugin installs are never replaced, because plugins carry hooks and slash commands that the `skills` CLI drops
- ponytail installed as a native plugin on all three agents — full hook tier on Codex and OpenCode, not skill-only
- caveman on Codex is skill-only, per-session `/caveman` — upstream ships no Codex plugin build; native installer used for OpenCode where one exists
- `skills` CLI used only where the source is remote and has no plugin build: cloudflare, caveman-on-Codex
- Rejected: replacing all plugin installs with the `skills` CLI — one mechanism, but loses every hook

## repos
- houserules skill lives in this repo rather than its own — fewer repos to clone and wire per machine, and nothing in it is private
