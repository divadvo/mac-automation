# Preparation Guide

This guide covers pre-automation steps for setting up a new Mac and migrating from an old Mac.


## Format Old Mac

Before setting up your new Mac, prepare your old Mac for handoff:

### Export Current Configuration

Save your current Homebrew setup:

```bash
# Export installed formulae (command-line tools)
brew leaves --installed-on-request > formulae.txt

# Export installed casks (GUI applications)
brew list --cask -l1 > casks.txt
```

### Sign Out of Licensed Software

Before formatting your old Mac:

- **Adobe Creative Cloud**: Sign out to free up license activation
- **Apple Music/iTunes**: Deauthorize computer (Account → Deauthorizations)
- Follow Apple's official guide: [What to do before you sell, give away, or trade in your Mac](https://support.apple.com/en-au/HT212749)


---

## New Mac Setup (Phase 0)

Complete these steps before running the bootstrap script:

1. **Complete macOS setup wizard** - Create your user account, set language/region
2. **Sign into Apple Account** - System Settings → Apple Account (enables iCloud, App Store)
3. **Connect Bluetooth peripherals** - Mouse, keyboard, etc.
4. **Sign into Google** - Open Safari → google.com → sign in
5. **Sign into GitHub** - Open Safari → github.com → sign in (can use Google account)

Once complete, proceed to [Phase 1: Bootstrap Setup](../README.md#phase-1-bootstrap-setup).
