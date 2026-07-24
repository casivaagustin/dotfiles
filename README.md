# Dotfiles

These are my dot files, this repo is desinged to be used be my and just me. This readme is for me to don't forget
how it works and how to use it.

## One-line remote install

Runs everything on Manjaro/Arch, Ubuntu/Debian, and macOS from a fresh machine.
Safe to re-run.

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/casivaagustin/dotfiles/main/bootstrap.sh)"
```

Override defaults with env vars if needed:

```
DOTFILES_DIR=~/code/dotfiles \
DOTFILES_REPO=https://github.com/casivaagustin/dotfiles.git \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/casivaagustin/dotfiles/main/bootstrap.sh)"
```

## Local install

If the repo is already cloned:

```
cd ~/dotfiles
./install.sh
```

## What gets installed

`bootstrap.sh` detects the OS, installs `git` if missing, clones this repo to
`~/dotfiles`, then hands off to `install.sh`. `install.sh` performs the steps
below, skipping anything already present.

**OS packages** — installed from the appropriate list under `deps/`:

- `deps/apt.txt`             — Ubuntu / Debian, official repos (`sudo apt-get install`)
- `deps/apt-third-party.sh`  — Ubuntu / Debian, third-party repos: Google Chrome, Brave, VS Code, 1Password, Insync, DBeaver, plus Tailscale (official installer), Discord (.deb), Cursor (AppImage in `~/Applications`)
- `deps/pacman.txt`          — Manjaro / Arch, official repos (`sudo pacman -S --needed`)
- `deps/aur.txt`             — Manjaro / Arch, AUR packages installed via `yay` (1Password, Google Chrome, Brave, Insync, Cursor, VS Code). `yay` is bootstrapped from AUR git on first run.
- `deps/brew.txt`             — macOS Homebrew formulae (`brew install`; Homebrew is installed first if missing)
- `deps/brew-cask.txt`       — macOS Homebrew casks / GUI apps (`brew install --cask`): 1Password, Brave, Calibre, Cursor, DBeaver, Discord, Chrome, Insync, Tailscale, VS Code

Edit those files to add or drop dependencies.

**Node.js via nvm** — the installer clones [nvm](https://github.com/nvm-sh/nvm)
into `~/.nvm`, installs the latest Node.js with `nvm install node --default`,
and sets it as the default version. `zsh/.zsh.d/04-tools.zsh` already sources
nvm on shell startup, so no manual PATH setup is needed. Node.js and npm are
intentionally NOT in the OS package lists — nvm is the single source of truth.

**Global npm CLIs** — installed via `npm install -g` after nvm is set up:

- `deps/npm.txt` — Claude Code (`@anthropic-ai/claude-code`), Codex (`@openai/codex`), OpenCode (`opencode-ai`). Google Antigravity CLI is listed but commented pending package-name verification.

**Zsh ecosystem** — cloned into the standard oh-my-zsh locations:

- oh-my-zsh at `~/.oh-my-zsh`
- powerlevel10k theme at `$ZSH_CUSTOM/themes/powerlevel10k`
- zsh-autosuggestions plugin at `$ZSH_CUSTOM/plugins/zsh-autosuggestions`
- zsh-syntax-highlighting plugin at `$ZSH_CUSTOM/plugins/zsh-syntax-highlighting`

**Editor starters**:

- Ultimate VIM (amix/vimrc) at `~/.vim_runtime`
- LazyVim starter at `~/.config/nvim`

**Stow packages** — every top-level config directory is symlinked into place with
`stow`. Linux-only packages (`i3`, `picom`, `polybar`) are skipped on macOS.

- `zsh`, `p10k`, `tmux`, `vim`, `nvim`
- `fonts`, `agents-rules`
- `cursor`, `vscode`
- `i3`, `picom`, `polybar` (Linux only)

**Fonts**:

- Linux: `fc-cache -fv` is run after `stow fonts`
- macOS: `font-meslo-lg-nerd-font` is installed via Homebrew cask

**Editor extensions** — installed if the CLI is available:

- VS Code extensions from `vscode/extensions.txt` (via `code --install-extension`)
- Cursor extensions from `cursor/extensions.txt` (via `cursor --install-extension`)

## Links and more info

- https://www.youtube.com/watch?v=y6XCebnB9gs
- https://www.youtube.com/watch?v=NoFiYOqnC4o&t=10s
- https://www.youtube.com/watch?v=mmqDYw9C30I
- https://www.josean.com/posts/7-amazing-cli-tools
