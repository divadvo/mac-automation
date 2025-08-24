# mac-automation


I use this project to configure my MacBook the way I like it.
It contains Ansible code to install software and set up configuration files through symlinks to this repository.
That way I can set up a new MacBook quickly.

## What it does

- Installs development tools via Homebrew (CLI tools, GUI apps, runtime versions)
- Generates SSH keys and sets up GitHub authentication  
- Configures dotfiles and macOS system settings
- Clones your GitHub repositories

## Setup Process

This setup uses a **five-phase approach** with minimal manual steps:

### Phase 1: Manual Pre-work

1. **Clone this repository:**
   ```bash
   mkdir -p ~/pr/priority
   git clone https://github.com/divadvo/mac-automation ~/pr/priority/mac-automation
   cd ~/pr/priority/mac-automation
   ```

2. **Install homebrew:**
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   *Note: This automatically installs Xcode Command Line Tools if needed*

3. **Install dependencies:**
   ```bash
   eval "$(/opt/homebrew/bin/brew shellenv)" && brew install uv
   ```

4. **Update your email:**
   Edit `roles/divadvo_mac/vars/main.yml` and change `user_email` to your actual email address. This command will open the editor:

   ```bash
   open -e roles/divadvo_mac/vars/main.yml
   ```

### Phase 2: First Playbook Execution

Run the main setup playbook:
```bash
uv run ./playbook.yml
```

This installs all software, generates SSH keys, sets up dotfiles, and configures macOS system preferences.

### Phase 3: Manual GitHub Authentication

Authenticate with GitHub CLI:
```bash
gh auth login
```

Follow the prompts to sign in to GitHub. Test authentication with:
```bash
gh auth status
```

### Phase 4: Repository Cloning

Clone your repositories:
```bash
uv run ./playbook.yml --tags repositories
```

This clones your priority repositories to `~/pr/priority/` and recent repositories to `~/pr/recent/`.

### Phase 5: Logout and Manual Configuration

**Please log out and log back in** to ensure all macOS system settings take effect properly.

After logging back in:

1. **Add SSH key to GitHub and other services (Optional):**
   
   Display your public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   
   Or copy directly to clipboard:
   ```bash
   pbcopy < ~/.ssh/id_ed25519.pub
   ```
   
   Copy the output and add it to your accounts:
   - **GitHub:** https://github.com/settings/ssh/new
   
   Test the connection:
   ```bash
   ssh -T git@github.com
   ```

2. **Manually configure all installed cask applications** such as Raycast, Rectangle, VS Code, etc. See [MANUAL_SETUP.md](./docs/MANUAL_SETUP.md) for detailed instructions.

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

