#!/bin/bash
set -euo pipefail

# Directory configuration
PRIORITY_DIR=~/pr/priority

echo "🚀 MacBook Automation Bootstrap Script"
echo "======================================"

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Set up PATH for Homebrew
    echo "🔧 Setting up Homebrew PATH..."
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew is already installed"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install essential tools
echo "🛠️  Installing essential tools (uv, gh, git)..."
brew install uv gh git

# Get user details for configuration
echo "📝 Getting user details for configuration..."

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
            echo "✅ Details confirmed!"
            break
            ;;
        *)
            echo "Let's try again..."
            echo ""
            ;;
    esac
done

# Authenticate with GitHub CLI
echo "🔑 Authenticating with GitHub CLI..."
echo "Please follow the prompts to authenticate with GitHub:"
gh auth login

# Verify authentication
echo "✅ Verifying GitHub authentication..."
gh auth status

# Clone the repository
echo "📥 Cloning mac-automation repository..."
mkdir -p $PRIORITY_DIR
if [ -d $PRIORITY_DIR/mac-automation ]; then
    echo "Repository already exists, updating..."
    cd $PRIORITY_DIR/mac-automation
    #git pull
else
    gh repo clone divadvo/mac-automation $PRIORITY_DIR/mac-automation
    cd $PRIORITY_DIR/mac-automation
fi

# Update configuration with user details
echo "📝 Updating configuration with your details..."
sed -i.bak "s/user_email: \".*\"/user_email: \"$user_email\"/" roles/divadvo_mac/vars/main.yml
sed -i.bak2 "s/user_name: \".*\"/user_name: \"$user_name\"/" roles/divadvo_mac/vars/main.yml

echo ""
echo "🎉 Bootstrap complete!"
echo "📁 Repository location: $PRIORITY_DIR/mac-automation"
echo ""
echo "Next, navigate to the repository:"
echo "cd $PRIORITY_DIR/mac-automation"
echo ""
echo "👉 See README.md for Phase 2-4 instructions"