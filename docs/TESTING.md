# Testing in VM

Test the setup safely using Tart on the host:

```bash
# Install Tart
brew install cirruslabs/cli/tart

# Create VM (using vanilla image for clean testing)
tart clone ghcr.io/cirruslabs/macos-sequoia-vanilla:latest sequoia-vanilla
tart run --dir=mac-automation:~/pr/mac-automation:ro sequoia-vanilla

# To delete VM:
tart delete sequoia-vanilla
```

Inside the VM run, install clipboard support:

```bash
brew install cirruslabs/cli/tart
```

## Quick VM Recreation

To quickly recreate a fresh VM for testing:

```bash
tart delete sequoia-vanilla && tart clone ghcr.io/cirruslabs/macos-sequoia-vanilla:latest sequoia-vanilla && tart run --dir=mac-automation:~/pr/mac-automation:ro sequoia-vanilla
```

## Development Testing in VM

To test playbook changes from shared folders in the VM:

```bash
# Copy from shared folder to VM local directory
rm -rf ~/test/mac-automation/
rsync -avh --progress --exclude .git/ /Volumes/My\ Shared\ Files/mac-automation/ ~/test/mac-automation/
cd ~/test/mac-automation/

# Run playbooks (with testing mode for faster execution)
uv run ./playbook.yml -e testing_mode=true
```

One-liner for quick testing:
```bash
rm -rf ~/test/mac-automation/ && rsync -avh --progress --exclude .git/ /Volumes/My\ Shared\ Files/mac-automation/ ~/test/mac-automation/ && cd ~/test/mac-automation/ && uv run ./playbook.yml -e testing_mode=true
```

Or clone and run:

```bash
git stash && git pull && git stash pop && uv run ./playbook.yml -e testing_mode=true
```

## Tart Image Variants

**Recommended: `-vanilla` image**
- Minimal macOS installation with almost no additional software
- Ideal for testing clean automation scripts
- Better represents a fresh Mac out-of-the-box experience

**Alternative: `-base` image**  
- Includes pre-installed development tools (Xcode CLI tools, Homebrew, etc.)
- Larger download but faster initial setup
- May mask automation issues that only appear on truly clean systems

For detailed differences, see the [official image templates repository](https://github.com/cirruslabs/macos-image-templates).

**Why we use `-vanilla`**: Testing with the minimal image ensures our automation works on completely fresh Macs, catching any missing prerequisites or setup steps.
