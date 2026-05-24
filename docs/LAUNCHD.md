# LaunchAgents

Per-user scheduled jobs installed via Ansible (`roles/divadvo_mac/tasks/launchd.yml`).

## Agents

| Label | Schedule | Script | Log |
|---|---|---|---|
| `com.divadvo.mac-upgrade` | daily 20:00 | `~/pr/github/divadvo-scripts/mac/d-mac-upgrade` | `~/Library/Logs/d-mac-upgrade.log` |

If the Mac is asleep at the scheduled time, launchd runs the job on next wake.

## Common operations

Replace `<LABEL>` with the agent label (e.g. `com.divadvo.mac-upgrade`).

```bash
# Watch log live
tail -f ~/Library/Logs/d-mac-upgrade.log

# Read log
less ~/Library/Logs/d-mac-upgrade.log

# Trigger a run now (executes the real command!)
launchctl kickstart -k gui/$(id -u)/<LABEL>

# Status / next-run info
launchctl print gui/$(id -u)/<LABEL> | less

# Disable (until next reload)
launchctl bootout gui/$(id -u)/<LABEL>

# Enable (or reload after editing the plist)
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<LABEL>.plist

# Re-apply via Ansible (handles unload + reload automatically on change)
cd ~/pr/github/mac-automation && uv run ./playbook.yml --tags launchd
```

## Adding a new agent

1. Add a Jinja template at `roles/divadvo_mac/templates/launchd/<label>.plist.j2`.
2. Add tasks in `roles/divadvo_mac/tasks/launchd.yml` mirroring the existing pattern (template + bootout-on-change + bootstrap-on-change).
3. Add a row to the table above.
