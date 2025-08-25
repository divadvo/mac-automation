# divadvo/mac-automation - CLAUDE.md

## Project Overview

Ansible-based MacBook automation system with multi-phase setup workflow. Uses bootstrap script, GitHub CLI integration, and automatic SSH key management. See README.md for user setup instructions.

## Development Commands

### Running Playbooks
- **Setup, packages, config, repos**: `uv run ./playbook.yml`
- **Including macOS settings**: `uv run ./playbook.yml --tags all`
- **Debug mode**: `uv run ./playbook.yml --step -vvv --diff`
- **Start at specific task**: `uv run ./playbook.yml --step -vvv --diff --start-at-task "task name"`

### Run by Tags
- Setup/SSH: `uv run ./playbook.yml --tags setup`
- Packages: `uv run ./playbook.yml --tags packages`  
- Dotfiles: `uv run ./playbook.yml --tags config`
- Repositories: `uv run ./playbook.yml --tags repositories`
- macOS settings: `uv run ./playbook.yml --tags macos`

### Testing
- **VM testing**: `rm -rf ~/test/mac-automation/ && rsync -avh --progress --exclude .git/ /Volumes/My\ Shared\ Files/mac-automation/ ~/test/mac-automation/ && cd ~/test/mac-automation/ && uv run ./playbook.yml`

## Architecture

### Key Files
- **`bootstrap.sh`**: Phase 1 setup script (Homebrew, tools, GitHub auth, repo cloning)
- **`playbook.yml`**: Main Ansible playbook
- **`roles/divadvo_mac/`**: Single role containing all configuration

### Task Structure
- **`tasks/main.yml`**: Task orchestration with tags
- **`tasks/setup.yml`**: SSH keys + automatic GitHub upload
- **`tasks/packages.yml`**: Package management (brew, mise, uv, npm)
- **`tasks/config.yml`**: Dotfiles and application config
- **`tasks/macos.yml`**: macOS system defaults (with `never` tags)
- **`tasks/repositories.yml`**: GitHub repository cloning

### Configuration
- **`vars/main.yml`**: All variables including directory paths
- **`templates/`**: Jinja2 templates (git config, zshrc)
- **`files/dotfiles/`**: Static configuration files for symlinking

### Key Features
- **Bootstrap integration**: Single-command setup with input validation
- **SSH automation**: Key generation + automatic GitHub upload via `gh cli`
- **Git templating**: Dynamic git config using user details from vars
- **Directory variables**: Configurable paths (`priority_dir`, `recent_dir`, `projects_dir`)
- **macOS separation**: System settings isolated in macos.yml with `never` tags

### Package Management
- **Homebrew**: System packages and applications
- **mise**: Runtime versions (Node.js, Ruby, Bun)
- **uv**: Python tools and versions
- **npm**: Global JavaScript tools

### Repository Management
- Uses GitHub CLI for authentication and discovery
- Priority repos → `{{ priority_dir }}` (always cloned)
- Recent repos → `{{ recent_dir }}` (limited by `max_recent_repos`)

## Configuration Variables

See README.md for user-configurable options. Key technical variables:
- `user_email`, `user_name`: Set by bootstrap script
- `priority_dir`, `recent_dir`, `projects_dir`: Directory structure
- `use_ansible_macos_config`: Ansible tasks vs shell script for macOS defaults

## Dependencies

- Python 3.13+ (pyproject.toml)
- uv for package management
- Ansible (via uv)
- Homebrew (installed by bootstrap)