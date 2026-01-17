# External Resources

This document contains useful external links and resources referenced from the original setup notes.

## Development Setup Guides

### Ruby on Rails
- [GoRails macOS Setup Guide](https://gorails.com/setup/macos/)
  - Comprehensive guide for Ruby on Rails development setup on macOS
  - Covers Ruby version management, database setup, and Rails installation

### SSH Configuration
- [Why does macOS keep asking for my SSH passphrase?](https://superuser.com/questions/1127067/why-does-macos-keep-asking-for-my-ssh-passphrase-ever-since-i-updated-to-macos-s)
  - Solutions for SSH password storage and keychain integration on macOS

## macOS Customization

### Menu Bar Configuration
- [MacBook Notch and Menu Bar Fixes](https://www.jessesquires.com/blog/2023/12/16/macbook-notch-and-menu-bar-fixes/)
  - Documentation for menu bar spacing adjustments
  - Solutions for notch-related display issues

### System Defaults
- [macOS Defaults Database](https://macos-defaults.com/)
  - Comprehensive database of macOS system defaults and configuration options
  - Community-maintained documentation of `defaults` commands

### Configuration References
- [Jeff Geerling's Mac Dev Playbook](https://github.com/geerlingguy/mac-dev-playbook)
  - Ansible-based macOS configuration for developers
  - Reference implementation for automated Mac setup

- [Jeff Geerling's Dotfiles (.osx)](https://github.com/geerlingguy/dotfiles/blob/master/.osx)
  - Source of many settings adapted for this project's Ansible implementation
  - Original extensive macOS defaults configuration script

- [Adam Johnson's mac-ansible](https://github.com/adamchainz/mac-ansible)
  - Another Ansible-based macOS configuration project
  - Alternative implementation and configuration ideas

### Community Resources
- [Reddit: How to manage non-default system settings](https://old.reddit.com/r/MacOS/comments/1bk3cgt/how_to_manage_setting_nondefault_system_settings/)
  - Community discussion on macOS configuration management
  - Tips and tricks for system customization

## Theme and Appearance

### iTerm2 Themes
- [Dracula theme for iTerm2](https://draculatheme.com/iterm)
  - Popular dark theme for terminal applications
  - Provides consistent color scheme across development tools

## Version Management

### Mise (Development Tools)
- [Mise Getting Started Guide](https://mise.jdx.dev/getting-started.html)
  - Official documentation for mise version manager
  - Configuration and usage examples

## PostgreSQL Setup

After automated installation, start PostgreSQL service:
```bash
brew services start postgresql@17
```
