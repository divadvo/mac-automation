# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible-based MacBook configuration system that automates the setup of a new Mac. It uses a multi-phase approach to install software, generate SSH keys, configure dotfiles, and clone repositories.

## Development Commands

### Running Playbooks
- **Main setup playbook**: `uv run ./playbook.yml`
- **Repository cloning playbook**: `uv run ./playbook-2.yml`
- **Debug mode**: `uv run ./playbook.yml --step -vvv --diff`
- **Start at specific task**: `uv run ./playbook.yml --step -vvv --diff --start-at-task "dotfiles links"`

### Testing in VM
- **Quick test setup**: `rm -rf ~/test/mac-automation/ && rsync -avh --progress --exclude .git/ /Volumes/My\ Shared\ Files/mac-automation/ ~/test/mac-automation/ && cd ~/test/mac-automation/ && uv run ./playbook.yml`

## Architecture

### Project Structure
- **`playbook.yml`**: Main playbook for Phase 2 setup (packages, SSH, dotfiles)
- **`playbook-2.yml`**: Repository cloning playbook for Phase 4
- **`roles/divadvo_mac/`**: Single Ansible role containing all configuration
  - **`tasks/main.yml`**: Orchestrates the three main task categories
  - **`tasks/setup.yml`**: SSH key generation and system setup
  - **`tasks/packages.yml`**: Package installation (homebrew, mise, uv, npm tools)
  - **`tasks/config.yml`**: Dotfiles symlinking and macOS configuration
  - **`tasks/repositories.yml`**: GitHub repository cloning logic
  - **`vars/main.yml`**: Main configuration variables
  - **`files/dotfiles/`**: Configuration files to be symlinked

### Task Organization
The role is organized into three main categories:
1. **System setup and SSH keys** (`setup.yml`) - Creates SSH keys and configures authentication
2. **Install packages and tools** (`packages.yml`) - Manages homebrew, mise, uv, and npm installations
3. **Configure dotfiles and settings** (`config.yml`) - Symlinks dotfiles and configures macOS defaults

### Package Management Strategy
- **Homebrew**: For system packages and cask applications
- **mise**: For runtime version management (Node.js, Ruby, Bun)
- **uv**: For Python tools and version management
- **npm**: For global JavaScript tools

### Configuration Management
- Variables defined in `roles/divadvo_mac/vars/main.yml`
- Dotfiles stored in `roles/divadvo_mac/files/dotfiles/`
- Symlinked to appropriate locations in home directory
- macOS defaults configured via `osx_defaults` module

### Repository Management
- Priority repositories always cloned to `~/pr/priority/`
- Recent repositories cloned to `~/pr/recent/` (limited by `max_recent_repos`)
- Uses GitHub CLI for repository discovery and authentication

## Key Configuration Files

### Variables (`roles/divadvo_mac/vars/main.yml`)
- `user_email`: Email for SSH key generation
- `homebrew_packages`: CLI tools to install via brew
- `homebrew_cask_packages`: Applications to install via brew cask
- `uv_tools`: Python tools to install via uv
- `priority_repos`: Important repositories to always clone
- `max_recent_repos`: Number of recent repositories to clone

### Ansible Configuration (`ansible.cfg`)
- Uses local inventory only
- YAML output format for better readability
- Task debugger enabled for troubleshooting

## Dependencies

The project requires:
- **Python 3.13+** (managed via `pyproject.toml`)
- **uv** for Python package management
- **Ansible** (installed via uv dependencies)
- **Homebrew** (installed manually in Phase 1)