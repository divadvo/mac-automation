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
- `asd-ste100` from danyuchn, not AminBlg/SimpleEnglish — AminBlg ships session hooks and a global output style that also govern chat replies, colliding with caveman and ponytail
- STE skill is structural rules only — ASD-STE100 Issue 9 is free to obtain but its ~900-word approved dictionary may not be redistributed
- STE goes through the `skills` CLI for Claude Code too, unlike cloudflare and caveman — it ships no plugin build for any agent, so there is nothing to install from a marketplace
- Rejected Vale as a prose linter — houserules §4 is don't-test-don't-verify, so a linter nobody runs is config debt
- Rejected a context7 rule in houserules — the MCP already ships its own prefer-me-over-web-search instruction
- houserules names skill precedence explicitly — four skills now govern overlapping surfaces, and three scattered ad-hoc mentions did not say who wins
- `skill-creator` is provisioned like any other plugin, with `anthropics/claude-plugins-official` as its source — `settings.json` enabled it while no install list carried it, so a fresh machine got the flag and no plugin

## repos
- houserules skill lives in this repo rather than its own — fewer repos to clone and wire per machine, and nothing in it is private
- Clone tasks use `creates` rather than filtering "already exists" out of the failure — a red rc=1 per existing repo every run trains you to skim past errors that matter

## dotfiles
- `WT_HOST` derived from `scutil --get LocalHostName` rather than hardcoded — the zshrc is machine-agnostic and ships to every Mac this repo sets up
- Tailscale MagicDNS left as a comment, not the value — it only resolves while Tailscale is running, and the mDNS name covers the same-wifi case
