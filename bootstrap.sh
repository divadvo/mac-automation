#!/bin/bash
set -euo pipefail

# Configuration
PRIORITY_DIR=~/pr/priority
MAC_AUTOMATION_PREFIX="[BOOTSTRAP]"

echo "🚀 MacBook Automation Bootstrap Script"
echo "======================================"
echo

echo "=== PART 1: HOMEBREW SETUP ==="
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

echo "=== PART 2: USER CONFIGURATION ==="
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

echo "=== PART 3: GITHUB AUTHENTICATION ==="
echo
echo "$MAC_AUTOMATION_PREFIX 🔑 Authenticating with GitHub CLI..."
echo "$MAC_AUTOMATION_PREFIX GitHub offers multiple modern authentication methods:"
echo "$MAC_AUTOMATION_PREFIX   • Passkeys (synced via iCloud Keychain) - RECOMMENDED"
echo "$MAC_AUTOMATION_PREFIX   • Sign in with Google"
echo "$MAC_AUTOMATION_PREFIX   • Traditional password + 2FA"
echo ""
echo "$MAC_AUTOMATION_PREFIX ✨ RECOMMENDED: Test your authentication first!"
echo "$MAC_AUTOMATION_PREFIX Before continuing, try logging into GitHub.com in your browser."
echo "$MAC_AUTOMATION_PREFIX If you have passkeys from another device, they should sync via iCloud."
echo ""
read -p "$MAC_AUTOMATION_PREFIX Would you like to open GitHub.com now to test login? (y/N): " open_github
if [ "$open_github" = "y" ] || [ "$open_github" = "Y" ] || [ "$open_github" = "yes" ] || [ "$open_github" = "Yes" ]; then
    echo "$MAC_AUTOMATION_PREFIX Opening GitHub.com in your browser..."
    open "https://github.com/login"
    echo "$MAC_AUTOMATION_PREFIX Please test your login, then return here."
    echo ""
fi
read -p "$MAC_AUTOMATION_PREFIX Have you verified you can log into GitHub.com? (y/N): " github_verified
echo ""
echo "$MAC_AUTOMATION_PREFIX Authentication flow:"
echo "$MAC_AUTOMATION_PREFIX   1. A device code will be displayed (e.g., ABCD-1234)"
echo "$MAC_AUTOMATION_PREFIX   2. Visit https://github.com/login/device in your browser"
echo "$MAC_AUTOMATION_PREFIX   3. Choose your preferred authentication method:"
echo "$MAC_AUTOMATION_PREFIX      • 'Sign in with Passkey' (if available)"
echo "$MAC_AUTOMATION_PREFIX      • 'Sign in with Google' (if you have Google account)"
echo "$MAC_AUTOMATION_PREFIX      • Enter password + 2FA (traditional method)"
echo "$MAC_AUTOMATION_PREFIX   4. GitHub CLI will ask about SSH key generation (answer 'y')"
echo ""
echo "--- GitHub CLI Authentication ---"
gh auth login --hostname github.com --git-protocol ssh --web
echo "--- End GitHub CLI Authentication ---"

if [ "$github_verified" != "y" ] && [ "$github_verified" != "Y" ] && [ "$github_verified" != "yes" ] && [ "$github_verified" != "Yes" ]; then
    echo "$MAC_AUTOMATION_PREFIX ⚠️  If authentication failed, try these steps:"
    echo "$MAC_AUTOMATION_PREFIX   1. iCloud Keychain sync: Go to System Settings → Apple ID → iCloud → Passwords & Keychain"
    echo "$MAC_AUTOMATION_PREFIX   2. Approve this Mac from another device if prompted"
    echo "$MAC_AUTOMATION_PREFIX   3. Wait a few minutes for passkey sync to complete"
    echo "$MAC_AUTOMATION_PREFIX   4. Use 'Sign in with Google' as alternative"
    echo "$MAC_AUTOMATION_PREFIX   5. Fallback: Retrieve password from Bitwarden manually"
    echo ""
fi

echo "$MAC_AUTOMATION_PREFIX ✅ Verifying GitHub authentication..."
echo "--- GitHub Auth Status ---"
gh auth status
echo "--- End GitHub Auth Status ---"
echo

echo "=== PART 4: REPOSITORY SETUP ==="
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
echo "$MAC_AUTOMATION_PREFIX Next steps:"
echo "cd $PRIORITY_DIR/mac-automation"
echo ""
echo "$MAC_AUTOMATION_PREFIX 🚀 Phase 2: Run the automated setup:"
echo "uv run ./playbook.yml"
echo ""
echo "$MAC_AUTOMATION_PREFIX 📖 For more details, see README.md"