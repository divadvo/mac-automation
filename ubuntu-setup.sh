#!/usr/bin/env bash
#
# ubuntu-setup.sh — reproduce the macOS dev environment (from this Ansible repo)
# on a fresh Ubuntu 26.04 VPS. Single, self-contained, idempotent.
#
#   Copy this one file to the server and run it, e.g.:
#     curl -fsSL https://raw.githubusercontent.com/divadvo/mac-automation/main/ubuntu-setup.sh | bash
#   or:
#     scp ubuntu-setup.sh vps: && ssh vps 'bash ubuntu-setup.sh'
#
# It installs CLI packages, mise runtimes (node/ruby/bun/rust), uv + Python,
# corepack (pnpm/yarn), oh-my-zsh + Powerlevel10k + plugins, NVChad, clones this
# repo and symlinks its dotfiles, generates an SSH key, and optionally clones
# your personal repos.
#
# GUI apps, macOS `defaults`, LaunchAgents, iTerm2 colors etc. are intentionally
# skipped — they have no server equivalent.
#
# IMPORTANT: this script mirrors the macOS setup. When packages, tool versions,
# uv tools, oh-my-zsh plugins, or dotfiles change in the Ansible role, update
# this script to match. See CLAUDE.md.

set -euo pipefail

# ----------------------------------------------------------------------------
# Config (edit these, or override via env vars) — mirrors roles/divadvo_mac/vars/main.yml
# ----------------------------------------------------------------------------
REPO_URL="${REPO_URL:-https://github.com/divadvo/mac-automation.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"
REPO_DIR="${REPO_DIR:-$HOME/pr/github/mac-automation}"

# Identity — leave blank to be prompted at runtime (or pass via env).
GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"

NODE_VERSION="${NODE_VERSION:-24}"
RUBY_VERSION="${RUBY_VERSION:-4}"
BUN_VERSION="${BUN_VERSION:-1}"
RUST_VERSION="${RUST_VERSION:-1}"
PYTHON_VERSIONS=(3.13 3.14)
UV_TOOLS=(build ruff b2)

# Modern CLI tools not (reliably) in apt — installed via the mise registry.
MISE_EXTRA_TOOLS=(xh bottom tlrc cheat yt-dlp zellij opencode flyctl gum hcloud miniserve rclone typst)

# oh-my-zsh custom plugins (name|repo)
OMZ_PLUGINS=(
  "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git"
  "zsh-you-should-use|https://github.com/MichaelAquilina/zsh-you-should-use.git"
  "pnpm|https://github.com/ntnyq/omz-plugin-pnpm.git"
)

# Claude Code extensions, installed user-wide (mirrors tasks/claude.yml).
# MCP servers: "name|http|<url>"  OR  "name|stdio|<command with args>"
CLAUDE_MCP_SERVERS=(
  "context7|http|https://mcp.context7.com/mcp"
  "turbostarter|http|https://www.turbostarter.dev/mcp"
  "playwright|stdio|npx -y @playwright/mcp@latest"
  "chrome-devtools|stdio|npx -y chrome-devtools-mcp@latest"
  "shadcn|stdio|npx -y shadcn@latest mcp"
)
# Marketplace plugins: "plugin@marketplace|marketplace-source"
CLAUDE_PLUGINS=(
  "cloudflare@cloudflare|cloudflare/skills"
  "caveman@caveman|juliusbrussee/caveman"
  "ponytail@ponytail|DietrichGebert/ponytail"
)
# Global npm CLIs for the Claude workflow (installed via mise node).
CLAUDE_NPM_TOOLS=(@fission-ai/openspec@latest)

