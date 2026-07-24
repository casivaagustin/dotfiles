#!/usr/bin/env bash
# Remote bootstrap for these dotfiles.
# Intended to be run via curl-pipe:
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/casivaagustin/dotfiles/main/bootstrap.sh)"
#
# It installs git (if missing), clones the repo to ~/dotfiles
# (or fast-forwards it), then hands off to install.sh which does the
# full setup. Everything is written inside main() so the entire script
# is downloaded before any command runs — safe under curl-pipe.
set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/casivaagustin/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

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
    *manjaro*|*arch*)         echo "arch" ;;
    *ubuntu*|*debian*|*mint*) echo "debian" ;;
    *) die "Unsupported Linux distro: ID=${ID:-?} ID_LIKE=${ID_LIKE:-?}" ;;
  esac
}

ensure_git() {
  if command -v git >/dev/null 2>&1; then return; fi
  local os="$1"
  log "git not found — installing it before cloning"
  case "$os" in
    osx)
      if command -v brew >/dev/null 2>&1; then
        brew install git
      else
        log "Triggering Xcode Command Line Tools install (GUI prompt)"
        xcode-select --install || true
        die "Finish the Command Line Tools install, then re-run this command."
      fi
      ;;
    debian) sudo apt-get update && sudo apt-get install -y git ;;
    arch)   sudo pacman -Sy --noconfirm --needed git ;;
  esac
}

clone_or_update() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    log "Repo already at $DOTFILES_DIR — pulling latest"
    git -C "$DOTFILES_DIR" pull --ff-only || warn "pull failed; continuing with current checkout"
  elif [ -e "$DOTFILES_DIR" ]; then
    die "$DOTFILES_DIR exists but is not a git repo. Move or remove it and retry."
  else
    log "Cloning $REPO_URL -> $DOTFILES_DIR"
    git clone "$REPO_URL" "$DOTFILES_DIR"
  fi
}

main() {
  local os
  os="$(detect_os)"
  log "OS: $os"
  ensure_git "$os"
  clone_or_update
  log "Running installer"
  cd "$DOTFILES_DIR"
  exec bash install.sh
}

main "$@"
