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
  yay
)

YAY_PACKAGES=(
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
  yay
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
  elif command -v yay >/dev/null 2>&1; then
    package_manager=yay
  elif command -v pacman >/dev/null 2>&1; then
    package_manager=pacman
  elif command -v dnf >/dev/null 2>&1; then
    package_manager=dnf
  else
    echo "Unsupported Linux distribution: no supported package manager"
    exit 1
  fi
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
    ;;
  yay)
    yay -Sy --needed --noconfirm
    ;;
  pacman)
    sudo pacman -Sy --needed --noconfirm "${PACMAN_PACKAGES[@]}"
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
