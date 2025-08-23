# mac-ansible


I use this project to configure my MacBook the way I like it.
It contains Ansible code to install software and set up configuration files through symlinks to this repository.
That way I can set up a new MacBook quickly.

## What it does

- Installs essential development tools (homebrew, git, gh, neovim, etc.)
- Generates fresh SSH keys and configures GitHub authentication
- Sets up dotfiles (zsh, git config, SSH config)
- Clones your important GitHub repositories to `~/pr/`
- Configures macOS settings and applications

## Setup Process

This setup uses a **four-phase approach** with minimal manual steps:

### Phase 1: Manual Pre-work

1. **Clone this repository:**
   ```bash
   git clone https://github.com/divadvo/mac-ansible
   cd mac-ansible
   ```

2. **Install homebrew:**
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   *Note: This automatically installs Xcode Command Line Tools if needed*

3. **Install dependencies:**
   ```bash
   brew install uv iterm2
   ```

4. **Open iTerm2** (for better terminal experience)

### Phase 2: First Playbook Execution

Run the main setup playbook:
```bash
uv run ./playbook.yml
```

This installs all software, generates SSH keys, and sets up dotfiles. At the end, you'll see instructions for Phase 3.

### Phase 3: Manual GitHub Authentication

Authenticate with GitHub CLI:
```bash
gh auth login
```

Follow the prompts to sign in to GitHub. Test authentication with:
```bash
gh auth status
```

### Phase 4: Second Playbook Execution

Clone your repositories:
```bash
uv run ./playbook-2.yml
```

This clones your priority repositories to `~/pr/priority/` and recent repositories to `~/pr/recent/`.

### Phase 5: SSH Key Setup (Optional)

Add your generated SSH key to GitHub and other services:

1. **Display your public key:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

   **Or copy directly to clipboard:**
   ```bash
   pbcopy < ~/.ssh/id_ed25519.pub
   ```

2. **Copy the output and add it to your accounts:**
   - **GitHub:** https://github.com/settings/ssh/new

3. **Test the connection:**
   ```bash
   ssh -T git@github.com
   ```

## Configuration

Edit `roles/divadvo_mac/vars/main.yml` to customize:
- `user_email`: Your email for SSH key generation
- `priority_repos`: Important repositories to always clone
- `max_recent_repos`: Number of recent repositories to clone

## Testing in VM

Test the setup safely using Tart:

```bash
# Install Tart
brew install cirruslabs/cli/tart

# Create VM
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest sequoia-base
tart run --dir=mac-ansible:~/pr/mac-ansible:ro sequoia-base

# Inside VM, install clipboard support
brew install cirruslabs/cli/tart
```

### Development Testing in VM

To test playbook changes from shared folders in the VM:

```bash
# Copy from shared folder to VM local directory
rm -rf ~/test/mac-ansible/
rsync -avh --progress --exclude .git/ /Volumes/My\ Shared\ Files/mac-ansible/ ~/test/mac-ansible/
cd ~/test/mac-ansible/

# Run playbooks
uv run ./playbook.yml
```

One-liner for quick testing:
```bash
rm -rf ~/test/mac-ansible/ && rsync -avh --progress --exclude .git/ /Volumes/My\ Shared\ Files/mac-ansible/ ~/test/mac-ansible/ && cd ~/test/mac-ansible/ && uv run ./playbook.yml
```

## Troubleshooting

Run in step mode for debugging:
```bash
uv run ./playbook.yml --step -vvv --diff
uv run ./playbook.yml --step -vvv --diff --start-at-task "dotfiles links"
```

## Resources

- [Dracula theme for iTerm2](https://draculatheme.com/iterm)
- [macOS defaults reference](https://macos-defaults.com/)

