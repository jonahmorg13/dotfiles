#!/usr/bin/env bash

#[TODO] add waybar config
#[TODO] what other config do i need to add?
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HOME_CONFIG="$HOME/.config"

APT_PACKAGES=(
  git
  curl
  wget
  vim
  unzip
  jq
  helix
  gh
  tmux
  htop
  btop
  zsh
  neovim
  kitty
  eza
  fzf
  fd-find # installs the "fd" binary as fdfind, not fd
  fastfetch
  ncdu
  tldr
  rsync
  nmap
  dunst
  brightnessctl
  pamixer
  blueman
)

DNF_PACKAGES=(
  git
  curl
  wget
  vim-enhanced
  unzip
  jq
  helix
  gh
  nextcloud-client
  tmux
  htop
  btop
  grim
  slurp
  wl-clipboard
  libnotify
  playerctl
  zsh
  neovim
  kitty
  eza
  fzf
  fd-find
  fastfetch
  ncdu
  tldr
  rsync
  nmap
  dunst
  brightnessctl
  pamixer
  blueman
  waybar
  pavucontrol
)

# Core Hyprland packages were orphaned/retired from the official Fedora repos
# (hyprland itself was retired as of Fedora 43), so they need a COPR.
# ashbuk/Hyprland-Fedora only publishes x86_64 chroots; lionheartp/Hyprland
# (a fork of solopasha/hyprland) also builds aarch64 (e.g. Fedora Asahi Remix).
DNF_COPR_X86_64="ashbuk/Hyprland-Fedora"
DNF_COPR_AARCH64="lionheartp/Hyprland"
DNF_COPR_PACKAGES=(
  hyprland
  hyprlock
  hyprpaper
  hyprpicker
  xdg-desktop-portal-hyprland
)

# ashbuk/Hyprland-Fedora (x86_64) doesn't build these; lionheartp/Hyprland
# (aarch64) does. Install from source on x86_64 if you need them there.
DNF_COPR_PACKAGES_AARCH64=(
  hyprshot
  hyprlauncher
  hyprtoolkit
)

PACMAN_PACKAGES=(
  git
  curl
  wget
  vim
  unzip
  jq
  helix
  tmux
  htop
  btop
  grim
  slurp
  wl-clipboard
  libnotify
  base-devel
  zsh
  neovim
  kitty
  eza
  fzf
  fd
  fastfetch
  ncdu
  tldr
  rsync
  nmap
  dunst
  brightnessctl
  pamixer
  blueman
  waybar
)

# AUR-only packages (or packages we want yay to resolve regardless of repo).
# These install in addition to PACMAN_PACKAGES when yay is available.
YAY_PACKAGES=(
  hyprshot
  hyprsunset
  hyprpicker
  hyprland
  hyprlauncher
  hyprlock
  hyprpaper
  hyprtoolkit
)



print_intro() {
  echo "======================================================"
  echo "===        Installing Dr. Jones Dotfiles!          ==="
  echo "======================================================"
}

get_architecture() {
  arch=$(uname -m)
  echo "System architecture: $arch"
}

get_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    package_manager=apt
  elif command -v pacman >/dev/null 2>&1; then
    package_manager=arch
  elif command -v dnf >/dev/null 2>&1; then
    package_manager=dnf
  else
    echo "Unsupported Linux distribution: no supported package manager"
    exit 1
  fi
}

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi
  echo "yay not found; bootstrapping it from the AUR..."
  local build_dir
  build_dir=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin"
  (cd "$build_dir/yay-bin" && makepkg -si --needed --noconfirm)
  rm -rf "$build_dir"
}

