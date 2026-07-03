# Manjaro/Arch-specific configuration

# Additional packages (install with pacman/yay)
MANJARO_PACKAGES=(
  i3-scrot
  i3exit
  blueman
  manjaro-hello
  pamac
  morc_menu
  ff-theme-util
  fix_xcursor
)

install_manjaro_packages() {
  local all_packages=("${LINUX_PACKAGES[@]}" "${MANJARO_PACKAGES[@]}")
  echo "Installing packages with pacman/yay..."
  yay -S --needed "${all_packages[@]}"
}
