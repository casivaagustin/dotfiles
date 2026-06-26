#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$DOTFILES_DIR"

PACKAGES=(
  zsh
  p10k
  i3
  picom
  polybar
  tmux
  vim
  nvim
  fonts
  agents-rules
  cursor
  vscode
)

echo "Stowing dotfiles..."

for package in "${PACKAGES[@]}"; do
  if [ -d "$package" ]; then
    echo "  -> stow $package"
    stow --restow "$package"
  else
    echo "  !! skipping missing package: $package"
  fi
done

echo "Installing VS Code extensions..."

if command -v code >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/vscode/extensions.txt" ]; then
  xargs -r -n1 code --install-extension < "$DOTFILES_DIR/vscode/extensions.txt"
else
  echo "  !! code command or vscode/extensions.txt not found"
fi

echo "Installing Cursor extensions..."

if command -v cursor >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/cursor/extensions.txt" ]; then
  xargs -r -n1 cursor --install-extension < "$DOTFILES_DIR/cursor/extensions.txt"
else
  echo "  !! cursor command or cursor/extensions.txt not found"
fi

echo "Done."
