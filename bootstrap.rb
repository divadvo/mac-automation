#!/usr/bin/env ruby
# bootstrap.rb - MacBook Automation Bootstrap Script (Ruby Version)
# Idempotent, location-independent bootstrap for mac-automation

require 'fileutils'

class MacBootstrap
  PRIORITY_DIR = File.expand_path("~/pr/priority").freeze
  PREFIX = "[BOOTSTRAP]".freeze
  STATE_DIR = File.expand_path("~/.mac-bootstrap").freeze
  REPO_PATH = File.join(PRIORITY_DIR, "mac-automation").freeze
  CONFIG_PATH = File.join(REPO_PATH, "roles/divadvo_mac/vars/main.yml").freeze
  BREW_PATH = "/opt/homebrew/bin:/opt/homebrew/sbin".freeze
  BREW_INIT = 'eval "$(/opt/homebrew/bin/brew shellenv)"'.freeze
  SHELL_FILES = %w[~/.zprofile ~/.zshrc].map { |f| File.expand_path(f) }.freeze
  
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
    with_step("HOMEBREW SETUP") do
      if command_exists?("brew")
        log("Homebrew already installed", type: :success)
      else
        log("📦 Installing Homebrew...")
        ENV['NONINTERACTIVE'] = '1'
        run_command('/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"', "📦 Installing Homebrew...")
        
        # Setup PATH in shell files
        SHELL_FILES.each do |file|
          next if File.exist?(file) && File.read(file).include?(BREW_INIT)
          log("Adding Homebrew PATH to #{File.basename(file)}")
          File.open(file, 'a') { |f| f.puts(BREW_INIT) }
        end
      end
      run_command(BREW_INIT)
    end
  end

  def setup_tools
    with_step("ESSENTIAL TOOLS") do
      ENV['PATH'] = "#{BREW_PATH}:#{ENV['PATH']}" unless command_exists?("brew")
      
      missing = %w[uv gh git].reject do |tool|
        if brew_installed?(tool)
          log("#{tool}: Already installed", type: :success)
          true
        else
          log("#{tool}: Missing")
          false
        end
      end
      
      unless missing.empty?
        log("🛠️ Installing: #{missing.join(', ')}")
        brew_cmd = command_exists?("brew") ? "brew" : "/opt/homebrew/bin/brew"
        run_command("#{brew_cmd} install #{missing.join(' ')}", "🛠️ Installing tools...")
      end
    end
  end

  def get_user_config
    with_step("USER CONFIGURATION") do
      if config_set?
        content = File.read(CONFIG_PATH)
        @user_email = content[/^user_email:\s*["']?(.*)["']?$/, 1]
        @user_name = content[/^user_name:\s*["']?(.*)["']?$/, 1]
        log("Using: #{@user_name} <#{@user_email}>", type: :success)
      else
        log("📝 Getting user details...")
        loop do
          print "Email: "; @user_email = gets.chomp
          print "Name: "; @user_name = gets.chomp
          puts "\nVerify:\n  Email: '#{@user_email}'\n  Name:  '#{@user_name}'\n"
          break log("Confirmed!", type: :success) if ask_yes_no("Correct?")
          log("Try again..."); puts
        end
      end
    end
  end

  def setup_github_auth
    with_step("GITHUB AUTHENTICATION") do
      if command_exists?("gh") && system("gh auth status", out: File::NULL, err: File::NULL)
        log("GitHub already authenticated", type: :success)
        run_command("gh auth status", "✅ Verifying...")
      else
        %w[
          🔑\ Authenticating\ with\ GitHub\ CLI...
          Methods:\ Passkeys\ (recommended),\ Google,\ or\ password+2FA
          ✨\ Test\ login\ at\ GitHub.com\ first\ if\ possible
        ].each { |msg| log(msg.gsub('\ ', ' ')) }
        
        if ask_yes_no("Open GitHub.com to test?")
          log("Opening browser...")
          system("open 'https://github.com/login'")
        end
        
        puts "\nFlow: device code → https://github.com/login/device → choose auth method\n"
        run_command("gh auth login --hostname github.com --git-protocol ssh --web", "🔑 Authenticating...")
        run_command("gh auth status", "✅ Verifying...")
      end
    end
  end

  def setup_repository
    with_step("REPOSITORY SETUP") do
      FileUtils.mkdir_p(PRIORITY_DIR)
      
      if Dir.exist?(REPO_PATH) && Dir.chdir(REPO_PATH) { Dir.exist?('.git') }
        log("Valid git repository", type: :success)
      else
        log("Repository missing or invalid, cloning...", type: :warning) if Dir.exist?(REPO_PATH)
        FileUtils.rm_rf(REPO_PATH) if Dir.exist?(REPO_PATH)
        clone_repo
      end
      
      Dir.chdir(REPO_PATH)
    end
  end

  def update_config
    with_step("CONFIGURATION UPDATE") do
      unless File.exist?(CONFIG_PATH)
        log("Config not found: #{CONFIG_PATH}", type: :error)
        exit(1)
      end
      
      content = File.read(CONFIG_PATH)
      original_content = content.dup
      
      # Update only the specific lines, preserving all formatting and comments
      if content.gsub!(/^user_email:\s*["']?.*["']?$/, "user_email: \"#{@user_email}\"")
        log("📝 Email: #{@user_email}")
      end
      
      if content.gsub!(/^user_name:\s*["']?.*["']?$/, "user_name: \"#{@user_name}\"")
        log("📝 Name: #{@user_name}")
      end
      
      if content != original_content
        File.write(CONFIG_PATH, content)
        log("Configuration updated", type: :success)
      else
        log("Configuration current", type: :success)
      end
    end
  end

  # Utilities

  def with_step(step_name)
    return unless run_step(step_name)
    yield
    complete_step(step_name)
  end

  def run_step(step_name)
    if File.exist?(step_file(step_name))
      log("#{step_name} already completed", type: :success)
      return false
    end
    log(step_name, type: :step)
    true
  end

  def complete_step(step_name)
    FileUtils.touch(step_file(step_name))
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

  # Helpers

  def log(message, type: :info)
    icon = { success: "✅", error: "❌", warning: "⚠️" }[type] || ""
    
    case type
    when :step then puts "\n=== #{message.upcase} ===\n"
    when :command then puts "#{PREFIX} #{message}\n--- Command Output ---"
    else puts "#{PREFIX} #{icon}#{icon.empty? ? '' : ' '}#{message}"
    end
  end

  def command_exists?(cmd)
    system("which #{cmd}", out: File::NULL, err: File::NULL)
  end

  def brew_installed?(pkg)
    system("brew list #{pkg}", out: File::NULL, err: File::NULL)
  end

  def ask_yes_no(prompt)
    print "#{PREFIX} #{prompt} (y/N): "
    gets.chomp.match?(/^[Yy]([Ee][Ss])?$/)
  end

  def config_set?
    return false unless File.exist?(CONFIG_PATH)
    content = File.read(CONFIG_PATH)
    content.match?(/^user_email:\s*["']?(?!your@email\.com).*["']?$/) &&
    content.match?(/^user_name:\s*["']?(?!Your Name).*["']?$/)
  rescue
    false
  end

  def step_file(name)
    File.join(STATE_DIR, name.downcase.gsub(' ', '_'))
  end

  def clone_repo
    run_command("gh repo clone divadvo/mac-automation #{REPO_PATH}", "📥 Cloning...")
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