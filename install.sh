#!/usr/bin/env bash
# Single-command installer for these dotfiles.
# Supports: macOS (brew), Ubuntu/Debian (apt), Manjaro/Arch (pacman).
# Reads package lists from deps/<manager>.txt.
# Safe to re-run: every step checks state before acting.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_DIR="$DOTFILES_DIR/deps"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "osx"; return ;;
    Linux)  ;;
    *) die "Unsupported OS: $(uname -s)" ;;
  esac

  [ -r /etc/os-release ] || die "Cannot detect Linux distro: /etc/os-release not found"
  # shellcheck disable=SC1091
  . /etc/os-release
  local id_list="${ID:-} ${ID_LIKE:-}"
  case "$id_list" in
    *manjaro*|*arch*)          echo "arch" ;;
    *ubuntu*|*debian*|*mint*)  echo "debian" ;;
    *) die "Unsupported Linux distro: ID=${ID:-?} ID_LIKE=${ID_LIKE:-?}" ;;
  esac
}

read_pkg_list() {
  local file="$1"
  [ -f "$file" ] || die "Missing package list: $file"
  # Strip comments, trim, drop blanks.
  sed -e 's/#.*//' -e 's/[[:space:]]\+$//' -e 's/^[[:space:]]\+//' "$file" | grep -v '^$' || true
}

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Make brew available in this shell if just installed.
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_packages_brew() {
  ensure_brew
  local pkgs
  mapfile -t pkgs < <(read_pkg_list "$DEPS_DIR/brew.txt")
  log "Installing ${#pkgs[@]} brew formulae"
  brew install "${pkgs[@]}"
}

install_packages_apt() {
  local pkgs
  mapfile -t pkgs < <(read_pkg_list "$DEPS_DIR/apt.txt")
  log "Updating apt index"
  sudo apt-get update
  log "Installing ${#pkgs[@]} apt packages"
  sudo apt-get install -y "${pkgs[@]}"
}

install_packages_pacman() {
  local pkgs
  mapfile -t pkgs < <(read_pkg_list "$DEPS_DIR/pacman.txt")
  log "Syncing pacman database"
  sudo pacman -Sy --noconfirm
  log "Installing ${#pkgs[@]} pacman packages"
  sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "oh-my-zsh already installed"
    return
  fi
  log "Installing oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

clone_if_missing() {
  local repo="$1" dest="$2" extra_args="${3:-}"
  if [ -d "$dest" ]; then
    log "Already present: $dest"
    return
  fi
  log "Cloning $repo -> $dest"
  # shellcheck disable=SC2086
  git clone $extra_args "$repo" "$dest"
}

install_zsh_ecosystem() {
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  clone_if_missing https://github.com/romkatv/powerlevel10k.git \
                   "$custom/themes/powerlevel10k" "--depth=1"
  clone_if_missing https://github.com/zsh-users/zsh-autosuggestions.git \
                   "$custom/plugins/zsh-autosuggestions"
  clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git \
                   "$custom/plugins/zsh-syntax-highlighting"
}

install_vim_runtime() {
  clone_if_missing https://github.com/amix/vimrc.git "$HOME/.vim_runtime" "--depth=1"
}

install_nvim_starter() {
  if [ -d "$HOME/.config/nvim" ]; then
    log "nvim config already present"
    return
  fi
  log "Cloning LazyVim starter -> ~/.config/nvim"
  mkdir -p "$HOME/.config"
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
}

install_fonts_osx() {
  ensure_brew
  log "Installing Meslo Nerd Font (cask)"
  brew install --cask font-meslo-lg-nerd-font
}

refresh_font_cache_linux() {
  if command -v fc-cache >/dev/null 2>&1; then
    log "Rebuilding font cache"
    fc-cache -fv >/dev/null
  else
    warn "fc-cache not available; skipping font cache refresh"
  fi
}

STOW_PACKAGES=(
  zsh
  p10k
  tmux
  vim
  nvim
  fonts
  agents-rules
  cursor
  vscode
  i3
  picom
  polybar
)

stow_packages() {
  cd "$DOTFILES_DIR"
  for pkg in "${STOW_PACKAGES[@]}"; do
    if [ ! -d "$pkg" ]; then
      warn "skipping missing package: $pkg"
      continue
    fi
    # Linux-only packages: don't stow on OSX.
    if [ "$OS" = "osx" ]; then
      case "$pkg" in
        i3|picom|polybar) warn "skipping $pkg on macOS"; continue ;;
      esac
    fi
    log "stow $pkg"
    stow --restow "$pkg"
  done
}

install_editor_extensions() {
  if command -v code >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/vscode/extensions.txt" ]; then
    log "Installing VS Code extensions"
    xargs -n1 code --install-extension < "$DOTFILES_DIR/vscode/extensions.txt" || true
  else
    warn "code CLI or vscode/extensions.txt missing; skipping VS Code extensions"
  fi

  if command -v cursor >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/cursor/extensions.txt" ]; then
    log "Installing Cursor extensions"
    xargs -n1 cursor --install-extension < "$DOTFILES_DIR/cursor/extensions.txt" || true
  else
    warn "cursor CLI or cursor/extensions.txt missing; skipping Cursor extensions"
  fi
}

main() {
  OS="$(detect_os)"
  log "Detected OS: $OS"

  case "$OS" in
    osx)    install_packages_brew ;;
    debian) install_packages_apt ;;
    arch)   install_packages_pacman ;;
  esac

  install_oh_my_zsh
  install_zsh_ecosystem
  install_vim_runtime
  install_nvim_starter

  stow_packages

  if [ "$OS" = "osx" ]; then
    install_fonts_osx
  else
    refresh_font_cache_linux
  fi

  install_editor_extensions

  log "Done. Restart your shell (or run: exec zsh) to pick up changes."
}

main "$@"