install_packages() {
  echo "Installing packages using: $package_manager"
  case "$package_manager" in
  apt)
    sudo add-apt-repository ppa:maveonair/helix-editor
    sudo apt-get update
    sudo apt-get install -y "${APT_PACKAGES[@]}"
    ;;
  dnf)
    sudo dnf install "${DNF_PACKAGES[@]}"
    case "$arch" in
    x86_64) dnf_copr="$DNF_COPR_X86_64" ;;
    aarch64) dnf_copr="$DNF_COPR_AARCH64" ;;
    *) dnf_copr="" ;;
    esac
    if [[ -n "$dnf_copr" ]]; then
      sudo dnf copr enable "$dnf_copr"
      sudo dnf install "${DNF_COPR_PACKAGES[@]}"
      if [[ "$arch" == "aarch64" ]]; then
        sudo dnf install "${DNF_COPR_PACKAGES_AARCH64[@]}"
      fi
    else
      echo "No known Hyprland COPR for $arch; skipping: ${DNF_COPR_PACKAGES[*]}"
    fi
    ;;
  arch)
    sudo pacman -Sy --needed --noconfirm "${PACMAN_PACKAGES[@]}"
    install_yay
    if command -v yay >/dev/null 2>&1; then
      yay -Sy --needed --noconfirm "${YAY_PACKAGES[@]}"
    else
      echo "yay not found; skipping AUR packages: ${YAY_PACKAGES[*]}"
    fi
    ;;
  *)
    echo "Unsupported package manager: $package_manager"
    exit 1
    ;;
  esac
}

symlink_configurations() {
  SOURCE_DIR=$SCRIPT_DIR/.config/
  TARGET_DIR=$HOME_CONFIG/

  mkdir -p $TARGET_DIR

  shopt -s dotglob
  ln -sf "$SOURCE_DIR"* $TARGET_DIR
}

select_theme() {
  THEMES_DIR=$SCRIPT_DIR/themes
  COUNT=1
  echo "Choose theme:"
  for n in $(ls $THEMES_DIR)
  do
    echo $COUNT: $n
    COUNT=$((COUNT + 1))
  done;
  read -p "Choose your theme: " THEME_CHOICE
  if ! [[ "$THEME_CHOICE" =~ ^[0-9]+$ ]]; then
    echo "Not a number. Aborting..."
    exit
  elif [ "$THEME_CHOICE" -lt "1" ] || [ "$THEME_CHOICE" -ge "$COUNT" ]; then
    echo "Incorrect choice. Aborting..."
    exit
  fi

  NEW_COUNT=1
  for n in $(ls $THEMES_DIR)
  do
    if [ "$NEW_COUNT" -eq "$THEME_CHOICE" ]; then
      # Symlink every app directory in this theme (hypr, waybar, dunst, ...)
      # over top of the corresponding ~/.config/<app>, overriding whatever
      # symlink_configurations already set up for shared/non-themed apps.
      for app in $(ls $THEMES_DIR/$n); do
        # -n keeps ln from following an existing ~/.config/<app> symlink into
        # its target directory (which would drop the new link inside it
        # instead of replacing ~/.config/<app> itself).
        ln -sfn "$THEMES_DIR/$n/$app" "$HOME_CONFIG/$app"
      done
    fi
    NEW_COUNT=$((NEW_COUNT + 1))
  done;
}

restart_hypr_daemons() {
  if pgrep -x Hyprland >/dev/null 2>&1; then
    echo "Reloading Hyprland config..."
    hyprctl reload
  fi

  if pgrep -x waybar >/dev/null 2>&1; then
    echo "Restarting waybar..."
    pkill -x waybar
    setsid -f waybar >/dev/null 2>&1
  fi

  if pgrep -x dunst >/dev/null 2>&1; then
    echo "Restarting dunst..."
    pkill -x dunst
    setsid -f dunst >/dev/null 2>&1
  fi

  if pgrep -x hyprpaper >/dev/null 2>&1; then
    echo "Restarting hyprpaper..."
    pkill -x hyprpaper
    setsid -f hyprpaper >/dev/null 2>&1
  fi

  if pgrep -x hyprlauncher >/dev/null 2>&1; then
    echo "Restarting hyprlauncher..."
    pkill -x hyprlauncher
    setsid -f hyprlauncher >/dev/null 2>&1
  fi
}

print_outro() {
  echo "======================================================"
  echo "===                     FIN                        ==="
  echo "======================================================"
}

print_intro
get_architecture
get_package_manager
install_packages
symlink_configurations
select_theme
restart_hypr_daemons
print_outro
