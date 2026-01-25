# Manual Setup Tasks

This document covers tasks that require manual intervention after running the automation playbooks.


## Terminal and Shell Configuration

### Powerlevel10k Configuration
1. **Run Interactive Configuration**
   - Open iTerm2 and start a new terminal session a few times until the p10k config WITH the font install appears.
   - Run: `p10k configure`
   - This will automatically download and install MesloLGS NF fonts
   - Follow the interactive prompts to customize your prompt appearance
   - Your configuration will be saved to `~/.p10k.zsh`

2. **Font Installation Verification**
   - The fonts are automatically installed during `p10k configure`
   - If needed, manually go to iTerm2 → Preferences → Profiles → Text
   - Set Font to "MesloLGS NF" (should be auto-selected)

### iTerm2 Setup
1. **Import Catppuccin Frappé Color Scheme**
   - Open iTerm2 → Preferences (⌘+,)
   - Go to Profiles → Colors tab
   - Click "Color Presets..." → Import...
   - Navigate to the `downloads/iTerm2-Colors/catppuccin-frappe.itermcolors` file in this repository
   - Select the imported "Catppuccin Frappé" preset

2. **Configure Scrollback Buffer**
   - In Profiles → Terminal tab
   - Set "Scrollback lines" to "Unlimited scrollback" or 50,000+ lines
   - Enable "Unlimited scrollback" checkbox (recommended)

3. **Set as Default Profile**
   - In Profiles tab, click "Other Actions..." → "Set as Default"



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

### Raycast
1. **Initial Setup**
   - Open Raycast (installed via automation)
   - Grant accessibility permissions when prompted
   - Set hotkey (default: ⌘ + Space, or change if conflicts with Spotlight)

2. **Essential Extensions**
   - Install GitHub extension for repository management
   - Install System Preferences extension for quick settings access
   - Install Calculator and Unit Converter for productivity

3. **Configure Search Providers**
   - Add Google, Stack Overflow, and documentation sites
   - Customize default search engines for development

### Rectangle
1. **Window Management Setup**
   - Open Rectangle (installed via automation)
   - Grant accessibility permissions when prompted
   - Review and customize keyboard shortcuts:
     - Left Half: ⌘ + ← (default)
     - Right Half: ⌘ + → (default)
     - Maximize: ⌘ + ↑ (default)
     - Center: ⌘ + ↓ (customize if needed)

2. **Additional Configuration**
   - Enable "Launch on login" for persistent window management
   - Adjust gap sizes between windows if desired

### Visual Studio Code
1. **Settings Sync**
   - Open VS Code (installed via automation)
   - Sign in with GitHub/Microsoft account
   - Enable Settings Sync to restore extensions and preferences

2. **Essential Extensions** (if not synced)
   - Prettier for code formatting
   - Language-specific extensions for your development stack

### OrbStack
1. **Docker Alternative Setup**
   - Open OrbStack (installed via automation)
   - Complete initial setup and resource allocation
   - Configure Docker CLI integration if migrating from Docker Desktop
   - Set up Linux VMs if needed for development

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

## System Utilities Configuration

### BetterDisplay
1. **Display Management Setup**
   - Open BetterDisplay (installed via automation)
   - Grant screen recording permissions when prompted
   - Configure custom resolutions for external displays if needed
   - Set up display switching shortcuts for multiple monitor setups

### UnnaturalScrollWheels
1. **Mouse Scroll Configuration**
   - Open UnnaturalScrollWheels (installed via automation)
   - Configure scroll direction preferences (natural vs. traditional)
   - Set per-device scroll settings if using multiple input devices
   - Enable "Launch on login" for persistent settings

### CleanShot
1. **Screenshot Tool Setup**
   - Open CleanShot (installed via automation)
   - Grant screen recording permissions when prompted
   - Configure capture shortcuts:
     - Area screenshot: ⌘ + Shift + 4 (or customize)
     - Window screenshot: ⌘ + Shift + 5 (or customize)
   - Set default save location and file format preferences
   - Configure annotation tools and cloud sync if desired

## Security Applications

### Bitwarden
1. **Password Manager Setup**
   - Open Bitwarden (installed via automation)
   - Sign in with your existing Bitwarden account or create new account
   - Configure browser extension integration (download from web store)
   - Enable biometric unlock (Touch ID/Face ID) for quick access
   - Set up autofill preferences in System Preferences → Passwords → AutoFill Passwords
   - Configure desktop app to start on login for persistent access

## Web Browsers and Communication

### Web Browsers (Chrome, Brave, Firefox)
1. **Profile Sync**
   - Sign in to browser account (Google, Brave, Mozilla)
   - Enable bookmark and settings sync
   - Set as default browser if preferred (System Preferences → General → Default web browser)

### Communication Apps (WhatsApp, Discord, Zoom)
1. **Account Setup**
   - WhatsApp: Scan QR code with phone app
   - Discord: Sign in with existing account
   - Zoom: Sign in and configure audio/video preferences
   - TeamViewer: Create account or sign in for remote access

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

### Application Configuration
- [ ] Adobe Creative Cloud signed in and apps installed
- [ ] JetBrains Toolbox signed in and IDEs installed  
- [ ] Microsoft Office signed in and activated
- [ ] Raycast configured with hotkey and essential extensions
- [ ] Rectangle window management shortcuts configured
- [ ] VS Code settings synced and extensions installed
- [ ] OrbStack Docker integration configured

### System Utilities
- [ ] BetterDisplay permissions granted and displays configured
- [ ] UnnaturalScrollWheels scroll preferences set
- [ ] CleanShot permissions granted and shortcuts configured

### Security
- [ ] Bitwarden signed in and browser extensions installed
- [ ] Bitwarden biometric unlock configured

### Web and Communication
- [ ] Default web browser set and synced
- [ ] WhatsApp, Discord, Zoom accounts configured
- [ ] Tailscale VPN connected

### Terminal and Development
- [ ] iTerm2 Catppuccin Frappé color scheme imported
- [ ] iTerm2 scrollback buffer configured
- [ ] Powerlevel10k configured with `p10k configure`
- [ ] MesloLGS NF fonts installed and applied
- [ ] GitHub CLI authenticated
- [ ] All development tools working

### System Configuration
- [ ] iCloud Photos sync configured
- [ ] Apple Music sync configured
- [ ] Printer added and configured
- [ ] Manual Finder/Dock preferences set