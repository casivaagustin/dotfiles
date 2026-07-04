#!/usr/bin/env bash
# Adds third-party apt repos (Chrome, Brave, VS Code, 1Password, Insync,
# DBeaver) and installs those packages, plus a few apps that ship as raw
# .deb / AppImage (Discord, Cursor) and Tailscale (via its own installer).
# Idempotent: each block checks if the app is already installed before acting.
# Called from install.sh on Ubuntu/Debian.
set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# shellcheck disable=SC1091
. /etc/os-release
CODENAME="${VERSION_CODENAME:-stable}"
ARCH="$(dpkg --print-architecture)"

need_update=0
add_repo() {
  # add_repo <name> <keyring-url> <deb-line>
  local name="$1" key_url="$2" deb_line="$3"
  local key_path="/usr/share/keyrings/${name}-archive-keyring.gpg"
  local list_path="/etc/apt/sources.list.d/${name}.list"
  if [ -f "$list_path" ] && [ -f "$key_path" ]; then
    return
  fi
  log "Adding $name apt repo"
  curl -fsSL "$key_url" | sudo gpg --yes --dearmor -o "$key_path"
  echo "$deb_line" | sudo tee "$list_path" >/dev/null
  need_update=1
}

apt_install() { sudo apt-get install -y "$@"; }

# ---------------------------------------------------------------------------
# Google Chrome — install via official .deb (simpler than adding their repo).
# ---------------------------------------------------------------------------
if ! dpkg -s google-chrome-stable >/dev/null 2>&1; then
  log "Installing Google Chrome (.deb)"
  tmp="$(mktemp -d)"
  wget -qO "$tmp/chrome.deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  chmod 644 "$tmp/chrome.deb"
  sudo apt-get install -y "$tmp/chrome.deb"
  rm -rf "$tmp"
fi

# ---------------------------------------------------------------------------
# Brave Browser
# ---------------------------------------------------------------------------
add_repo brave-browser \
  https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
  "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=$ARCH] https://brave-browser-apt-release.s3.brave.com/ stable main"

# ---------------------------------------------------------------------------
# VS Code (Microsoft)
# ---------------------------------------------------------------------------
add_repo vscode \
  https://packages.microsoft.com/keys/microsoft.asc \
  "deb [signed-by=/usr/share/keyrings/vscode-archive-keyring.gpg arch=amd64,arm64,armhf] https://packages.microsoft.com/repos/code stable main"

# ---------------------------------------------------------------------------
# 1Password
# ---------------------------------------------------------------------------
add_repo 1password \
  https://downloads.1password.com/linux/keys/1password.asc \
  "deb [signed-by=/usr/share/keyrings/1password-archive-keyring.gpg arch=amd64] https://downloads.1password.com/linux/debian/amd64 stable main"

# 1Password also wants a debsig policy for package verification.
if [ ! -f /etc/debsig/policies/AC2D62742012EA22/1password.pol ]; then
  log "Adding 1Password debsig policy"
  sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
  curl -fsSL https://downloads.1password.com/linux/debian/debsig/1password.pol \
    | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null
  sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
  curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
    | sudo gpg --yes --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
fi

# ---------------------------------------------------------------------------
# Insync
# ---------------------------------------------------------------------------
add_repo insync \
  https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key \
  "deb [signed-by=/usr/share/keyrings/insync-archive-keyring.gpg] http://apt.insync.io/${ID} ${CODENAME} non-free contrib"

# ---------------------------------------------------------------------------
# DBeaver Community
# ---------------------------------------------------------------------------
add_repo dbeaver \
  https://dbeaver.io/debs/dbeaver.gpg.key \
  "deb [signed-by=/usr/share/keyrings/dbeaver-archive-keyring.gpg] https://dbeaver.io/debs/dbeaver-ce /"

# ---------------------------------------------------------------------------
# Docker CE (docker.com's apt repo, newer than the distro-shipped docker.io)
# ---------------------------------------------------------------------------
# Remove conflicting Docker repo configs from prior installs before adding ours.
sudo rm -f /etc/apt/keyrings/docker.asc /etc/apt/sources.list.d/docker.list
add_repo docker \
  "https://download.docker.com/linux/${ID}/gpg" \
  "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg arch=$ARCH] https://download.docker.com/linux/${ID} ${CODENAME} stable"

