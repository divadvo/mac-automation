# mac-automation

I use this project to configure my MacBook the way I like it.
It contains Ansible code to install software and set up configuration files through symlinks to this repository.
That way I can set up a new MacBook quickly.

## What it does

- Installs development tools via Homebrew (CLI tools, GUI apps, runtime versions)
- Generates SSH keys and automatically uploads them to GitHub
- Configures dotfiles and macOS system settings
- Clones your GitHub repositories automatically

## Setup Process

This setup uses a streamlined **4-phase approach** with GitHub CLI integration:

### Phase 1: Bootstrap Setup

1. **Install Homebrew:**
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   *Note: This automatically installs Xcode Command Line Tools if needed*

2. **Set up PATH for Homebrew:**
   ```bash
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

3. **Install essential tools:**
   ```bash
   brew install uv gh git
   ```

4. **Configure git with your details:**
   ```bash
   git config --global user.email "your-email@example.com"
   git config --global user.name "Your Name"
   ```

5. **Authenticate with GitHub CLI:**
   ```bash
   gh auth login
   ```
   Follow the prompts to authenticate with your GitHub account.

6. **Clone this repository:**
   ```bash
   mkdir -p ~/pr/priority
   gh repo clone divadvo/mac-automation ~/pr/priority/mac-automation
   cd ~/pr/priority/mac-automation
   ```

7. **Update your email in the configuration:**
   Edit `roles/divadvo_mac/vars/main.yml` and change `user_email` to your actual email address:
   ```bash
   open -e roles/divadvo_mac/vars/main.yml
   ```

### Phase 2: Automated Setup

Run the main playbook for complete automated setup:
```bash
uv run ./playbook.yml
```

This will automatically:
- Generate SSH keys and upload them to GitHub
- Install all packages (homebrew, mise, uv tools, npm tools)
- Configure dotfiles and shell enhancements
- Clone your priority and recent GitHub repositories

### Phase 3: macOS System Configuration

Apply macOS system settings and preferences:
```bash
uv run ./playbook.yml --tags macos
```

**Important**: Log out and log back in after this step to ensure all macOS system settings take effect properly.

### Phase 4: Final Manual Steps

After logging back in:

1. **Manually configure installed applications:** Configure applications such as Raycast, Rectangle, VS Code, etc. See [MANUAL_SETUP.md](./docs/MANUAL_SETUP.md) for detailed instructions.

## Configuration

Edit `roles/divadvo_mac/vars/main.yml` to customize:

- `user_email`: Your email for SSH key generation and git configuration
- `priority_repos`: Important repositories to always clone to `~/pr/priority/`
- `max_recent_repos`: Number of recent repositories to clone to `~/pr/recent/`
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

