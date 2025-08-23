# Manual Setup Tasks

This document covers tasks that require manual intervention after running the automation playbooks.

## Application Configuration

### Adobe Creative Cloud
1. **Sign in to Creative Cloud**
   - Open Creative Cloud desktop app (installed via automation)
   - Sign in with your Adobe ID
   - Install required Creative Suite applications

### JetBrains Toolbox
1. **Configure JetBrains Toolbox**
   - Open JetBrains Toolbox (installed via automation)
   - Sign in with your JetBrains account
   - Install required IDEs (IntelliJ IDEA, WebStorm, etc.)

### Microsoft Office
1. **Sign in to Microsoft Office**
   - Open any Office application (installed via automation)
   - Sign in with your Microsoft 365 account
   - Activate license and sync settings

## System Services

### iCloud Synchronization
1. **Configure Photos sync**
   - Open Photos app
   - Verify iCloud Photos sync settings
   - Ensure sync options match your preferences

2. **Configure Music/iTunes sync**
   - Open Music app
   - Sign in to Apple Music if subscribed
   - Ensure computer is authorized for iTunes purchases
   - Configure Library sync options

### Network Services

#### Tailscale VPN
1. **Configure Tailscale**
   - Open Tailscale app (installed via automation)
   - Sign in with your Tailscale account
   - Connect to your tailnet

#### Printer Setup
1. **Add printer**
   - Go to System Preferences → Printers & Scanners
   - Click "+" to add printer
   - Follow setup wizard for your specific printer model

## Manual System Preferences

### Finder Configuration
While many Finder settings are automated, you may want to manually configure:
- Sidebar items and favorites
- Toolbar customization
- Advanced search preferences

### Dock Configuration
The automation configures basic dock settings, but you may want to manually:
- Add additional applications to dock
- Organize dock items
- Configure dock folders and stacks

## Project Migration

### Repository Access
The automation clones repositories via GitHub CLI, but ensure:
- GitHub CLI is authenticated (`gh auth status`)
- SSH keys are added to GitHub account
- Repository access permissions are correct

### Development Environment Verification
After automation completes, verify:
- All development tools are accessible in PATH
- Language versions are correct (`mise current`)
- Global packages are installed (`npm list -g`, `uv tool list`)

## Verification Checklist

- [ ] Adobe Creative Cloud signed in and apps installed
- [ ] JetBrains Toolbox signed in and IDEs installed  
- [ ] Microsoft Office signed in and activated
- [ ] iCloud Photos sync configured
- [ ] Apple Music sync configured
- [ ] Tailscale connected
- [ ] Printer added and configured
- [ ] GitHub CLI authenticated
- [ ] All development tools working
- [ ] Manual Finder/Dock preferences set