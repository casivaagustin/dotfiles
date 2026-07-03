# Linux-specific configuration (shared across all distros)

# Packages required for i3 desktop environment
# Install with your distro's package manager
LINUX_PACKAGES=(
  # Window manager & utilities
  i3-gaps
  picom
  dunst
  dmenu
  rofi
  i3status
  xdotool
  xautolock
  nitrogen
  xset

  # Screenshots & clipboard
  maim
  xclip
  flameshot

  # Audio
  pulseaudio
  pavucontrol
  playerctl
  pasystray

  # Display & power
  xbacklight
  xfce4-power-manager

  # System tray & desktop
  network-manager-gnome
  clipit
  polkit-gnome

  # Applications
  gnome-terminal
  pcmanfm
  moc
  conky
)
