# Debian/Ubuntu-specific configuration

# Package name overrides for apt
DEBIAN_PACKAGES=(
  i3-scrot
  blueman
  xkill
)

install_debian_packages() {
  local all_packages=("${LINUX_PACKAGES[@]}" "${DEBIAN_PACKAGES[@]}")
  echo "Installing packages with apt..."
  sudo apt install -y "${all_packages[@]}"
}
