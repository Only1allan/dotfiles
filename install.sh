#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
SKIP_NVIM=0
SKIP_MISE=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --dry-run      Print what would happen without changing anything.
  --skip-nvim    Do not install Neovim or sync LazyVim plugins.
  --skip-mise    Do not install mise or Node.
  -h, --help     Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skip-nvim) SKIP_NVIM=1 ;;
    --skip-mise) SKIP_MISE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*"; }

run() {
  if ((DRY_RUN)); then
    printf '  would run: %s\n' "$*"
  else
    "$@"
  fi
}

backup_path() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    local dest="$BACKUP_DIR/${path#"$HOME"/}"
    run mkdir -p "$(dirname "$dest")"
    run mv "$path" "$dest"
    log "backed up $path -> $dest"
  fi
}

link_file() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    log "already linked: $dest"
    return
  fi
  backup_path "$dest"
  run mkdir -p "$(dirname "$dest")"
  run ln -s "$src" "$dest"
  log "linked $dest -> $src"
}

install_packages() {
  if ! command -v apt-get >/dev/null 2>&1; then
    warn "apt-get not found; install packages manually: bash tmux git curl wget unzip build-essential ripgrep fd-find fzf bat ncurses-term fontconfig bsdmainutils"
    return
  fi
  log "Updating apt and installing base packages..."
  run sudo apt-get update
  local packages=(bash tmux git curl wget unzip build-essential ripgrep fd-find fzf bat ncurses-term fontconfig bsdmainutils)
  run sudo apt-get install -y "${packages[@]}"
  local pkg
  for pkg in zoxide wslu eza; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      if ! run sudo apt-get install -y "$pkg"; then
        warn "Could not install $pkg; a fallback is used."
      fi
    else
      warn "$pkg is not available; a fallback is used."
    fi
  done
}

install_neovim() {
  if ((SKIP_NVIM)); then
    log "Skipping Neovim (--skip-nvim)."
    return
  fi

  if command -v nvim >/dev/null 2>&1; then
    local version
    version="$(nvim --version | head -n1)"
    if printf '%s\n' "$version" | grep -qE 'v(0\.(1[0-9]|[2-9][0-9])|[1-9][0-9]*)\.'; then
      log "Neovim already installed: $version"
      return
    fi
  fi

  log "Installing the latest Neovim release..."
  local arch dir asset
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) dir="nvim-linux-x86_64" ;;
    aarch64|arm64) dir="nvim-linux-arm64" ;;
    *) warn "Unsupported architecture: $arch; install Neovim manually."; return ;;
  esac
  asset="$dir.tar.gz"

  local tmp
  tmp="$(mktemp -d)"
  if ! run curl -fL "https://github.com/neovim/neovim/releases/latest/download/$asset" -o "$tmp/nvim.tar.gz"; then
    warn "Neovim download failed; install it manually."
    rm -rf "$tmp"
    return
  fi
  run mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
  run tar -xzf "$tmp/nvim.tar.gz" -C "$HOME/.local/opt"
  run ln -sfn "$HOME/.local/opt/$dir/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp"
  export PATH="$HOME/.local/bin:$PATH"
  hash -r
  if command -v nvim >/dev/null 2>&1; then
    log "Neovim installed: $(nvim --version | head -n1)"
  else
    log "Neovim would be installed."
  fi
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    log "Starship already installed."
    return
  fi

  if command -v apt-get >/dev/null 2>&1 && apt-cache show starship >/dev/null 2>&1; then
    if run sudo apt-get install -y starship; then
      return
    fi
  fi

  log "Installing Starship..."
  if ((DRY_RUN)); then
    printf '  would run: curl -fsSL https://starship.rs/install.sh | sh -s -- -y\n'
    return
  fi
  if ! curl -fsSL https://starship.rs/install.sh | sh -s -- -y; then
    warn "Starship install failed; install it manually from https://starship.rs"
  fi
}

