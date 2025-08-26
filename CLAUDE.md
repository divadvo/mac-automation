# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible-powered macOS automation project that configures a fresh MacBook with applications, dotfiles, system settings, and development tools. The project uses a multi-phase approach with GitHub CLI integration for streamlined setup.

## Essential Commands

### Running Playbooks
```bash
# Main playbook for complete setup
uv run ./playbook.yml

# Install packages only
uv run ./playbook.yml --tags packages

# Configure macOS system settings
uv run ./playbook.yml --tags macos

# Configure dotfiles only
uv run ./playbook.yml --tags dotfiles

# Clone repositories only
uv run ./playbook.yml --tags repositories

# Testing mode (minimal cask packages)
uv run ./playbook.yml -e testing_mode=true
```

### Development and Debugging
```bash
# Step-by-step execution with verbose output
uv run ./playbook.yml --step -vvv --diff

# Start from specific task
uv run ./playbook.yml --step -vvv --diff --start-at-task "dotfiles links"

# Install additional packages after initial setup
uv run ./playbook.yml --tags packages
```

## Architecture and Structure

### Core Components
- **playbook.yml**: Main Ansible playbook entry point with validation
- **roles/divadvo_mac/**: Primary role containing all automation tasks
- **bootstrap.rb**: Ruby script for initial system setup and GitHub authentication

### Role Task Organization
The `roles/divadvo_mac/tasks/main.yml` orchestrates these task files:
- **validate.yml**: System requirements and dependency validation
- **setup.yml**: SSH key generation and initial system setup
- **packages.yml**: Homebrew packages, mise tools, uv tools, npm packages
- **config.yml**: Dotfiles linking and shell configuration
- **repositories.yml**: GitHub repository cloning (priority and recent repos)
- **macos.yml**: macOS system settings and defaults (tagged as "never")

### Configuration Files
- **roles/divadvo_mac/vars/main.yml**: Main configuration file containing:
  - Package lists (homebrew_packages, homebrew_cask_packages, uv_tools, npm_tools)
  - User credentials (user_email, user_name)
  - Directory structure (projects_dir, priority_dir, recent_dir)
  - Runtime versions (node_version, ruby_version, python_versions)
  - Repository configuration (priority_repos, max_recent_repos)
  - Testing mode toggle (testing_mode)

### Multi-Phase Setup Process
1. **Bootstrap**: Run bootstrap.rb for Homebrew, GitHub CLI auth, repository cloning
2. **Automated Setup**: Main playbook for packages, dotfiles, repositories
3. **macOS Configuration**: System settings with `--tags macos`
4. **Manual Setup**: Application configuration (documented in docs/MANUAL_SETUP.md)

### Directory Structure Philosophy
- `~/pr/priority/`: Important repositories (defined in priority_repos)
- `~/pr/recent/`: Recent GitHub repositories (max_recent_repos limit)
- Uses GitHub CLI for repository operations

### Key Design Patterns
- **Idempotent Operations**: All tasks can be safely re-run
- **Tag-Based Execution**: Granular control with --tags flag
- **Testing Mode**: Minimal package installation via testing_mode variable
- **GitHub CLI Integration**: Handles authentication and repository cloning
- **VM Testing**: Tart-based testing with vanilla macOS images

## Important Notes

### Package Management
- Uses `testing_mode: true` for faster testing with minimal cask packages
- Optional packages are commented out in main.yml for easy toggling
- Package installation shows detailed progress during execution

### macOS Settings
- macOS configuration tasks are tagged as "never" - must be explicitly run
- Uses both Ansible osx_defaults and shell script approaches
- Requires logout/login after macOS settings changes

### Repository Management
- Priority repos are always cloned to priority directory
- Recent repos are fetched from GitHub API and cloned to recent directory
- Repository cloning can fail if local modifications exist (force=no)

### Testing and Development
- Step mode (`--step`) available for debugging task execution
- IMPORTANT: Please don't write or execute tests unless explicitly asked. I'll test myself manually with my own setup.