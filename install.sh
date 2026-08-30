#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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
)

# Core Hyprland packages were orphaned/retired from the official Fedora repos
# (hyprland itself was retired as of Fedora 43), so they need a COPR.
DNF_COPR="ashbuk/Hyprland-Fedora"
DNF_COPR_PACKAGES=(
  hyprland
  hyprlock
  hyprpaper
  hyprpicker
  xdg-desktop-portal-hyprland
)

# No maintained Fedora/COPR package found for these as of writing;
# install from source if you need them: hyprshot, hyprlauncher, hyprtoolkit

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
    sudo dnf copr enable "$DNF_COPR"
    sudo dnf install "${DNF_COPR_PACKAGES[@]}"
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
  TARGET_DIR=$HOME/.config/

  mkdir -p $TARGET_DIR

  shopt -s dotglob
  ln -sf "$SOURCE_DIR"* $TARGET_DIR
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
print_outro