install_mise() {
  if ((SKIP_MISE)); then
    log "Skipping mise (--skip-mise)."
    return
  fi

  if ! command -v mise >/dev/null 2>&1; then
    log "Installing mise..."
    if ((DRY_RUN)); then
      printf '  would run: curl https://mise.run | sh\n'
    else
      if ! curl -fsSL https://mise.run | sh; then
        warn "mise install failed; skipping Node."
        return
      fi
    fi
    export PATH="$HOME/.local/bin:$PATH"
    hash -r
  fi

  if command -v mise >/dev/null 2>&1; then
    log "Installing Node 26.8.1 with mise..."
    if ! run mise install node@26.8.1; then
      warn "mise could not install Node 26.8.1; run 'mise install' manually."
    fi
    export PATH="$HOME/.local/share/mise/shims:$PATH"
  fi
}

fix_tool_names() {
  run mkdir -p "$HOME/.local/bin"
  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    run ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
  fi
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    run ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
}

trust_mise() {
  if command -v mise >/dev/null 2>&1; then
    run mise trust "$HOME/.config/mise/config.toml" >/dev/null 2>&1 || true
  fi
}

install_tmux_plugins() {
  local tpm="$HOME/.config/tmux/plugins/tpm"
  if [ ! -d "$tpm/.git" ]; then
    log "Installing TPM..."
    run mkdir -p "$(dirname "$tpm")"
    if ! run git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm"; then
      warn "Could not clone TPM; install tmux plugins manually with prefix + I."
      return
    fi
  else
    log "TPM already present."
  fi

  if ((DRY_RUN)); then
    printf '  would run: %s/bin/install_plugins\n' "$tpm"
    return
  fi

  local session="dotfiles-bootstrap-$$"
  tmux start-server 2>/dev/null || true
  tmux new-session -d -s "$session" 2>/dev/null || true
  if [ -x "$tpm/bin/install_plugins" ]; then
    "$tpm/bin/install_plugins" || warn "TPM plugin install failed; open tmux and press prefix + I."
  fi
  tmux kill-session -t "$session" 2>/dev/null || true
}

sync_neovim() {
  if ((SKIP_NVIM)); then
    return
  fi
  if ! command -v nvim >/dev/null 2>&1; then
    warn "Neovim not found; skipping plugin sync."
    return
  fi
  log "Syncing LazyVim plugins (first run downloads ~59 plugins)..."
  if ((DRY_RUN)); then
    printf '  would run: nvim --headless "+Lazy! sync" +qa\n'
    return
  fi
  if ! nvim --headless "+Lazy! sync" +qa; then
    warn "Lazy sync failed; open nvim and run :Lazy sync."
  fi
}

log "Repo: $REPO_DIR"
install_packages
install_neovim
install_starship
install_mise
fix_tool_names

log "Linking dotfiles..."
link_file "$REPO_DIR/home/.bashrc" "$HOME/.bashrc"
link_file "$REPO_DIR/home/.bash_profile" "$HOME/.bash_profile"
link_file "$REPO_DIR/home/.profile" "$HOME/.profile"
link_file "$REPO_DIR/home/.inputrc" "$HOME/.inputrc"
link_file "$REPO_DIR/home/.config/starship.toml" "$HOME/.config/starship.toml"
link_file "$REPO_DIR/home/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
link_file "$REPO_DIR/home/.config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
link_file "$REPO_DIR/home/.config/tmux/tmux.conf" "$HOME/.tmux.conf"
link_file "$REPO_DIR/home/.config/nvim" "$HOME/.config/nvim"

trust_mise
install_tmux_plugins
sync_neovim

log "Done."
if [ -d "$BACKUP_DIR" ]; then
  echo "Existing files were backed up to: $BACKUP_DIR"
fi

cat <<'EOF'

Next steps:
  1. Close and reopen the terminal, or run: exec bash -l
  2. Start tmux with: t
  3. In Neovim, run :Lazy and :Mason to verify plugins and LSP servers.
  4. Windows Terminal users: import windows-terminal/matte-black-scheme.json.
  5. Alacritty users: copy alacritty/alacritty.toml to %APPDATA%\alacritty\alacritty.toml.

If you use Windows Terminal, install the font first:
  powershell.exe -ExecutionPolicy Bypass -File scripts/install-font.ps1
EOF
