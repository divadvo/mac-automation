#!/usr/bin/env ruby
# bootstrap.rb - MacBook Automation Bootstrap Script (Ruby Version)
# Idempotent, location-independent bootstrap for mac-automation

require 'fileutils'
require 'yaml'

class MacBootstrap
  PRIORITY_DIR = File.expand_path("~/pr/priority").freeze
  PREFIX = "[BOOTSTRAP]".freeze
  STATE_DIR = File.expand_path("~/.mac-bootstrap").freeze
  REPO_PATH = File.join(PRIORITY_DIR, "mac-automation").freeze
  CONFIG_PATH = File.join(REPO_PATH, "roles/divadvo_mac/vars/main.yml").freeze
  
  def initialize
    @changes_made = false
    FileUtils.mkdir_p(STATE_DIR)
    log("🚀 MacBook Automation Bootstrap Script (Ruby)")
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
      show_completion_message
      exec("zsh")
    else
      log("All steps complete - no changes needed!", type: :success)
      log("📁 Repository: #{REPO_PATH}")
      log("Run: cd #{REPO_PATH} && uv run ./playbook.yml")
    end
  end

  private

  # Main step methods (following execution order)
  
  def install_homebrew
    return unless run_step("HOMEBREW SETUP")
    
    if system("which brew", out: File::NULL, err: File::NULL)
      log("Homebrew already installed", type: :success)
    else
      log("📦 Installing Homebrew...")
      ENV['NONINTERACTIVE'] = '1'
      run_command('/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"', "📦 Installing Homebrew...")
      
      # Setup PATH
      brew_line = 'eval "$(/opt/homebrew/bin/brew shellenv)"'
      [File.expand_path("~/.zprofile"), File.expand_path("~/.zshrc")].each do |file|
        next if File.exist?(file) && File.read(file).include?(brew_line)
        log("Adding Homebrew PATH to #{File.basename(file)}")
        File.open(file, 'a') { |f| f.puts(brew_line) }
      end
    end
    
    run_command('eval "$(/opt/homebrew/bin/brew shellenv)"')
    complete_step("HOMEBREW SETUP")
  end

  def setup_tools
    return unless run_step("ESSENTIAL TOOLS")
    
    # Ensure brew accessible
    unless system("which brew", out: File::NULL, err: File::NULL)
      ENV['PATH'] = "/opt/homebrew/bin:/opt/homebrew/sbin:#{ENV['PATH']}"
    end
    
    # Install missing tools
    missing_tools = []
    %w[uv gh git].each do |tool|
      if system("brew list #{tool}", out: File::NULL, err: File::NULL)
        log("#{tool}: Already installed", type: :success)
      else
        missing_tools << tool
        log("#{tool}: Missing")
      end
    end
    
    unless missing_tools.empty?
      log("🛠️ Installing: #{missing_tools.join(', ')}")
      brew_cmd = system("which brew", out: File::NULL, err: File::NULL) ? "brew" : "/opt/homebrew/bin/brew"
      run_command("#{brew_cmd} install #{missing_tools.join(' ')}", "🛠️ Installing tools...")
    end
    
    complete_step("ESSENTIAL TOOLS")
  end

  def get_user_config
    return unless run_step("USER CONFIGURATION")
    
    if config_set?
      config = YAML.load_file(CONFIG_PATH) rescue {}
      @user_email = config['user_email']
      @user_name = config['user_name']
      log("Using: #{@user_name} <#{@user_email}>", type: :success)
    else
      log("📝 Getting user details...")
      loop do
        print "Email: "; @user_email = gets.chomp
        print "Name: "; @user_name = gets.chomp
        puts "\nVerify:\n  Email: '#{@user_email}'\n  Name:  '#{@user_name}'\n"
        print "Correct? (y/N): "
        if gets.chomp.match?(/^[Yy]([Ee][Ss])?$/)
          log("Confirmed!", type: :success); break
        else
          log("Try again..."); puts
        end
      end
    end
    
    complete_step("USER CONFIGURATION")
  end

  def setup_github_auth
    return unless run_step("GITHUB AUTHENTICATION")
    
    if system("gh auth status", out: File::NULL, err: File::NULL)
      log("GitHub already authenticated", type: :success)
      run_command("gh auth status", "✅ Verifying...")
    else
      # Instructions
      [
        "🔑 Authenticating with GitHub CLI...",
        "Methods: Passkeys (recommended), Google, or password+2FA",
        "✨ Test login at GitHub.com first if possible"
      ].each { |message| log(message) }
      
      print "#{PREFIX} Open GitHub.com to test? (y/N): "
      if gets.chomp.match?(/^[Yy]([Ee][Ss])?$/)
        log("Opening browser...")
        system("open 'https://github.com/login'")
      end
      
      puts "\nFlow: device code → https://github.com/login/device → choose auth method\n"
      run_command("gh auth login --hostname github.com --git-protocol ssh --web", "🔑 Authenticating...")
      run_command("gh auth status", "✅ Verifying...")
    end
    
    complete_step("GITHUB AUTHENTICATION")
  end

  def setup_repository
    return unless run_step("REPOSITORY SETUP")
    
    FileUtils.mkdir_p(PRIORITY_DIR)
    
    if Dir.exist?(REPO_PATH)
      log("Repository exists, validating...")
      Dir.chdir(REPO_PATH) do
        if Dir.exist?('.git')
          log("Valid git repository", type: :success)
        else
          log("Not a git repo, recreating...", type: :warning)
          FileUtils.rm_rf(REPO_PATH)
          run_command("gh repo clone divadvo/mac-automation #{REPO_PATH}", "📥 Cloning...")
        end
      end
    else
      run_command("gh repo clone divadvo/mac-automation #{REPO_PATH}", "📥 Cloning...")
    end
    
    Dir.chdir(REPO_PATH)
    complete_step("REPOSITORY SETUP")  
  end

  def update_config
    return unless run_step("CONFIGURATION UPDATE")
    
    unless File.exist?(CONFIG_PATH)
      log("Config not found: #{CONFIG_PATH}", type: :error)
      exit(1)
    end
    
    config = YAML.load_file(CONFIG_PATH)
    updated = false
    
    if config['user_email'] != @user_email
      log("📝 Email: #{config['user_email']} → #{@user_email}")
      config['user_email'] = @user_email
      updated = true
    end
    
    if config['user_name'] != @user_name
      log("📝 Name: #{config['user_name']} → #{@user_name}")  
      config['user_name'] = @user_name
      updated = true
    end
    
    if updated
      File.write(CONFIG_PATH, YAML.dump(config))
      log("Configuration updated", type: :success)
    else
      log("Configuration current", type: :success)
    end
    
    complete_step("CONFIGURATION UPDATE")
  end

  # Step management utilities

  def run_step(step_name)
    step_file = File.join(STATE_DIR, step_name.downcase.gsub(' ', '_'))
    if File.exist?(step_file)
      log("#{step_name} already completed", type: :success)
      return false
    end
    log(step_name, type: :step)
    true
  end

  def complete_step(step_name)
    FileUtils.touch(File.join(STATE_DIR, step_name.downcase.gsub(' ', '_')))
    @changes_made = true
  end

  def run_command(command, description = nil)
    log(description, type: :command) if description
    unless system(command)
      puts "--- Command Failed ---"
      log("Command failed: #{command}", type: :error)
      exit(1)
    end
    puts "--- End Command Output ---" if description
  end

  # Helper methods

  def log(message, type: :info)
    icon = case type
    when :success then "✅"
    when :error then "❌" 
    when :warning then "⚠️"
    when :step then ""
    when :command then ""
    else ""
    end
    
    if type == :step
      puts "\n=== #{message.upcase} ===\n"
    elsif type == :command
      puts "#{PREFIX} #{message}\n--- Command Output ---"
    else
      puts "#{PREFIX} #{icon}#{icon.empty? ? '' : ' '}#{message}"
    end
  end

  def config_set?
    return false unless File.exist?(CONFIG_PATH)
    config = YAML.load_file(CONFIG_PATH)
    config['user_email'] != 'your@email.com' && 
    config['user_name'] != 'Your Name' &&
    !config['user_email'].nil? && !config['user_name'].nil?
  rescue
    false
  end

  def show_completion_message
    puts "\n#{'=' * 42}\n🎉 BOOTSTRAP COMPLETE!\n#{'=' * 42}"
    log("📁 Repository: #{REPO_PATH}")
    puts "\nNext: cd #{REPO_PATH}\nThen: uv run ./playbook.yml\n"
    log("🔄 Starting fresh shell...")
  end
end

# Run bootstrap
if __FILE__ == $0
  begin
    MacBootstrap.new.run
  rescue Interrupt
    puts "\n#{MacBootstrap::PREFIX} ❌ Interrupted"
    exit(1)
  rescue => e
    puts "\n#{MacBootstrap::PREFIX} ❌ Failed: #{e.message}"
    exit(1)
  end
end