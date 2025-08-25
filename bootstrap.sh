#!/bin/bash
set -euo pipefail

# Configuration
PRIORITY_DIR=~/pr/priority
MAC_AUTOMATION_PREFIX="[BOOTSTRAP]"

echo "🚀 MacBook Automation Bootstrap Script"
echo "======================================"
echo

echo "=== PHASE 1: HOMEBREW SETUP ==="
echo

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "$MAC_AUTOMATION_PREFIX 📦 Installing Homebrew..."
    echo "--- Homebrew Installation Output ---"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "--- End Homebrew Installation ---"
    
    # Set up PATH for Homebrew
    echo "$MAC_AUTOMATION_PREFIX 🔧 Setting up Homebrew PATH..."
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "$MAC_AUTOMATION_PREFIX ✅ Homebrew is already installed"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
echo

echo "$MAC_AUTOMATION_PREFIX 🛠️  Installing essential tools (uv, gh, git)..."
echo "--- Brew Install Output ---"
brew install uv gh git
echo "--- End Brew Install ---"
echo

echo "=== PHASE 2: USER CONFIGURATION ==="
echo
echo "$MAC_AUTOMATION_PREFIX 📝 Getting user details for configuration..."

# Loop until user confirms details are correct
while true; do
    echo "Please enter your email address:"
    read -p "Email: " user_email
    echo "Please enter your full name:"
    read -p "Name: " user_name
    
    # Show captured values for verification
    echo ""
    echo "Please verify your details:"
    echo "  Email: '$user_email'"
    echo "  Name:  '$user_name'"
    echo ""
    
    # Ask for confirmation
    read -p "Are these details correct? (y/N): " confirm
    case $confirm in
        [Yy]|[Yy][Ee][Ss])
            echo "$MAC_AUTOMATION_PREFIX ✅ Details confirmed!"
            break
            ;;
        *)
            echo "$MAC_AUTOMATION_PREFIX Let's try again..."
            echo ""
            ;;
    esac
done
echo

echo "=== PHASE 3: GITHUB AUTHENTICATION ==="
echo
echo "$MAC_AUTOMATION_PREFIX 🔑 Authenticating with GitHub CLI..."
echo "$MAC_AUTOMATION_PREFIX You will be shown a device code to enter in GitHub."
echo "$MAC_AUTOMATION_PREFIX GitHub CLI will also ask about generating SSH keys."
echo ""
echo "$MAC_AUTOMATION_PREFIX Authentication steps:"
echo "$MAC_AUTOMATION_PREFIX   1. A device code will be displayed (e.g., ABCD-1234)"
echo "$MAC_AUTOMATION_PREFIX   2. Open GitHub mobile app → Settings → Applications → Device activation"
echo "$MAC_AUTOMATION_PREFIX   3. OR visit https://github.com/login/device in any browser"
echo "$MAC_AUTOMATION_PREFIX   4. Enter the device code when prompted"
echo "$MAC_AUTOMATION_PREFIX   5. Answer 'y' to generate SSH key when asked (recommended)"
echo ""
echo "--- GitHub CLI Authentication ---"
gh auth login --hostname github.com --git-protocol ssh --web
echo "--- End GitHub CLI Authentication ---"

echo "$MAC_AUTOMATION_PREFIX ✅ Verifying GitHub authentication..."
echo "--- GitHub Auth Status ---"
gh auth status
echo "--- End GitHub Auth Status ---"
echo

echo "=== PHASE 4: REPOSITORY SETUP ==="
echo
echo "$MAC_AUTOMATION_PREFIX 📥 Cloning mac-automation repository..."
mkdir -p $PRIORITY_DIR
if [ -d $PRIORITY_DIR/mac-automation ]; then
    echo "$MAC_AUTOMATION_PREFIX Repository already exists, updating..."
    cd $PRIORITY_DIR/mac-automation
    #git pull
else
    echo "--- Git Clone Output ---"
    gh repo clone divadvo/mac-automation $PRIORITY_DIR/mac-automation
    echo "--- End Git Clone ---"
    cd $PRIORITY_DIR/mac-automation
fi
echo

echo "$MAC_AUTOMATION_PREFIX 📝 Updating configuration with your details..."
sed -i.bak "s/user_email: \".*\"/user_email: \"$user_email\"/" roles/divadvo_mac/vars/main.yml
sed -i.bak2 "s/user_name: \".*\"/user_name: \"$user_name\"/" roles/divadvo_mac/vars/main.yml

echo
echo "======================================"
echo "🎉 BOOTSTRAP COMPLETE!"
echo "======================================"
echo "$MAC_AUTOMATION_PREFIX 📁 Repository location: $PRIORITY_DIR/mac-automation"
echo ""
echo "$MAC_AUTOMATION_PREFIX Next, navigate to the repository:"
echo "cd $PRIORITY_DIR/mac-automation"
echo ""
echo "$MAC_AUTOMATION_PREFIX 👉 See README.md for Phase 2-4 instructions"