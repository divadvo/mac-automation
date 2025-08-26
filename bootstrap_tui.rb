#!/usr/bin/env ruby
# bootstrap_tui.rb - MacBook Automation Bootstrap Script with Interactive TUI
# Idempotent, location-independent bootstrap for mac-automation with split-screen interface

require 'fileutils'
require 'io/console'
require 'open3'

class TUIBootstrap
  PRIORITY_DIR = File.expand_path("~/pr/priority").freeze
  PREFIX = "[MAC-AUTOMATION]".freeze
  STATE_DIR = File.expand_path("~/.mac-bootstrap").freeze
  REPO_PATH = File.join(PRIORITY_DIR, "mac-automation").freeze
  CONFIG_PATH = File.join(REPO_PATH, "roles/divadvo_mac/vars/main.yml").freeze
  BREW_PATH = "/opt/homebrew/bin:/opt/homebrew/sbin".freeze
  BREW_INIT = 'eval "$(/opt/homebrew/bin/brew shellenv)"'.freeze
  SHELL_FILES = %w[~/.zprofile ~/.zshrc].map { |f| File.expand_path(f) }.freeze
  
  # ANSI escape codes
  CLEAR_SCREEN = "\e[2J".freeze
  CURSOR_HOME = "\e[H".freeze
  HIDE_CURSOR = "\e[?25l".freeze
  SHOW_CURSOR = "\e[?25h".freeze
  SAVE_CURSOR = "\e[s".freeze
  RESTORE_CURSOR = "\e[u".freeze
  
  # Colors
  GREEN = "\e[32m".freeze
  YELLOW = "\e[33m".freeze
  RED = "\e[31m".freeze
  BLUE = "\e[34m".freeze
  CYAN = "\e[36m".freeze
  RESET = "\e[0m".freeze
  BOLD = "\e[1m".freeze
  
  def initialize
    @changes_made = false
    @terminal_width, @terminal_height = get_terminal_size
    @left_width = (@terminal_width * 0.35).to_i
    @right_width = @terminal_width - @left_width - 3 # 3 for borders
    @output_buffer = []
    @max_output_lines = @terminal_height - 4 # Leave room for borders and status
    
    @steps = [
      { name: "HOMEBREW SETUP", status: :pending, method: :install_homebrew },
      { name: "ESSENTIAL TOOLS", status: :pending, method: :setup_tools },
      { name: "USER CONFIGURATION", status: :pending, method: :get_user_config },
      { name: "GITHUB AUTHENTICATION", status: :pending, method: :setup_github_auth },
      { name: "REPOSITORY SETUP", status: :pending, method: :setup_repository },
      { name: "CONFIGURATION UPDATE", status: :pending, method: :update_config }
    ]
    
    FileUtils.mkdir_p(STATE_DIR)
    setup_terminal
    initial_render
  end
  
  def run
    trap('INT') { cleanup_and_exit }
    trap('TERM') { cleanup_and_exit }
    
    @steps.each_with_index do |step, index|
      next if step_already_completed?(step[:name])
      
      @steps[index][:status] = :in_progress
      render_interface
      
      begin
        send(step[:method])
        @steps[index][:status] = :completed
        complete_step(step[:name])
      rescue => e
        @steps[index][:status] = :error
        add_output("❌ Error in #{step[:name]}: #{e.message}", :error)
        cleanup_and_exit(1)
      end
      
      render_interface
      sleep(0.5) # Brief pause to show completion
    end
    
    show_completion_status
    handle_next_phases
    cleanup_and_exit
  end
  
  private
  
  def setup_terminal
    print HIDE_CURSOR
    print CLEAR_SCREEN
    at_exit { print SHOW_CURSOR }
  end
  
  def cleanup_and_exit(code = 0)
    print SHOW_CURSOR
    print CLEAR_SCREEN
    print CURSOR_HOME
    exit(code)
  end
  
  def get_terminal_size
    if STDOUT.tty?
      IO.console.winsize.reverse
    else
      [80, 24] # Default fallback
    end
  end
  
  def initial_render
    add_output("🚀 MacBook Automation Bootstrap Script (Ruby TUI)")
    add_output("=" * 42)
    add_output("")
    render_interface
  end
  
  def render_interface
    print CURSOR_HOME
    
    # Top border
    puts "┌#{'─' * @left_width}┬#{'─' * @right_width}┐"
    
    # Header
    left_header = "#{BOLD}BOOTSTRAP STEPS#{RESET}".center(@left_width)
    right_header = "#{BOLD}EXECUTION OUTPUT#{RESET}".center(@right_width)
    puts "│#{left_header}│#{right_header}│"
    puts "├#{'─' * @left_width}┼#{'─' * @right_width}┤"
    
    # Content rows
    content_rows = [@steps.length, @max_output_lines].max
    (0...content_rows).each do |i|
      left_content = render_step_line(i)
      right_content = render_output_line(i)
      puts "│#{left_content}│#{right_content}│"
    end
    
    # Bottom border
    puts "└#{'─' * @left_width}┴#{'─' * @right_width}┘"
  end
  
  def render_step_line(line_index)
    if line_index < @steps.length
      step = @steps[line_index]
      status_icon = case step[:status]
                   when :completed then "#{GREEN}✓#{RESET}"
                   when :in_progress then "#{YELLOW}●#{RESET}"
                   when :error then "#{RED}✗#{RESET}"
                   else "#{CYAN}○#{RESET}"
                   end
      
      step_text = "#{status_icon} #{step[:name]}"
      truncate_text(step_text, @left_width)
    else
      " " * @left_width
    end
  end
  
  def render_output_line(line_index)
    if line_index < @output_buffer.length
      line = @output_buffer[-(@max_output_lines - line_index)]
      truncate_text(line || "", @right_width)
    else
      " " * @right_width
    end
  end
  
  def truncate_text(text, max_width)
    # Remove ANSI codes for length calculation, but preserve them in output
    clean_text = text.gsub(/\e\[[0-9;]*m/, '')
    if clean_text.length <= max_width
      text + " " * (max_width - clean_text.length)
    else
      # Find a good truncation point that preserves ANSI codes
      truncated = text[0..max_width-4] + "..."
      truncated + " " * (max_width - truncated.gsub(/\e\[[0-9;]*m/, '').length)
    end
  end
  
  def add_output(message, type = :info)
    timestamp = Time.now.strftime("%H:%M:%S")
    
    case type
    when :command
      formatted = "#{BLUE}[#{timestamp}]#{RESET} #{BOLD}$#{RESET} #{message}"
    when :success
      formatted = "#{BLUE}[#{timestamp}]#{RESET} #{GREEN}✓#{RESET} #{message}"
    when :error
      formatted = "#{BLUE}[#{timestamp}]#{RESET} #{RED}✗#{RESET} #{message}"
    when :warning
      formatted = "#{BLUE}[#{timestamp}]#{RESET} #{YELLOW}⚠#{RESET} #{message}"
    else
      formatted = "#{BLUE}[#{timestamp}]#{RESET} #{message}"
    end
    
    @output_buffer << formatted
    
    # Keep buffer size manageable
    @output_buffer = @output_buffer.last(1000) if @output_buffer.length > 1000
    
    render_interface
  end
  
  def run_command(command, description = nil)
    add_output(description || command, :command) if description
    
    success = false
    Open3.popen2e(command) do |stdin, stdout_err, wait_thr|
      stdin.close
      
      while line = stdout_err.gets
        add_output(line.chomp)
      end
      
      success = wait_thr.value.success?
    end
    
    unless success
      add_output("Command failed: #{command}", :error)
      raise "Command failed: #{command}"
    end
    
    add_output("Command completed successfully", :success)
  end
  
  def ask_yes_no(prompt, default: false)
    print SHOW_CURSOR
    print SAVE_CURSOR
    
    # Move to bottom of screen for input
    print "\e[#{@terminal_height};1H"
    print "\e[K" # Clear line
    
    suffix = default ? "(Y/n)" : "(y/N)"
    print "#{PREFIX} #{prompt} #{suffix}: "
    
    input = gets.chomp
    result = if input.empty?
               default
             else
               input.match?(/^[Yy]([Ee][Ss])?$/)
             end
    
    print RESTORE_CURSOR
    print HIDE_CURSOR
    render_interface
    
    result
  end
  
  # Original bootstrap methods adapted for TUI
  
  def install_homebrew
    if command_exists?("brew")
      add_output("Homebrew already installed", :success)
    else
      add_output("Installing Homebrew...")
      ENV['NONINTERACTIVE'] = '1'
      run_command('/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"', "📦 Installing Homebrew...")
      
      # Setup PATH in shell files
      SHELL_FILES.each do |file|
        next if File.exist?(file) && File.read(file).include?(BREW_INIT)
        add_output("Adding Homebrew PATH to #{File.basename(file)}")
        File.open(file, 'a') { |f| f.puts(BREW_INIT) }
      end
    end
    run_command(BREW_INIT)
  end

  def setup_tools
    ENV['PATH'] = "#{BREW_PATH}:#{ENV['PATH']}" unless command_exists?("brew")
    
    missing = %w[uv gh git].reject do |tool|
      if brew_installed?(tool)
        add_output("#{tool}: Already installed", :success)
        true
      else
        add_output("#{tool}: Missing", :warning)
        false
      end
    end
    
    unless missing.empty?
      add_output("Installing: #{missing.join(', ')}")
      brew_cmd = command_exists?("brew") ? "brew" : "/opt/homebrew/bin/brew"
      run_command("#{brew_cmd} install #{missing.join(' ')}", "🛠️ Installing tools...")
    end
  end

  def get_user_config
    if config_set?
      content = File.read(CONFIG_PATH)
      @user_email = content[/^user_email:\s*[\"']?(.*)[\"']?$/, 1]
      @user_name = content[/^user_name:\s*[\"']?(.*)[\"']?$/, 1]
      add_output("Using: #{@user_name} <#{@user_email}>", :success)
    else
      add_output("Getting user details...")
      
      print SHOW_CURSOR
      loop do
        print "\e[#{@terminal_height-1};1H\e[K"
        print "Email: "
        @user_email = gets.chomp
        
        print "\e[#{@terminal_height};1H\e[K"
        print "Name: "
        @user_name = gets.chomp
        
        print "\e[#{@terminal_height-1};1H\e[2K"
        print "Verify: Email: '#{@user_email}', Name: '#{@user_name}'"
        print "\e[#{@terminal_height};1H\e[K"
        
        break if ask_yes_no("Correct?")
        add_output("Try again...")
      end
      print HIDE_CURSOR
      
      add_output("Confirmed!", :success)
    end
  end

  def setup_github_auth
    if command_exists?("gh") && system("gh auth status", out: File::NULL, err: File::NULL)
      add_output("GitHub already authenticated", :success)
      run_command("gh auth status", "✅ Verifying...")
    else
      add_output("🔑 Authenticating with GitHub CLI...")
      add_output("Methods: Passkeys (recommended), Google, or password+2FA")
      add_output("✨ Test login at GitHub.com first if possible")
      
      if ask_yes_no("Open GitHub.com to test?")
        add_output("Opening browser...")
        system("open 'https://github.com/login'")
      end
      
      add_output("Flow: device code → https://github.com/login/device → choose auth method")
      run_command("gh auth login --hostname github.com --git-protocol ssh --web", "🔑 Authenticating...")
      run_command("gh auth status", "✅ Verifying...")
    end
  end

  def setup_repository
    FileUtils.mkdir_p(PRIORITY_DIR)
    
    if Dir.exist?(REPO_PATH) && Dir.chdir(REPO_PATH) { Dir.exist?('.git') }
      add_output("Valid git repository", :success)
    else
      add_output("Repository missing or invalid, cloning...", :warning) if Dir.exist?(REPO_PATH)
      FileUtils.rm_rf(REPO_PATH) if Dir.exist?(REPO_PATH)
      clone_repo
    end
    
    Dir.chdir(REPO_PATH)
  end

  def update_config
    unless File.exist?(CONFIG_PATH)
      add_output("Config not found: #{CONFIG_PATH}", :error)
      raise "Config file not found"
    end
    
    content = File.read(CONFIG_PATH)
    original_content = content.dup
    
    # Update only the specific lines, preserving all formatting and comments
    if content.gsub!(/^user_email:\s*[\"']?.*[\"']?$/, "user_email: \"#{@user_email}\"")
      add_output("📝 Email: #{@user_email}")
    end
    
    if content.gsub!(/^user_name:\s*[\"']?.*[\"']?$/, "user_name: \"#{@user_name}\"")
      add_output("📝 Name: #{@user_name}")
    end
    
    if content != original_content
      File.write(CONFIG_PATH, content)
      add_output("Configuration updated", :success)
    else
      add_output("Configuration current", :success)
    end
  end
  
  def show_completion_status
    status = @changes_made ? "🎉 Bootstrap complete!" : "All steps complete - no changes needed!"
    add_output(status, :success)
    add_output("📁 Repository: #{REPO_PATH}")
    sleep(1)
  end
  
  def handle_next_phases
    if ask_yes_no("Run Phase 2 (main playbook)?")
      run_main_playbook
    end
    
    if ask_yes_no("Open Phase 4 manual setup guide?", default: true)
      open_manual_setup
    end
  end
  
  def run_main_playbook
    Dir.chdir(REPO_PATH)
    base_cmd = "uv run ./playbook.yml"
    test_cmd = "#{base_cmd} -e testing_mode=true"
    
    add_output("Commands available:")
    add_output("• Full mode: #{base_cmd}")
    add_output("• Testing mode: #{test_cmd}")
    
    cmd = ask_yes_no("Use testing mode? (fewer packages)") ? test_cmd : base_cmd
    run_command(cmd, "🚀 Phase 2: Running main playbook...")
  end
  
  def open_manual_setup
    system("open 'https://github.com/divadvo/mac-automation/blob/main/docs/MANUAL_SETUP.md'")
    add_output("📖 Phase 4: Manual setup guide opened", :success)
  end
  
  # Helper methods
  
  def command_exists?(cmd)
    system("which #{cmd}", out: File::NULL, err: File::NULL)
  end

  def brew_installed?(pkg)
    system("brew list #{pkg}", out: File::NULL, err: File::NULL)
  end
  
  def config_set?
    return false unless File.exist?(CONFIG_PATH)
    content = File.read(CONFIG_PATH)
    content.match?(/^user_email:\s*[\"']?(?!your@email\.com).*[\"']?$/) &&
    content.match?(/^user_name:\s*[\"']?(?!Your Name).*[\"']?$/)
  rescue
    false
  end

  def step_already_completed?(step_name)
    File.exist?(step_file(step_name))
  end

  def complete_step(step_name)
    FileUtils.touch(step_file(step_name))
    @changes_made = true
  end

  def step_file(name)
    File.join(STATE_DIR, name.downcase.gsub(' ', '_'))
  end

  def clone_repo
    run_command("gh repo clone divadvo/mac-automation #{REPO_PATH}", "📥 Cloning...")
  end
end

# Run TUI bootstrap
if __FILE__ == $0
  begin
    TUIBootstrap.new.run
  rescue Interrupt
    print "\e[?25h" # Show cursor
    print "\e[2J\e[H" # Clear screen
    puts "\n#{TUIBootstrap::PREFIX} ❌ Interrupted"
    exit(1)
  rescue => e
    print "\e[?25h" # Show cursor  
    print "\e[2J\e[H" # Clear screen
    puts "\n#{TUIBootstrap::PREFIX} ❌ Failed: #{e.message}"
    exit(1)
  end
end