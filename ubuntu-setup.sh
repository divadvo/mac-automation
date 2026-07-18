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
# repo and symlinks its dotfiles, generates an SSH key, and clones your repos.
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
UV_TOOLS=(build ruff)

# Modern CLI tools not (reliably) in apt — installed via the mise registry.
MISE_EXTRA_TOOLS=(xh bottom tlrc cheat yt-dlp)

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

# Resolve the git identity, in order of preference: explicit env vars, an
# already-configured git identity (so reruns don't re-prompt), then an
# interactive prompt. Non-interactive runs (e.g. curl | bash) must supply the
# values via env or a prior config, otherwise we fall back / abort.
prompt_identity() {
  # Reuse an existing identity from a previous run (e.g. ~/.config/git/config).
  if command -v git >/dev/null 2>&1; then
    [[ -z "$GIT_USER_NAME"  ]] && GIT_USER_NAME="$(git config --get user.name 2>/dev/null || true)"
    [[ -z "$GIT_USER_EMAIL" ]] && GIT_USER_EMAIL="$(git config --get user.email 2>/dev/null || true)"
  fi
  if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
    ok "using existing git identity ($GIT_USER_NAME <$GIT_USER_EMAIL>)"
    return 0
  fi

  if [[ -z "$GIT_USER_NAME" ]]; then
    [[ -t 0 ]] && read -r -p "    Git user name: " GIT_USER_NAME || true
    [[ -z "$GIT_USER_NAME" ]] && GIT_USER_NAME="$(whoami)"
  fi
  if [[ -z "$GIT_USER_EMAIL" ]]; then
    [[ -t 0 ]] && read -r -p "    Git email (used for git config + SSH key): " GIT_USER_EMAIL || true
    [[ -z "$GIT_USER_EMAIL" ]] && die "GIT_USER_EMAIL is required — set it at the top of this script or pass GIT_USER_EMAIL=... "
  fi
  return 0  # don't let a false [[ ]] test above make the function return non-zero under `set -e`
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
  install_uv
  install_ohmyzsh
  install_nvchad
  install_claude_cli
  install_claude_extensions
  fetch_repo
  link_dotfiles
  setup_ssh_key
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
install_claude_extensions() {
  if ! command -v claude >/dev/null 2>&1; then
    warn "claude CLI not found; skipping Claude Code extensions"
    return
  fi
  log "Configuring Claude Code extensions (user scope)"

  # --- MCP servers (name|http|<url>  OR  name|stdio|<command with args>) ---
  local existing entry name transport rest
  existing="$(claude mcp list 2>/dev/null || true)"
  for entry in "${CLAUDE_MCP_SERVERS[@]}"; do
    name="${entry%%|*}"; rest="${entry#*|}"
    transport="${rest%%|*}"; rest="${rest#*|}"
    if grep -qF "$name" <<<"$existing"; then
      ok "mcp $name already configured"; continue
    fi
    if [[ "$transport" == "http" ]]; then
      try claude mcp add --scope user --transport http "$name" "$rest"
    else
      # stdio: split the command line into argv on whitespace (intentional).
      # shellcheck disable=SC2086
      try claude mcp add --scope user "$name" -- $rest
    fi
  done

  # --- Marketplace plugins (plugin@marketplace|marketplace-source) ---
  local marketplaces installed spec plugin_id source pname mkt
  marketplaces="$(claude plugin marketplace list 2>/dev/null || true)"
  installed="$(claude plugin list 2>/dev/null || true)"
  for spec in "${CLAUDE_PLUGINS[@]}"; do
    plugin_id="${spec%%|*}"; source="${spec#*|}"
    pname="${plugin_id%@*}"; mkt="${plugin_id#*@}"
    grep -qF "$mkt" <<<"$marketplaces" || try claude plugin marketplace add "$source"
    if grep -qF "$pname" <<<"$installed"; then
      ok "plugin $plugin_id already installed"
    else
      try claude plugin install "$plugin_id" --scope user
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

  mkdir -p "$HOME/.config/git" "$HOME/.config" "$HOME/.claude" "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # repo-relative path -> $HOME/.<path>  (mirrors config.yml, minus macOS-only vscode)
  local rel
  for rel in \
    config/ripgreprc \
    config/git/attributes \
    config/git/ignore \
    ssh/config \
    zprofile \
    claude/settings.json \
    claude/statusline.sh \
    hushlogin \
    zshrc
  do
    ln -sfn "$df/$rel" "$HOME/.$rel"
  done
  ok "symlinked zshrc, zprofile, git/*, ripgreprc, ssh/config, claude/*, hushlogin"

  # Git config is templated in Ansible (config.j2). Render name/email here.
  render_git_config
}

render_git_config() {
  local tpl="$REPO_DIR/roles/divadvo_mac/templates/config/git/config.j2"
  [[ -f "$tpl" ]] || { warn "git config template missing, skipping"; return; }
  [[ -n "$GIT_USER_NAME" ]] || GIT_USER_NAME="$(whoami)"
  sed -e "s/{{ user_name }}/${GIT_USER_NAME}/g" \
      -e "s/{{ user_email }}/${GIT_USER_EMAIL}/g" \
      "$tpl" > "$HOME/.config/git/config"
  ok "wrote ~/.config/git/config ($GIT_USER_NAME <$GIT_USER_EMAIL>)"
}

setup_ssh_key() {
  log "Setting up SSH key"
  local key="$HOME/.ssh/id_ed25519"
  if [[ ! -f "$key" ]]; then
    ssh-keygen -t ed25519 -f "$key" -N "" -C "$GIT_USER_EMAIL"
    chmod 600 "$key"; chmod 644 "$key.pub"
    ok "generated $key"
  else
    ok "SSH key already exists"
  fi

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
    info "then run: gh auth login   (and re-run this script to clone repos)"
  fi
}

clone_repositories() {
  log "Setting up ~/pr and cloning repositories"
  mkdir -p "$HOME/pr/github" "$HOME/pr/github-other" "$HOME/pr/sandbox"

  if ! gh auth status >/dev/null 2>&1; then
    warn "gh not authenticated — created ~/pr dirs only."
    info "run 'gh auth login', then re-run this script to clone repositories."
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
  recent="$(gh repo list --limit 200 --json nameWithOwner,pushedAt \
            --jq ".[] | select(.pushedAt > \"$REPOS_PUSHED_AFTER\") | .nameWithOwner" 2>/dev/null || true)"
  local r
  while IFS= read -r r; do
    [[ -z "$r" ]] && continue
    name="${r##*/}"
    [[ -d "$HOME/pr/github/$name" ]] && continue
    try gh repo clone "$r" "$HOME/pr/github/$name"
  done <<< "$recent"
  ok "repositories cloned into ~/pr/github"
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
    git git-lfs zsh fish
    neovim
    ripgrep fd-find bat lsd git-delta tree fzf zoxide
    htop
    wget curl rsync jq
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
  # Re-entry: this invocation is the per-user phase spawned by root.
  if [[ "${_USER_PHASE:-}" == "1" ]]; then
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
