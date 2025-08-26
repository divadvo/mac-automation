#!/usr/bin/env ruby
# bootstrap.rb - MacBook Automation Bootstrap Script (Ruby Version)
# Idempotent, location-independent bootstrap for mac-automation

require 'fileutils'
require 'yaml'
require 'net/http'
require 'uri'

class MacBootstrap
  PRIORITY_DIR = File.expand_path("~/pr/priority").freeze
  MAC_AUTOMATION_PREFIX = "[BOOTSTRAP]".freeze
  STATE_DIR = File.expand_path("~/.mac-bootstrap").freeze
  REPO_PATH = File.join(PRIORITY_DIR, "mac-automation").freeze
  CONFIG_PATH = File.join(REPO_PATH, "roles/divadvo_mac/vars/main.yml").freeze
  
  def initialize
    @changes_made = false
    FileUtils.mkdir_p(STATE_DIR)
    puts "🚀 MacBook Automation Bootstrap Script (Ruby)"
    puts "=" * 42
    puts
  end

  def run
    install_homebrew
    setup_tools
    get_user_config
    setup_github_auth
    setup_repository
    update_config
    
    if @changes_made
      puts
      puts "=" * 42
      puts "🎉 BOOTSTRAP COMPLETE!"
      puts "=" * 42
      puts "#{MAC_AUTOMATION_PREFIX} 📁 Repository location: #{REPO_PATH}"
      puts
      puts "#{MAC_AUTOMATION_PREFIX} Next steps:"
      puts "cd #{REPO_PATH}"
      puts
      puts "#{MAC_AUTOMATION_PREFIX} 🚀 Phase 2: Run the automated setup:"
      puts "uv run ./playbook.yml"
      puts
      puts "#{MAC_AUTOMATION_PREFIX} 📖 For more details, see README.md"
      puts
      puts "#{MAC_AUTOMATION_PREFIX} 🔄 Starting fresh shell with updated PATH..."
      exec("zsh")
    else
      puts
      puts "#{MAC_AUTOMATION_PREFIX} ✅ All steps already complete - no changes needed!"
      puts "#{MAC_AUTOMATION_PREFIX} 📁 Repository location: #{REPO_PATH}"
      puts "#{MAC_AUTOMATION_PREFIX} You can run: cd #{REPO_PATH} && uv run ./playbook.yml"
    end
  end

  private

  def step_completed?(step)
    File.exist?(File.join(STATE_DIR, step))
  end

  def mark_step_complete(step)
    FileUtils.touch(File.join(STATE_DIR, step))
    @changes_made = true
  end

  def run_step(step_name)
    if step_completed?(step_name)
      puts "#{MAC_AUTOMATION_PREFIX} ✅ #{step_name} already completed"
      return false
    end
    
    puts
    puts "=== #{step_name.upcase} ==="
    puts
    true
  end

  def run_command(command, description = nil)
    puts "#{MAC_AUTOMATION_PREFIX} #{description}" if description
    puts "--- Command Output ---" if description
    
    success = system(command)
    
    puts "--- End Command Output ---" if description
    
    unless success
      puts "#{MAC_AUTOMATION_PREFIX} ❌ Command failed: #{command}"
      exit(1)
    end
  end

  def install_homebrew
    return unless run_step("HOMEBREW SETUP")

    if command_exists?("brew")
      puts "#{MAC_AUTOMATION_PREFIX} ✅ Homebrew is already installed"
      run_command('eval "$(/opt/homebrew/bin/brew shellenv)"')
    else
      puts "#{MAC_AUTOMATION_PREFIX} 📦 Installing Homebrew..."
      ENV['NONINTERACTIVE'] = '1'
      run_command('/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
                 "📦 Installing Homebrew...")
      
      puts "#{MAC_AUTOMATION_PREFIX} 🔧 Setting up Homebrew PATH..."
      setup_homebrew_path
      run_command('eval "$(/opt/homebrew/bin/brew shellenv)"')
    end

    mark_step_complete("homebrew_setup")
  end

  def setup_homebrew_path
    brew_setup_line = 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    
    [File.expand_path("~/.zprofile"), File.expand_path("~/.zshrc")].each do |shell_file|
      next if File.exist?(shell_file) && File.read(shell_file).include?(brew_setup_line)
      
      puts "#{MAC_AUTOMATION_PREFIX} Adding Homebrew PATH to #{File.basename(shell_file)}"
      File.open(shell_file, 'a') { |f| f.puts(brew_setup_line) }
    end
  end

  def setup_tools
    return unless run_step("ESSENTIAL TOOLS")

    tools_to_install = []
    
    %w[uv gh git].each do |tool|
      unless homebrew_package_installed?(tool)
        tools_to_install << tool
        puts "#{MAC_AUTOMATION_PREFIX} #{tool}: Not installed via Homebrew"
      else
        puts "#{MAC_AUTOMATION_PREFIX} #{tool}: ✅ Already installed via Homebrew"
      end
    end
    
    if tools_to_install.empty?
      puts "#{MAC_AUTOMATION_PREFIX} ✅ All essential tools already installed via Homebrew"
    else
      puts "#{MAC_AUTOMATION_PREFIX} 🛠️  Installing missing tools: #{tools_to_install.join(', ')}"
      run_command("brew install #{tools_to_install.join(' ')}", "🛠️  Installing essential tools...")
    end

    mark_step_complete("tools_setup")
  end

  def get_user_config
    return unless run_step("USER CONFIGURATION")

    if config_already_set?
      puts "#{MAC_AUTOMATION_PREFIX} ✅ User configuration already set"
      config = load_existing_config
      @user_email = config['user_email']
      @user_name = config['user_name']
      puts "#{MAC_AUTOMATION_PREFIX} Using: #{@user_name} <#{@user_email}>"
      return
    end

    puts "#{MAC_AUTOMATION_PREFIX} 📝 Getting user details for configuration..."
    
    loop do
      print "Please enter your email address: "
      @user_email = gets.chomp
      print "Please enter your full name: "
      @user_name = gets.chomp
      
      puts
      puts "Please verify your details:"
      puts "  Email: '#{@user_email}'"
      puts "  Name:  '#{@user_name}'"
      puts
      
      print "Are these details correct? (y/N): "
      confirm = gets.chomp
      
      if confirm.match?(/^[Yy]([Ee][Ss])?$/)
        puts "#{MAC_AUTOMATION_PREFIX} ✅ Details confirmed!"
        break
      else
        puts "#{MAC_AUTOMATION_PREFIX} Let's try again..."
        puts
      end
    end

    mark_step_complete("user_config")
  end

  def setup_github_auth
    return unless run_step("GITHUB AUTHENTICATION")

    if github_authenticated?
      puts "#{MAC_AUTOMATION_PREFIX} ✅ Already authenticated with GitHub"
      run_command("gh auth status", "✅ Verifying GitHub authentication...")
      return
    end

    puts "#{MAC_AUTOMATION_PREFIX} 🔑 Authenticating with GitHub CLI..."
    puts "#{MAC_AUTOMATION_PREFIX} GitHub offers multiple modern authentication methods:"
    puts "#{MAC_AUTOMATION_PREFIX}   • Passkeys (synced via iCloud Keychain) - RECOMMENDED"
    puts "#{MAC_AUTOMATION_PREFIX}   • Sign in with Google"
    puts "#{MAC_AUTOMATION_PREFIX}   • Traditional password + 2FA"
    puts
    puts "#{MAC_AUTOMATION_PREFIX} ✨ RECOMMENDED: Test your authentication first!"
    puts "#{MAC_AUTOMATION_PREFIX} Before continuing, try logging into GitHub.com in your browser."
    puts "#{MAC_AUTOMATION_PREFIX} If you have passkeys from another device, they should sync via iCloud."
    puts

    print "#{MAC_AUTOMATION_PREFIX} Would you like to open GitHub.com now to test login? (y/N): "
    open_github = gets.chomp
    
    if open_github.match?(/^[Yy]([Ee][Ss])?$/)
      puts "#{MAC_AUTOMATION_PREFIX} Opening GitHub.com in your browser..."
      system("open 'https://github.com/login'")
      puts "#{MAC_AUTOMATION_PREFIX} Please test your login, then return here."
      puts
    end

    print "#{MAC_AUTOMATION_PREFIX} Have you verified you can log into GitHub.com? (y/N): "
    github_verified = gets.chomp
    
    puts
    puts "#{MAC_AUTOMATION_PREFIX} Authentication flow:"
    puts "#{MAC_AUTOMATION_PREFIX}   1. A device code will be displayed (e.g., ABCD-1234)"
    puts "#{MAC_AUTOMATION_PREFIX}   2. Visit https://github.com/login/device in your browser"
    puts "#{MAC_AUTOMATION_PREFIX}   3. Choose your preferred authentication method:"
    puts "#{MAC_AUTOMATION_PREFIX}      • 'Sign in with Passkey' (if available)"
    puts "#{MAC_AUTOMATION_PREFIX}      • 'Sign in with Google' (if you have Google account)"
    puts "#{MAC_AUTOMATION_PREFIX}      • Enter password + 2FA (traditional method)"
    puts "#{MAC_AUTOMATION_PREFIX}   4. GitHub CLI will ask about SSH key generation (answer 'y')"
    puts

    run_command("gh auth login --hostname github.com --git-protocol ssh --web",
               "🔑 Authenticating with GitHub CLI...")

    unless github_verified.match?(/^[Yy]([Ee][Ss])?$/)
      puts "#{MAC_AUTOMATION_PREFIX} ⚠️  If authentication failed, try these steps:"
      puts "#{MAC_AUTOMATION_PREFIX}   1. iCloud Keychain sync: Go to System Settings → Apple ID → iCloud → Passwords & Keychain"
      puts "#{MAC_AUTOMATION_PREFIX}   2. Approve this Mac from another device if prompted"
      puts "#{MAC_AUTOMATION_PREFIX}   3. Wait a few minutes for passkey sync to complete"
      puts "#{MAC_AUTOMATION_PREFIX}   4. Use 'Sign in with Google' as alternative"
      puts "#{MAC_AUTOMATION_PREFIX}   5. Fallback: Retrieve password from Bitwarden manually"
      puts
    end

    run_command("gh auth status", "✅ Verifying GitHub authentication...")

    mark_step_complete("github_auth")
  end

  def setup_repository
    return unless run_step("REPOSITORY SETUP")

    FileUtils.mkdir_p(PRIORITY_DIR)

    if Dir.exist?(REPO_PATH)
      puts "#{MAC_AUTOMATION_PREFIX} Repository already exists, validating..."
      
      Dir.chdir(REPO_PATH) do
        if Dir.exist?('.git')
          puts "#{MAC_AUTOMATION_PREFIX} ✅ Valid git repository found"
          # Could add git pull here if needed
        else
          puts "#{MAC_AUTOMATION_PREFIX} ⚠️  Directory exists but is not a git repository"
          FileUtils.rm_rf(REPO_PATH)
          clone_repository
        end
      end
    else
      clone_repository
    end

    Dir.chdir(REPO_PATH)
    mark_step_complete("repository_setup")
  end

  def clone_repository
    puts "#{MAC_AUTOMATION_PREFIX} 📥 Cloning mac-automation repository..."
    run_command("gh repo clone divadvo/mac-automation #{REPO_PATH}",
               "📥 Cloning mac-automation repository...")
  end

  def update_config
    return unless run_step("CONFIGURATION UPDATE")

    unless File.exist?(CONFIG_PATH)
      puts "#{MAC_AUTOMATION_PREFIX} ❌ Configuration file not found: #{CONFIG_PATH}"
      exit(1)
    end

    config = YAML.load_file(CONFIG_PATH)
    updated = false

    if config['user_email'] != @user_email
      puts "#{MAC_AUTOMATION_PREFIX} 📝 Updating email: #{config['user_email']} → #{@user_email}"
      config['user_email'] = @user_email
      updated = true
    end

    if config['user_name'] != @user_name
      puts "#{MAC_AUTOMATION_PREFIX} 📝 Updating name: #{config['user_name']} → #{@user_name}"
      config['user_name'] = @user_name
      updated = true
    end

    if updated
      File.write(CONFIG_PATH, YAML.dump(config))
      puts "#{MAC_AUTOMATION_PREFIX} ✅ Configuration updated successfully"
    else
      puts "#{MAC_AUTOMATION_PREFIX} ✅ Configuration already up to date"
    end

    mark_step_complete("config_update")
  end

  def command_exists?(command)
    system("which #{command} > /dev/null 2>&1")
  end

  def homebrew_package_installed?(package)
    system("brew list #{package} > /dev/null 2>&1")
  end

  def github_authenticated?
    system("gh auth status > /dev/null 2>&1")
  end

  def config_already_set?
    return false unless File.exist?(CONFIG_PATH)
    
    config = YAML.load_file(CONFIG_PATH)
    config['user_email'] != 'your@email.com' && 
    config['user_name'] != 'Your Name' &&
    !config['user_email'].nil? && 
    !config['user_name'].nil?
  rescue
    false
  end

  def load_existing_config
    YAML.load_file(CONFIG_PATH)
  rescue
    {}
  end
end

# Run the bootstrap if this file is executed directly
if __FILE__ == $0
  begin
    bootstrap = MacBootstrap.new
    bootstrap.run
  rescue Interrupt
    puts "\n#{MacBootstrap::MAC_AUTOMATION_PREFIX} ❌ Bootstrap interrupted by user"
    exit(1)
  rescue => e
    puts "\n#{MacBootstrap::MAC_AUTOMATION_PREFIX} ❌ Bootstrap failed: #{e.message}"
    puts e.backtrace.join("\n") if ENV['DEBUG']
    exit(1)
  end
end