# ---------------------------------------------------------------------------
# Apt update + install everything from the repos we just added
# ---------------------------------------------------------------------------
if [ "$need_update" -eq 1 ]; then
  log "Updating apt index for third-party repos"
  sudo apt-get update
fi

log "Installing third-party apt packages"
apt_install brave-browser code 1password insync dbeaver-ce \
            docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ---------------------------------------------------------------------------
# Tailscale — use their official installer (adds its own repo).
# ---------------------------------------------------------------------------
if ! command -v tailscale >/dev/null 2>&1; then
  log "Installing Tailscale via official installer"
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# ---------------------------------------------------------------------------
# Discord — no apt repo; ships as .deb.
# ---------------------------------------------------------------------------
if ! command -v discord >/dev/null 2>&1; then
  log "Installing Discord (.deb)"
  tmp="$(mktemp -d)"
  wget -qO "$tmp/discord.deb" "https://discord.com/api/download?platform=linux&format=deb"
  sudo apt-get install -y "$tmp/discord.deb"
  rm -rf "$tmp"
fi

# ---------------------------------------------------------------------------
# Cursor Agent CLI
# ---------------------------------------------------------------------------
if ! command -v cursor-agent >/dev/null 2>&1; then
  log "Installing Cursor Agent CLI"
  curl -fsSL https://cursor.com/install | bash
fi

# ---------------------------------------------------------------------------
# Cursor IDE (.deb)
# ---------------------------------------------------------------------------
if ! dpkg -s cursor >/dev/null 2>&1; then
  log "Installing Cursor IDE (.deb)"
  tmp="$(mktemp -d)"
  wget -qO "$tmp/cursor.deb" "https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/latest"
  chmod 644 "$tmp/cursor.deb"
  sudo apt-get install -y "$tmp/cursor.deb"
  rm -rf "$tmp"
fi

# ---------------------------------------------------------------------------
# lazydocker — no apt package; use upstream install script (installs to
# ~/.local/bin, which the zsh config already adds to PATH).
# ---------------------------------------------------------------------------
if ! command -v lazydocker >/dev/null 2>&1; then
  log "Installing lazydocker"
  curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
fi

# ---------------------------------------------------------------------------
# ctop — no apt package; drop the release binary into /usr/local/bin.
# ---------------------------------------------------------------------------
if ! command -v ctop >/dev/null 2>&1; then
  log "Installing ctop"
  ctop_arch="amd64"
  [ "$ARCH" = "arm64" ] && ctop_arch="arm64"
  ctop_ver="0.7.7"
  sudo wget -qO /usr/local/bin/ctop \
    "https://github.com/bcicen/ctop/releases/download/v${ctop_ver}/ctop-${ctop_ver}-linux-${ctop_arch}"
  sudo chmod +x /usr/local/bin/ctop
fi

# ---------------------------------------------------------------------------
# Lando — install via upstream setup script (fetches the correct .deb).
# --yes is honored by their setup-lando.sh to skip prompts.
# ---------------------------------------------------------------------------
if ! command -v lando >/dev/null 2>&1; then
  log "Installing Lando"
  curl -fsSL https://get.lando.dev/setup-lando.sh | bash -s -- --yes
fi

# ---------------------------------------------------------------------------
# Claude Code CLI
# ---------------------------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  log "Installing Claude Code CLI"
  curl -fsSL https://claude.ai/install.sh | bash
fi

# ---------------------------------------------------------------------------
# Anti Gravity CLI
# ---------------------------------------------------------------------------
if ! command -v antigravity >/dev/null 2>&1; then
  log "Installing Anti Gravity CLI"
  curl -fsSL https://antigravity.google/cli/install.sh | bash
fi

# ---------------------------------------------------------------------------
# OpenCode CLI
# ---------------------------------------------------------------------------
if ! command -v opencode >/dev/null 2>&1; then
  log "Installing OpenCode CLI"
  curl -fsSL https://opencode.ai/install | bash
fi
