# mac-automation

I use this project to configure my MacBook the way I like it.
It contains Ansible code to install applications via Homebrew, generate SSH keys, configure dotfiles and macos settings, and automatically clone repositories.
That way I can set up a new MacBook quickly with all my preferred software and settings.

## Setup Process

This setup uses a streamlined **multi-phase approach** with GitHub CLI integration:

### Phase 0: Pre-Bootstrap Setup

Complete the [New Mac Setup](./docs/PREPARATION.md#new-mac-setup-phase-0) steps before running the bootstrap script.

### Phase 1: Bootstrap Setup

Run the Ruby bootstrap script to automatically set up everything (idempotent and can be safely re-run):

**One-liner (Recommended):**
```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/divadvo/mac-automation/main/bootstrap.rb)"
```

**Or step-by-step:**
```bash
cd /tmp
curl -sSL https://raw.githubusercontent.com/divadvo/mac-automation/main/bootstrap.rb -o bootstrap.rb
chmod +x bootstrap.rb
./bootstrap.rb
```

The bootstrap script will automatically:
- Install Homebrew and essential tools (uv, gh, git)
- Prompt for your email and name with verification
- Authenticate with GitHub CLI
- Clone this repository to `~/pr/github/mac-automation`
- Update configuration with your details

### Phase 2: Automated Setup

Run the main playbook for complete automated setup:
```bash
uv run ./playbook.yml --ask-become-pass
```

This will automatically:
- Generate SSH keys and upload them to GitHub
- Install all packages (homebrew, mise, uv tools, npm tools)
- Configure dotfiles and shell enhancements
- Clone your GitHub repositories to organized directory structure

### Phase 3: macOS System Configuration

Apply macOS system settings and preferences:
```bash
uv run ./playbook.yml --tags macos --ask-become-pass
```

**Important**: Log out and log back in after this step to ensure all macOS system settings take effect properly.

### Phase 4: Final Manual Steps

After logging back in:

1. **Manually configure installed applications:** Configure applications such as Raycast, Rectangle, VS Code, etc. See [MANUAL_SETUP.md](./docs/MANUAL_SETUP.md) for detailed instructions.

## Configuration

Edit `roles/divadvo_mac/vars/main.yml` to customize:

- `user_email`: Your email for SSH key generation and git configuration
- `priority_repos`: Important repositories to always clone
- `max_recent_repos`: Number of recent repositories to clone
- `projects_dir`, `github_dir`, `github_other_dir`, `sandbox_dir`: Directory paths for project organization
- `homebrew_packages`: Command-line tools to install via Homebrew
- `homebrew_cask_packages`: GUI applications to install via Homebrew Cask
- `uv_tools`: Python tools to install globally via uv
- `npm_tools`: Global npm packages to install
- `node_version`, `ruby_version`, `bun_version`: Runtime versions managed by mise
- `python_versions`: Python versions to install via uv
- `postgresql_version`: PostgreSQL version to install
- `use_ansible_macos_config`: Use Ansible tasks (true) or shell script (false) for macOS defaults

## Adding New Packages

To install additional packages after initial setup: edit `roles/divadvo_mac/vars/main.yml` to add packages, then run:

```bash
uv run ./playbook.yml --tags packages
```

## Troubleshooting

Run in step mode for debugging:
```bash
uv run ./playbook.yml --step -vvv --diff
uv run ./playbook.yml --step -vvv --diff --start-at-task "dotfiles links"
```


## Documentation

- [PREPARATION.md](./docs/PREPARATION.md) - Pre-automation setup and old Mac migration
- [MANUAL_SETUP.md](./docs/MANUAL_SETUP.md) - Post-automation manual tasks
- [TESTING.md](./docs/TESTING.md) - VM-based testing instructions
- [RESOURCES.md](./docs/RESOURCES.md) - External links and references
- [CLAUDE.md](./CLAUDE.md) - Development commands and project architecture

