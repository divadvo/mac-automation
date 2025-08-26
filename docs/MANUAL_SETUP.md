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

## Terminal and Shell Configuration

### iTerm2 Setup
1. **Import Catppuccin Frappé Color Scheme**
   - Open iTerm2 → Preferences (⌘+,)
   - Go to Profiles → Colors tab
   - Click "Color Presets..." → Import...
   - Navigate to `~/Downloads/iTerm2-Colors/catppuccin-frappe.itermcolors`
   - Select the imported "Catppuccin Frappé" preset

2. **Configure Scrollback Buffer**
   - In Profiles → Terminal tab
   - Set "Scrollback lines" to "Unlimited scrollback" or 50,000+ lines
   - Enable "Unlimited scrollback" checkbox (recommended)

3. **Set as Default Profile**
   - In Profiles tab, click "Other Actions..." → "Set as Default"

### Powerlevel10k Configuration
1. **Run Interactive Configuration**
   - Open iTerm2 and start a new terminal session
   - Run: `p10k configure`
   - This will automatically download and install MesloLGS NF fonts
   - Follow the interactive prompts to customize your prompt appearance
   - Your configuration will be saved to `~/.p10k.zsh`

2. **Font Installation Verification**
   - The fonts are automatically installed during `p10k configure`
   - If needed, manually go to iTerm2 → Preferences → Profiles → Text
   - Set Font to "MesloLGS NF" (should be auto-selected)

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

### System Permissions

#### iTerm2 Full Disk Access
1. **Enable Full Disk Access for iTerm2**
   - Go to System Preferences → Privacy & Security → Full Disk Access
   - Click the lock to make changes (enter your password)
   - Click "+" and add iTerm2 from Applications folder
   - This allows iTerm2 to access all files and folders

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
- [ ] iTerm2 Catppuccin Frappé color scheme imported
- [ ] iTerm2 scrollback buffer configured
- [ ] Powerlevel10k configured with `p10k configure`
- [ ] MesloLGS NF fonts installed and applied