#!/bin/bash
set -euo pipefail

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

# Configure git
echo "📝 Configuring git..."
echo "Please enter your email address for git configuration:"
read -p "Email: " user_email
echo "Please enter your full name for git configuration:"
read -p "Name: " user_name

git config --global user.email "$user_email"
git config --global user.name "$user_name"

# Authenticate with GitHub CLI
echo "🔑 Authenticating with GitHub CLI..."
echo "Please follow the prompts to authenticate with GitHub:"
gh auth login

# Verify authentication
echo "✅ Verifying GitHub authentication..."
gh auth status

# Clone the repository
echo "📥 Cloning mac-automation repository..."
mkdir -p ~/pr/priority
if [ -d ~/pr/priority/mac-automation ]; then
    echo "Repository already exists, updating..."
    cd ~/pr/priority/mac-automation
    #git pull
else
    gh repo clone divadvo/mac-automation ~/pr/priority/mac-automation
    cd ~/pr/priority/mac-automation
fi

# Update email in configuration
echo "📝 Updating configuration with your email..."
sed -i.bak "s/user_email: \".*\"/user_email: \"$user_email\"/" roles/divadvo_mac/vars/main.yml

echo ""
echo "🎉 Bootstrap complete! Next steps:"
echo "1. Run the main playbook: uv run ./playbook.yml"
echo "2. Apply macOS settings: uv run ./playbook.yml --tags macos"
echo "3. Log out and back in for macOS settings to take effect"
echo ""
echo "📁 Repository location: ~/pr/priority/mac-automation"