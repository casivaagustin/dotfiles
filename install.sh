#!/usr/bin/env bash
# Single-command installer for these dotfiles.
# Supports: macOS (brew), Ubuntu/Debian (apt), Manjaro/Arch (pacman).
# Reads package lists from deps/<manager>.txt.
# Safe to re-run: every step checks state before acting.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_DIR="$DOTFILES_DIR/deps"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
step() { printf '\n\033[1;36m--- [Step %s] %s ---\033[0m\n' "$1" "$2"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

banner() {
  printf '\033[1;35m'
  cat <<'BANNER'

     _       _    __ _ _
  __| | ___ | |_ / _(_) | ___  ___
 / _` |/ _ \| __| |_| | |/ _ \/ __|
| (_| | (_) | |_|  _| | |  __/\__ \
 \__,_|\___/ \__|_| |_|_|\___||___/

BANNER
  printf '\033[0m'
  printf '\033[1mDotfiles installer\033[0m\n'
  printf 'Supports: macOS (brew) | Ubuntu/Debian (apt) | Manjaro/Arch (pacman)\n'
  printf 'Safe to re-run: every step checks state before acting.\n\n'
}

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

# Load a package list into a bash-3-compatible array (macOS ships bash 3.2,
# which has no `mapfile`/`readarray`). Usage: read_pkg_array <file> <varname>
read_pkg_array() {
  local __file="$1" __var="$2" __line
  eval "$__var=()"
  while IFS= read -r __line; do
    [ -n "$__line" ] || continue
    eval "${__var}+=(\"\$__line\")"
  done < <(read_pkg_list "$__file")
}

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew (non-interactive)"
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Make brew available in this shell if just installed.
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# Prime sudo and keep the timestamp fresh in the background so no step later
# in the installer stops to prompt for a password.
sudo_keep_alive() {
  if ! command -v sudo >/dev/null 2>&1; then return; fi
  log "Priming sudo — enter your password once; the installer will keep it alive"
  sudo -v
  ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

install_packages_brew() {
  ensure_brew
  local formulae casks
  read_pkg_array "$DEPS_DIR/brew.txt"      formulae
  read_pkg_array "$DEPS_DIR/brew-cask.txt" casks
  # Only install formulae that aren't already present.
  local f_missing=() f
  for f in "${formulae[@]}"; do
    if brew list --formula "$f" >/dev/null 2>&1; then
      log "formula already installed: $f"
    else
      f_missing+=("$f")
    fi
  done
  if [ "${#f_missing[@]}" -gt 0 ]; then
    log "Installing ${#f_missing[@]} brew formulae (of ${#formulae[@]} listed)"
    brew install "${f_missing[@]}"
  else
    log "All ${#formulae[@]} brew formulae already installed"
  fi
  # Cursor Agent CLI
  if ! command -v cursor-agent >/dev/null 2>&1; then
    log "Installing Cursor Agent CLI"
    curl -fsSL https://cursor.com/install | bash
  fi

  # Claude Code CLI
  if ! command -v claude >/dev/null 2>&1; then
    log "Installing Claude Code CLI"
    curl -fsSL https://claude.ai/install.sh | bash
  fi

  # Anti Gravity CLI
  if ! command -v antigravity >/dev/null 2>&1; then
    log "Installing Anti Gravity CLI"
    curl -fsSL https://antigravity.google/cli/install.sh | bash
  fi

  # OpenCode CLI
  if ! command -v opencode >/dev/null 2>&1; then
    log "Installing OpenCode CLI"
    curl -fsSL https://opencode.ai/install | bash
  fi

  if [ "${#casks[@]}" -gt 0 ]; then
    log "Installing brew casks (skipping already-installed)"
    for cask in "${casks[@]}"; do
      if brew list --cask "$cask" >/dev/null 2>&1; then
        log "cask already installed: $cask"
      else
        brew install --cask "$cask" || warn "failed to install cask: $cask (may already exist outside Homebrew)"
      fi
    done
  fi
}

install_packages_apt() {
  # Remove any pre-existing Docker repo config that may conflict with ours.
  sudo rm -f /etc/apt/keyrings/docker.asc
  sudo rm -f /etc/apt/sources.list.d/docker.list
  sudo rm -f /etc/apt/sources.list.d/docker.sources
  local pkgs
  read_pkg_array "$DEPS_DIR/apt.txt" pkgs
  log "Updating apt index"
  sudo apt-get update
  log "Installing ${#pkgs[@]} apt packages"
  sudo apt-get install -y "${pkgs[@]}"
  if [ -x "$DEPS_DIR/apt-third-party.sh" ]; then
    log "Installing third-party apt packages"
    bash "$DEPS_DIR/apt-third-party.sh"
  fi
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then return; fi
  log "Bootstrapping yay (AUR helper)"
  sudo pacman -S --needed --noconfirm base-devel git
  local tmpdir
  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (cd "$tmpdir/yay" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
}

install_packages_pacman() {
  local pkgs
  read_pkg_array "$DEPS_DIR/pacman.txt" pkgs
  log "Syncing pacman database"
  sudo pacman -Sy --noconfirm

  # Skip any package already satisfied by an installed package OR a provider
  # (e.g. Manjaro ships `dmenu-manjaro`, which provides `dmenu`). Installing the
  # upstream name would trigger a replace/conflict prompt that --noconfirm
  # auto-declines, aborting the whole transaction. `pacman -T` reports only the
  # unsatisfied targets, honouring provides.
  local missing=()
  while IFS= read -r pkg; do
    [ -n "$pkg" ] && missing+=("$pkg")
  done < <(pacman -T "${pkgs[@]}" 2>/dev/null || true)

  if [ "${#missing[@]}" -eq 0 ]; then
    log "All ${#pkgs[@]} pacman packages already satisfied"
  else
    log "Installing ${#missing[@]} pacman packages (of ${#pkgs[@]} listed)"
    sudo pacman -S --needed --noconfirm "${missing[@]}"
  fi

  local aur_pkgs
  read_pkg_array "$DEPS_DIR/aur.txt" aur_pkgs
  if [ "${#aur_pkgs[@]}" -gt 0 ]; then
    # Skip AUR packages already installed or provided, same as above. This also
    # avoids bootstrapping yay when everything is already present.
    local aur_missing=()
    while IFS= read -r pkg; do
      [ -n "$pkg" ] && aur_missing+=("$pkg")
    done < <(pacman -T "${aur_pkgs[@]}" 2>/dev/null || true)

    if [ "${#aur_missing[@]}" -eq 0 ]; then
      log "All ${#aur_pkgs[@]} AUR packages already satisfied"
    else
      ensure_yay
      log "Installing ${#aur_missing[@]} AUR packages via yay (of ${#aur_pkgs[@]} listed)"
      yay -S --needed --noconfirm --removemake \
          --answerdiff=None --answerclean=None --answeredit=None \
          "${aur_missing[@]}"
    fi
  fi
}

install_nvm() {
  export NVM_DIR="$HOME/.nvm"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    log "Installing nvm"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
  else
    log "nvm already installed"
  fi
  # Load nvm into this shell so `nvm` and `npm` work below.
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  log "Installing latest Node.js via nvm and setting it as default"
  nvm install node --default
  nvm use default >/dev/null
}

install_npm_globals() {
  if ! command -v npm >/dev/null 2>&1; then
    warn "npm not available; skipping npm globals"
    return
  fi
  local pkgs
  read_pkg_array "$DEPS_DIR/npm.txt" pkgs
  if [ "${#pkgs[@]}" -eq 0 ]; then return; fi
  log "Installing ${#pkgs[@]} npm global packages"
  npm install -g "${pkgs[@]}"
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

# Pick a Cursor CLI that installs extensions HEADLESSLY. Cursor's "Install
# 'cursor' command in PATH" (and some manual installs) symlink
# /usr/local/bin/cursor to a monolithic AppImage/GUI binary that just opens the
# editor when given --install-extension. The package-managed launcher runs the
# VS Code CLI headlessly, so prefer it over whatever `cursor` resolves to.
resolve_cursor_cli() {
  local c
  for c in /usr/bin/cursor /usr/share/cursor/bin/cursor; do
    [ -x "$c" ] && { echo "$c"; return; }
  done
  command -v cursor 2>/dev/null || true
}

install_editor_extensions() {
  local ext_list="$DOTFILES_DIR/vscode/extensions.txt"

  if command -v code >/dev/null 2>&1 && [ -f "$ext_list" ]; then
    log "Installing VS Code extensions"
    xargs -n1 -I{} code --install-extension {} --force < "$ext_list" || true
  else
    warn "code CLI or $ext_list missing; skipping VS Code extensions"
  fi

  local cursor_bin
  cursor_bin="$(resolve_cursor_cli)"
  if [ -n "$cursor_bin" ] && [ -f "$ext_list" ]; then
    log "Installing Cursor extensions via $cursor_bin"
    xargs -n1 -I{} "$cursor_bin" --install-extension {} --force < "$ext_list" || true
  else
    warn "cursor CLI or $ext_list missing; skipping Cursor extensions"
  fi
}

main() {
  banner

  OS="$(detect_os)"
  log "Detected OS: $OS"

  sudo_keep_alive

  step 1 "Installing system packages"
  case "$OS" in
    osx)    install_packages_brew ;;
    debian) install_packages_apt ;;
    arch)   install_packages_pacman ;;
  esac

  step 2 "Installing Oh My Zsh"
  install_oh_my_zsh

  step 3 "Installing Zsh ecosystem (powerlevel10k, plugins)"
  install_zsh_ecosystem

  step 4 "Installing Vim runtime"
  install_vim_runtime

  step 5 "Installing Neovim (LazyVim starter)"
  install_nvim_starter

  step 6 "Installing nvm and Node.js"
  install_nvm

  step 7 "Installing npm global packages"
  install_npm_globals

  step 8 "Symlinking dotfiles with stow"
  stow_packages

  step 9 "Setting up fonts"
  if [ "$OS" = "osx" ]; then
    install_fonts_osx
  else
    refresh_font_cache_linux
  fi

  step 10 "Installing editor extensions (VS Code, Cursor)"
  install_editor_extensions

  printf '\n\033[1;32m'
  log "All done! Restart your shell (or run: exec zsh) to pick up changes."
  printf '\033[0m'
}

main "$@"
