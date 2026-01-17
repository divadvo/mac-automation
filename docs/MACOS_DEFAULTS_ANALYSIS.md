# Missing macOS Defaults Analysis

## Overview
This document compares the macOS defaults from the [macos-defaults.com](https://github.com/yannbertrand/macos-defaults) repository with your current Ansible automation to identify missing configurations.

**Analysis Date**: 2026-01-17
**Source Repository**: https://github.com/yannbertrand/macos-defaults
**Current Configuration**: `/roles/divadvo_mac/tasks/macos_defaults.yml`

## Analysis Summary

### What You Already Have
Your current configuration covers these areas well:
- **General UI/UX**: Save/print panel expansion, document save location, printer auto-quit, smart quotes/dashes
- **Trackpad**: Haptic feedback, right-click configuration, corner actions
- **Keyboard**: Key repeat rates, press-and-hold, auto-correct
- **Screenshots**: Location, format (PNG), shadow disabling
- **Finder**: Show/hide files and extensions, status bar, search scope, path display, desktop icons
- **Dock**: Size, position (left), recent apps, hidden app translucency, hot corners
- **Activity Monitor**: Main window on launch, show all processes
- **Safari**: Developer tools (with sandboxed container paths)
- **Mail**: Plain text email addresses
- **System**: Mouse acceleration, menu bar spacing, click-to-show desktop

## Missing Defaults by Category

### 1. Activity Monitor
**Domain**: `com.apple.ActivityMonitor`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `IconType` | int | Dock icon display type (0=CPU History, 1=CPU Usage, 2=Network, 3=Disk, 4=Memory) | 0 |
| `UpdatePeriod` | int | Update frequency in seconds (1=Very often, 2=Often, 5=Normally) | 5 |

### 2. Desktop
**Domain**: `com.apple.finder`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `CreateDesktop` | bool | Show/hide all desktop icons | true |
| `_FXSortFoldersFirstOnDesktop` | bool | Sort folders before files on desktop | false |

### 3. Dock
**Domain**: `com.apple.dock`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `autohide` | bool | Auto-hide the Dock | false |
| `autohide-delay` | float | Delay before Dock shows (seconds) | 0.2 |
| `autohide-time-modifier` | float | Animation speed for show/hide | 0.5 |
| `mineffect` | string | Minimize animation effect ("genie" or "scale") | "genie" |
| `scroll-to-open` | bool | Scroll on Dock icon to open/show windows | false |
| `static-only` | bool | Show only active apps in Dock | false |
| `enable-spring-load-actions-on-all-items` | bool | Enable spring loading for Dock items | false |

### 4. Finder
**Domain**: `com.apple.finder` and `NSGlobalDomain`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `ShowPathbar` | bool | Show path bar at bottom of Finder windows | false |
| `_FXSortFoldersFirst` | bool | Sort folders before files in all views | false |
| `FinderSpawnTab` | bool | Open folders in tabs instead of windows | false |
| `FXRemoveOldTrashItems` | bool | Auto-remove items from trash after 30 days | false |
| `QuitMenuItem` | bool | Allow quitting Finder via Cmd+Q | false |
| `NSTableViewDefaultSizeMode` | int | Sidebar icon size (1=Small, 2=Medium, 3=Large) | 2 |
| `NSToolbarTitleViewRolloverDelay` | float | Delay before showing full path in title | 0.5 |

**Domain**: `com.apple.universalaccess`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `showWindowTitlebarIcons` | bool | Show file icons in window title bars | true |

### 5. Keyboard
**Domain**: `NSGlobalDomain` and `com.apple.HIToolbox`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `AppleKeyboardUIMode` | int | Full keyboard access (0=Text boxes and lists, 3=All controls) | 0 |
| `AppleFnUsageType` | int | Fn key behavior (0=Do Nothing, 1=Change Input Source, 2=Show Emoji) | 0 |
| `com.apple.keyboard.fnState` | bool | Use F1, F2, etc. keys as standard function keys | false |

**Domain**: `kCFPreferencesAnyApplication`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `TSMLanguageIndicatorEnabled` | bool | Show input menu in menu bar | true |

### 6. Menubar
**Domain**: `com.apple.menuextra.clock`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `DateFormat` | string | Menu bar date/time format (e.g., "EEE d MMM HH:mm:ss") | system default |
| `FlashDateSeparators` | bool | Flash separators (:) in clock | false |

### 7. Messages
**Domain**: `com.apple.MobileSMS`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `MMSShowSubject` | bool | Show subject field in Messages | false |

### 8. Mission Control
**Domain**: `com.apple.dock` and `com.apple.spaces`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `mru-spaces` | bool | Auto-rearrange Spaces based on recent use | true |
| `expose-group-apps` | bool | Group windows by application in Mission Control | true |

**Domain**: `NSGlobalDomain`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `AppleSpacesSwitchOnActivate` | bool | Switch to Space with open windows for app | true |

**Domain**: `com.apple.spaces`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `spans-displays` | bool | Displays have separate Spaces | false |

### 9. Mouse
**Domain**: `NSGlobalDomain`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `com.apple.mouse.linear` | bool | Disable mouse acceleration (linear scaling) | false |

**Domain**: `com.apple.Terminal`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `FocusFollowsMouse` | bool | Terminal focus follows mouse | false |

### 10. Screenshots
**Domain**: `com.apple.screencapture`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `include-date` | bool | Include date in screenshot filename | true |
| `show-thumbnail` | bool | Show thumbnail after taking screenshot | true |

### 11. TextEdit
**Domain**: `com.apple.TextEdit`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `RichText` | bool | Use rich text mode by default | true |
| `SmartQuotes` | bool | Use smart quotes | true |

### 12. Trackpad
**Domain**: `com.apple.AppleMultitouchTrackpad`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `Dragging` | bool | Enable tap to drag | false |
| `DragLock` | bool | Enable drag lock | false |
| `TrackpadThreeFingerDrag` | bool | Three-finger drag | false |

### 13. Time Machine
**Domain**: `com.apple.TimeMachine`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `DoNotOfferNewDisksForBackup` | bool | Don't prompt to use new disks for backup | false |

### 14. Xcode (Developer-Specific)
**Domain**: `com.apple.dt.Xcode`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `ShowBuildOperationDuration` | bool | Show build duration in activity viewer | false |
| `IDEAdditionalCounterpartSuffixes` | array | Additional suffixes for counterpart files | [] |

### 15. Miscellaneous
**Domain**: Various

| Domain | Key | Type | Purpose | Default |
|--------|-----|------|---------|---------|
| `com.apple.helpviewer` | `DevMode` | bool | Help Viewer developer mode | false |
| `NSGlobalDomain` | `NSQuitAlwaysKeepsWindow` | bool | Restore windows when re-opening apps | false |
| `com.apple.LaunchServices` | `LSQuarantine` | bool | Enable Gatekeeper quarantine | true |
| `com.apple.Music` | `userWantsPlaybackNotifications` | bool | Show Music playback notifications | true |
| `NSGlobalDomain` | `NSCloseAlwaysConfirmsChanges` | bool | Ask to save changes when closing | false |
| `com.apple.CloudSubscriptionFeatures.optIn` | `545129924` | bool | Apple Intelligence opt-in | system default |

### 16. iOS Simulator (Developer-Specific)
**Domain**: `com.apple.iphonesimulator`

| Key | Type | Purpose | Default Value |
|-----|------|---------|---------------|
| `ScreenShotSaveLocation` | string | Screenshot save location | system default |

## Recommendations

### High Priority (Commonly Used)
1. **Dock autohide settings** - Better screen real estate management
2. **Mission Control `mru-spaces`** - Prevent auto-rearranging Spaces (set to false)
3. **Finder `ShowPathbar`** - Useful for file navigation
4. **Finder `_FXSortFoldersFirst`** - Better file organization
5. **Trackpad three-finger drag** - Popular accessibility/usability feature
6. **Screenshots `show-thumbnail`** - Modern macOS feature
7. **Mouse `linear`** - For users who want no mouse acceleration

### Medium Priority (Nice to Have)
1. **Activity Monitor update period and icon type** - System monitoring preferences
2. **Menubar clock format** - Customize date/time display
3. **Finder `FinderSpawnTab`** - Tabs vs windows preference
4. **Finder `FXRemoveOldTrashItems`** - Auto-cleanup
5. **TextEdit rich text default** - Document editing preference
6. **Time Machine disk prompting** - Reduce annoyance

### Low Priority (Specialized Use Cases)
1. **Xcode settings** - Only for iOS developers
2. **Simulator settings** - Only for iOS developers
3. **Messages subject field** - Specialized messaging use
4. **Terminal focus follows mouse** - Power user feature
5. **Help Viewer dev mode** - Developer-specific
6. **Apple Intelligence opt-in** - Privacy consideration

### Already Well Covered
Your configuration already includes most essential settings that the majority of users need, particularly around Finder, screenshots, keyboard, and basic UI/UX preferences.

## Implementation Approach

If you want to add these missing defaults:

1. **Group by priority** - Add high-priority items first
2. **Test individually** - Some settings may require logout/restart
3. **Document purpose** - Add comments explaining what each does
4. **Consider defaults** - Only set if different from system default
5. **Version compatibility** - Test on your macOS version (check compatibility notes in macos-defaults docs)

## Reference Commands

For each missing default, you can test it manually using:

```bash
# Read current value
defaults read <domain> <key>

# Set value
defaults write <domain> <key> -<type> <value>

# Reset to default
defaults delete <domain> <key>

# Restart affected app
killall <AppName>
```

## Next Steps

Consider which of these defaults align with your preferences:
1. **Add all missing defaults** to your Ansible role
2. **Add only high-priority defaults**
3. **Add defaults by category** (e.g., just Dock and Mission Control)
4. **Create a separate optional defaults file** for advanced/specialized settings

The choice depends on:
- How opinionated you want your automation to be
- Whether you want minimal or comprehensive coverage
- If you prefer to keep specialized (Xcode, Simulator) settings separate