# Repositories (mirrors repositories.yml)
PRIORITY_REPOS=(divadvo/divadvo-scripts)
REPOS_PUSHED_AFTER="2022-01-01"

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
BOLD=$'\e[1m'; BLUE=$'\e[34m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; RST=$'\e[0m'
log()  { printf '%s\n' "${BLUE}${BOLD}==>${RST} ${BOLD}$*${RST}"; }
info() { printf '%s\n' "    $*"; }
ok()   { printf '%s\n' "${GREEN}    ✓ $*${RST}"; }
warn() { printf '%s\n' "${YELLOW}    ! $*${RST}" >&2; }
die()  { printf '%s\n' "${RED}    ✗ $*${RST}" >&2; exit 1; }

# Run a best-effort step: warn (don't abort) on failure.
try() {
  if "$@"; then return 0; fi
  warn "step failed (continuing): $*"
  return 0
}

tty_available() {
  [[ -r /dev/tty && -w /dev/tty ]] && (: </dev/tty) 2>/dev/null
}

# Ask a yes/no question using the controlling terminal. Enter and
# non-interactive runs both safely default to No.
confirm_no() {
  local prompt="$1" reply=""
  if ! tty_available; then
    info "$prompt [y/N] (no terminal; defaulting to No)"
    return 1
  fi
  read -r -p "    $prompt [y/N] " reply </dev/tty || return 1
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

prompt_required() {
  local var_name="$1" label="$2" value=""
  while [[ -z "$value" ]]; do
    read -r -p "    $label: " value </dev/tty || die "could not read $var_name from the terminal"
    [[ -n "$value" ]] || warn "$label cannot be empty"
  done
  printf -v "$var_name" '%s' "$value"
}

# Explicit env vars bypass prompts. Every missing value must be entered on the
# controlling terminal, including when the script itself is piped to bash.
prompt_identity() {
  local missing=()
  [[ -z "$GIT_USER_NAME" ]] && missing+=(GIT_USER_NAME)
  [[ -z "$GIT_USER_EMAIL" ]] && missing+=(GIT_USER_EMAIL)
  if (( ${#missing[@]} > 0 )) && ! tty_available; then
    die "missing required identity: ${missing[*]}. Run interactively or provide the missing environment variable(s)."
  fi

  [[ -n "$GIT_USER_NAME" ]] || prompt_required GIT_USER_NAME "Git user name"
  [[ -n "$GIT_USER_EMAIL" ]] || prompt_required GIT_USER_EMAIL "Git email (used for git config + SSH key)"
  ok "using git identity ($GIT_USER_NAME <$GIT_USER_EMAIL>)"
}

# ----------------------------------------------------------------------------
# User phase — everything that configures $HOME for the current user.
# Runs either directly (non-root, or root setting up its own home) or re-executed
# via `sudo -u <user>` when root provisions a separate account.
# ----------------------------------------------------------------------------
user_phase() {
  log "Configuring environment for $(whoami) (home: $HOME)"
  mkdir -p "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

  install_mise
  install_runtimes
  install_extra_tools
  install_render_cli
  install_uv
  install_ohmyzsh
  install_nvchad
  install_claude_cli
  install_claude_extensions
  fetch_repo
  link_dotfiles
  ensure_ssh_key
  configure_github_auth
  upload_ssh_key
  clone_repositories

  log "User setup complete for $(whoami)"
}

install_mise() {
  log "Installing mise + runtimes"
  if ! command -v mise >/dev/null 2>&1; then
    curl -fsSL https://mise.run | sh
  else
    ok "mise already installed"
  fi
  export PATH="$HOME/.local/bin:$PATH"
  eval "$(mise activate bash)" 2>/dev/null || true
  # mise manages node/ruby/bun/rust; uv manages Python (mise Python disabled).
  try mise settings set disable_tools python
  try mise settings set python.uv_venv_auto false
  # Download precompiled Ruby instead of compiling from source (falls back to
  # source build if no binary is available). Becomes mise's default in 2026.8.0.
  try mise settings set ruby.compile false
}

install_runtimes() {
  mise use -g "node@${NODE_VERSION}" "ruby@${RUBY_VERSION}" "bun@${BUN_VERSION}" "rust@${RUST_VERSION}"
  mise reshim
  ok "node ${NODE_VERSION}, ruby ${RUBY_VERSION}, bun ${BUN_VERSION}, rust ${RUST_VERSION}"
  # yarn + pnpm via corepack (through node)
  try mise x -- corepack enable
  try mise x -- corepack install -g pnpm@latest yarn@latest
}

install_extra_tools() {
  log "Installing modern CLI tools via mise (${MISE_EXTRA_TOOLS[*]})"
  local t
  for t in "${MISE_EXTRA_TOOLS[@]}"; do
    try mise use -g "$t"
  done
  mise reshim || true
}

install_render_cli() {
  log "Installing Render CLI"
  local render_bin="$HOME/.render/bin/render"
  if command -v render >/dev/null 2>&1; then
    ok "render already installed"
    return
  fi
  if [[ ! -x "$render_bin" ]]; then
    # A third-party installer must not take the whole user phase down with it:
    # this one exits non-zero when unzip is missing, and under `set -e` that
    # aborted everything after it.
    curl -fsSL https://raw.githubusercontent.com/render-oss/cli/main/bin/install.sh | sh \
      || { warn "Render CLI installer failed (continuing)"; return; }
  fi
  [[ -x "$render_bin" ]] || { warn "Render CLI installer did not create $render_bin"; return; }
  ln -sfn "$render_bin" "$HOME/.local/bin/render"
  ok "render linked into ~/.local/bin"
}

install_uv() {
  log "Installing uv + Python ${PYTHON_VERSIONS[*]}"
  if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  else
    ok "uv already installed"
  fi
  export PATH="$HOME/.local/bin:$PATH"
  local v
  for v in "${PYTHON_VERSIONS[@]}"; do
    try uv python install "$v"
  done
  local tool
  for tool in "${UV_TOOLS[@]}"; do
    try uv tool install --python 3.13 "$tool"
    try uv tool upgrade "$tool"
  done
}

install_ohmyzsh() {
  log "Installing oh-my-zsh + Powerlevel10k + plugins"
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    # --keep-zshrc: don't clobber the .zshrc we symlink later; --unattended: no chsh/no shell swap
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
      "" --unattended --keep-zshrc
  else
    ok "oh-my-zsh already installed"
  fi

  local custom="$HOME/.oh-my-zsh/custom"
  clone_if_missing https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k"

  local entry name repo
  for entry in "${OMZ_PLUGINS[@]}"; do
    name="${entry%%|*}"; repo="${entry#*|}"
    clone_if_missing "$repo" "$custom/plugins/$name"
  done
}

install_nvchad() {
  log "Installing NVChad (Neovim config)"
  clone_if_missing https://github.com/NvChad/starter "$HOME/.config/nvim"
}

# The claude-code CLI (macOS installs it via the claude-code cask; here we use
# the official install script). Required before install_claude_extensions.
install_claude_cli() {
  log "Installing Claude Code CLI"
  if command -v claude >/dev/null 2>&1; then
    ok "claude already installed"
  else
    curl -fsSL https://claude.ai/install.sh | bash
  fi
  export PATH="$HOME/.local/bin:$PATH"
}

# Install Claude Code extensions user-wide: MCP servers, marketplace plugins,
# and related global npm CLIs. Mirrors roles/divadvo_mac/tasks/claude.yml.
# Never let a claude subcommand inherit our stdin. When this script is piped to
# `bash -s` (which is how devbox provisions it), stdin IS the rest of the script:
# a child that reads it swallows the remainder of the run, and one that waits on
# it hangs forever. Measured on claude 2.1.226: `mcp list`, `mcp add`, `plugin
# list` and `plugin marketplace list` all exit 0 with no TTY and a fresh config
# dir, so nothing here needs an authenticated login — only a closed stdin.
claude_q() { claude "$@" </dev/null; }

install_claude_extensions() {
  if ! command -v claude >/dev/null 2>&1; then
    warn "claude CLI not found; skipping Claude Code extensions"
    return
  fi

  # One probe for the whole block. If claude cannot answer a read-only question
  # unattended, every call below would fail the same way, so say it once and
  # leave the user a command instead of a wall of warnings.
  if ! claude_q mcp list >/dev/null 2>&1; then
    local self="$0"
    [[ -f "$self" ]] || self="ubuntu-setup.sh"
    warn "claude cannot run unattended here; skipping Claude Code extensions"
    info "sign in with ${BOLD}claude${RST}, then apply them with:"
    info "  _EXTENSIONS_ONLY=1 bash $self"
    return
  fi

  log "Configuring Claude Code extensions (user scope)"

  # --- MCP servers (name|http|<url>  OR  name|stdio|<command with args>) ---
  local existing entry name transport rest
  existing="$(claude_q mcp list 2>/dev/null || true)"
  for entry in "${CLAUDE_MCP_SERVERS[@]}"; do
    name="${entry%%|*}"; rest="${entry#*|}"
    transport="${rest%%|*}"; rest="${rest#*|}"
    if grep -qF "$name" <<<"$existing"; then
      ok "mcp $name already configured"; continue
    fi
    if [[ "$transport" == "http" ]]; then
      try claude_q mcp add --scope user --transport http "$name" "$rest"
    else
      # stdio: split the command line into argv on whitespace (intentional).
      # shellcheck disable=SC2086
      try claude_q mcp add --scope user "$name" -- $rest
    fi
  done

  # --- Marketplace plugins (plugin@marketplace|marketplace-source) ---
  local marketplaces installed spec plugin_id source pname mkt
  marketplaces="$(claude_q plugin marketplace list 2>/dev/null || true)"
  installed="$(claude_q plugin list 2>/dev/null || true)"
  for spec in "${CLAUDE_PLUGINS[@]}"; do
    plugin_id="${spec%%|*}"; source="${spec#*|}"
    pname="${plugin_id%@*}"; mkt="${plugin_id#*@}"
    grep -qF "$mkt" <<<"$marketplaces" || try claude_q plugin marketplace add "$source"
    if grep -qF "$pname" <<<"$installed"; then
      ok "plugin $plugin_id already installed"
    else
      try claude_q plugin install "$plugin_id" --scope user
    fi
  done

  # --- Global npm CLIs (openspec, etc.) via mise node ---
  local tool
  for tool in "${CLAUDE_NPM_TOOLS[@]}"; do
    try mise x -- npm install -g "$tool"
  done
}

# Ensure this repo is available locally so we can symlink its dotfiles.
fetch_repo() {
  # If the script is being run from inside a checkout, use that.
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -d "$script_dir/roles/divadvo_mac/files/dotfiles" ]]; then
    REPO_DIR="$script_dir"
    ok "using repo checkout at $REPO_DIR"
    return
  fi
  log "Cloning $REPO_URL ($REPO_BRANCH)"
  if [[ -d "$REPO_DIR/.git" ]]; then
    ok "repo already cloned at $REPO_DIR"
  else
    git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"
  fi
}

link_dotfiles() {
  log "Linking dotfiles from $REPO_DIR"
  local df="$REPO_DIR/roles/divadvo_mac/files/dotfiles"
  [[ -d "$df" ]] || die "dotfiles not found at $df"

  mkdir -p "$HOME/.config/git" "$HOME/.config/zellij" "$HOME/.config" "$HOME/.claude" "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # repo-relative path -> $HOME/.<path>  (mirrors config.yml, minus macOS-only vscode)
  local rel
  for rel in \
    config/ripgreprc \
    config/git/attributes \
    config/git/ignore \
    config/zellij/config.kdl \
    ssh/config \
    zprofile \
    claude/settings.json \
    claude/statusline.sh \
    hushlogin \
    zshrc \
    tmux.conf
  do
    ln -sfn "$df/$rel" "$HOME/.$rel"
  done
  ok "symlinked zshrc, zprofile, git/*, ripgreprc, ssh/config, claude/*, hushlogin, tmux.conf, zellij/config.kdl"

  # Git config is templated in Ansible (config.j2). Render name/email here.
  render_git_config
}

render_git_config() {
  local tpl="$REPO_DIR/roles/divadvo_mac/templates/config/git/config.j2"
  [[ -f "$tpl" ]] || { warn "git config template missing, skipping"; return; }
  sed -e "s/{{ user_name }}/${GIT_USER_NAME}/g" \
      -e "s/{{ user_email }}/${GIT_USER_EMAIL}/g" \
      "$tpl" > "$HOME/.config/git/config"
  ok "wrote ~/.config/git/config ($GIT_USER_NAME <$GIT_USER_EMAIL>)"
}

ensure_ssh_key() {
  log "Setting up SSH key"
  local key="$HOME/.ssh/id_ed25519"
  if [[ ! -f "$key" ]]; then
    ssh-keygen -t ed25519 -f "$key" -N "" -C "$GIT_USER_EMAIL"
    chmod 600 "$key"; chmod 644 "$key.pub"
    ok "generated $key"
  else
    ok "SSH key already exists"
  fi
}

configure_github_auth() {
  if ! command -v gh >/dev/null 2>&1; then
    warn "gh is not installed — skipping GitHub authentication"
    return
  fi
  if gh auth status >/dev/null 2>&1; then
    ok "GitHub CLI already authenticated"
    return
  fi

  if ! confirm_no "Log in to GitHub CLI now?"; then
    warn "GitHub CLI login skipped"
    return
  fi

  log "Authenticating GitHub CLI"
  if gh auth login --hostname github.com --git-protocol ssh --web </dev/tty \
      && gh auth status >/dev/null 2>&1; then
    ok "GitHub CLI authenticated"
  else
    warn "GitHub CLI authentication failed; continuing without GitHub access"
  fi
}

upload_ssh_key() {
  local key="$HOME/.ssh/id_ed25519"
  if gh auth status >/dev/null 2>&1; then
    local title; title="VPS - $(hostname) - $(date '+%Y-%m-%d')"
    if gh ssh-key add "$key.pub" --title "$title" 2>/tmp/gh_ssh_err; then
      ok "uploaded public key to GitHub"
    elif grep -q "already" /tmp/gh_ssh_err 2>/dev/null; then
      ok "public key already on GitHub"
    else
      warn "could not upload SSH key to GitHub (see below)"; cat /tmp/gh_ssh_err >&2 || true
    fi
    rm -f /tmp/gh_ssh_err
  else
    warn "gh not authenticated — add this public key to GitHub manually:"
    printf '%s\n' "${BOLD}$(cat "$key.pub")${RST}"
    info "then run: gh auth login"
  fi
}

clone_repositories() {
  log "Setting up project directories"
  mkdir -p "$HOME/pr/github" "$HOME/pr/github-other" "$HOME/pr/sandbox"

  if ! confirm_no "Clone personal repositories now?"; then
    info "personal repository cloning skipped"
    return
  fi

  if ! gh auth status >/dev/null 2>&1; then
    warn "gh not authenticated — cannot clone personal repositories."
    info "run 'gh auth login', then re-run this script and opt in to repository cloning."
    return
  fi

  local repo name
  for repo in "${PRIORITY_REPOS[@]}"; do
    name="${repo##*/}"
    [[ -d "$HOME/pr/github/$name" ]] && { ok "$name already cloned"; continue; }
    try gh repo clone "$repo" "$HOME/pr/github/$name"
  done

  log "Cloning personal repos pushed after $REPOS_PUSHED_AFTER"
  local recent
  recent="$(gh repo list --limit 200 --json nameWithOwner,pushedAt,repositoryTopics \
            --jq ".[] | select(.pushedAt > \"$REPOS_PUSHED_AFTER\") | [.nameWithOwner, ([((.repositoryTopics // [])[].name)] | contains([\"sandbox\"]))] | @tsv" 2>/dev/null || true)"
  local r is_sandbox dest
  while IFS=$'\t' read -r r is_sandbox; do
    [[ -z "$r" ]] && continue
    [[ " ${PRIORITY_REPOS[*]} " == *" $r "* ]] && continue
    name="${r##*/}"
    dest="$HOME/pr/github"
    if [[ "$is_sandbox" == true ]]; then
      dest="$HOME/pr/sandbox"
    fi
    [[ -d "$dest/$name" ]] && continue
    try gh repo clone "$r" "$dest/$name"
  done <<< "$recent"
  ok "repositories cloned into ~/pr/github and ~/pr/sandbox"
}

clone_if_missing() {
  local url="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    ok "$(basename "$dest") already present"
  else
    git clone --depth 1 "$url" "$dest"
  fi
}

# ----------------------------------------------------------------------------
# System phase — apt packages, repos, users. Needs root/sudo.
# ----------------------------------------------------------------------------
SUDO=""

system_phase() {
  log "Installing system packages (apt)"
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -y

  # Core CLI tools available in apt (mirrors homebrew_packages that exist there).
  local pkgs=(
    git git-lfs git-filter-repo zsh fish bash
    ansible
    neovim
    ripgrep fd-find bat lsd git-delta tree fzf zoxide
    tmux
    htop
    wget curl rsync jq unzip
    ffmpeg nmap qpdf
    redis-server
    build-essential
    # Ruby build dependencies (mise compiles ruby via ruby-build)
    libssl-dev libyaml-dev zlib1g-dev libreadline-dev libffi-dev libgdbm-dev autoconf bison
    ca-certificates gnupg
  )
  $SUDO apt-get install -y "${pkgs[@]}"

  # `just` — in apt on recent Ubuntu; tolerate absence (mise can provide it).
  try_apt_install just

  install_github_cli

  # Match macOS binary names for apt tools that ship under different names.
  make_bin_shims
}

try_apt_install() {
  if $SUDO apt-get install -y "$@" 2>/dev/null; then
    ok "apt: $*"
  else
    warn "apt could not install: $* (skipping)"
  fi
}

install_github_cli() {
  if command -v gh >/dev/null 2>&1; then ok "gh already installed"; return; fi
  log "Installing GitHub CLI (gh)"
  local keyring=/etc/apt/keyrings/githubcli-archive-keyring.gpg
  $SUDO mkdir -p /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | $SUDO tee "$keyring" >/dev/null
  $SUDO chmod go+r "$keyring"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring] https://cli.github.com/packages stable main" \
    | $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  $SUDO apt-get update -y
  $SUDO apt-get install -y gh
}

make_bin_shims() {
  # apt ships fd as `fdfind` and bat as `batcat`; expose them under mac names.
  $SUDO mkdir -p /usr/local/bin
  command -v fdfind >/dev/null 2>&1 && $SUDO ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  command -v batcat >/dev/null 2>&1 && $SUDO ln -sf "$(command -v batcat)" /usr/local/bin/bat
  ok "fd/bat shims linked"
}

# ----------------------------------------------------------------------------
# Orchestration
# ----------------------------------------------------------------------------
TARGET_USER=""
TARGET_HOME=""

determine_target_user() {
  if [[ $EUID -ne 0 ]]; then
    # Non-root: configure the current user; use sudo for apt.
    command -v sudo >/dev/null 2>&1 || die "sudo required when not running as root"
    SUDO="sudo"
    TARGET_USER="$(whoami)"
    TARGET_HOME="$HOME"
    return
  fi

  # Root: optionally create an additional sudo user to own the dev environment.
  SUDO=""
  local new_user="${CREATE_USER:-}"
  if [[ -z "$new_user" && -z "${NO_NEW_USER:-}" && -t 0 ]]; then
    log "Running as root."
    read -r -p "    Create a new sudo user to own the dev setup? Enter name (blank = use root): " new_user || true
  fi

  if [[ -n "$new_user" ]]; then
    if ! id "$new_user" >/dev/null 2>&1; then
      log "Creating user '$new_user'"
      adduser --disabled-password --gecos "" "$new_user"
      usermod -aG sudo "$new_user"
      # Passwordless sudo so the unattended user-phase apt/gh steps don't block.
      echo "$new_user ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$new_user"
      chmod 440 "/etc/sudoers.d/90-$new_user"
      ok "created sudo user '$new_user' (set a password later with: passwd $new_user)"
    else
      ok "user '$new_user' already exists"
    fi
    TARGET_USER="$new_user"
    TARGET_HOME="$(getent passwd "$new_user" | cut -d: -f6)"
  else
    TARGET_USER="root"
    TARGET_HOME="$HOME"
  fi
}

main() {
  # Re-entry: apply only the Claude extensions to the current user's home. This
  # is the follow-up install_claude_extensions prints when it has to skip.
  if [[ "${_EXTENSIONS_ONLY:-}" == "1" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    install_claude_extensions
    exit 0
  fi

  # Re-entry: this invocation is the per-user phase spawned by root.
  if [[ "${_USER_PHASE:-}" == "1" ]]; then
    prompt_identity
    user_phase
    exit 0
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required (apt-get install -y curl)"
  command -v git  >/dev/null 2>&1 || true  # git installed in system_phase

  prompt_identity
  determine_target_user
  log "System: $TARGET_USER will own the dev environment (home: $TARGET_HOME)"

  system_phase

  # Set login shell to zsh for the target user.
  if command -v zsh >/dev/null 2>&1; then
    try $SUDO chsh -s "$(command -v zsh)" "$TARGET_USER"
    ok "default shell set to zsh for $TARGET_USER"
  fi

  # Run the per-user phase as the target user.
  if [[ $EUID -eq 0 && "$TARGET_USER" != "root" ]]; then
    log "Handing off to user phase as '$TARGET_USER'"
    local script_path
    script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/$(basename "${BASH_SOURCE[0]}")"
    [[ -f "$script_path" ]] || die "cannot locate this script on disk (piped via curl?). Save it to a file and re-run to provision a separate user."
    # The new user may not be able to read the script where it lives (e.g. /root).
    # Copy it into their home so the sudo'd re-exec can read it.
    local user_copy="$TARGET_HOME/.ubuntu-setup.sh"
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0755 "$script_path" "$user_copy"
    # Copy config-relevant env through the sudo boundary.
    sudo -u "$TARGET_USER" -H env _USER_PHASE=1 \
      REPO_URL="$REPO_URL" REPO_BRANCH="$REPO_BRANCH" \
      GIT_USER_NAME="$GIT_USER_NAME" GIT_USER_EMAIL="$GIT_USER_EMAIL" \
      NODE_VERSION="$NODE_VERSION" RUBY_VERSION="$RUBY_VERSION" \
      BUN_VERSION="$BUN_VERSION" RUST_VERSION="$RUST_VERSION" \
      bash "$user_copy"
  else
    user_phase
  fi

  log "All done."
  info "Log in as ${BOLD}${TARGET_USER}${RST} and start a new shell (or run: exec zsh)."
  info "First zsh launch will run the Powerlevel10k config wizard (or run: p10k configure)."
}

main "$@"
