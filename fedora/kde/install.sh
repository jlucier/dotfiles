#!/usr/bin/env bash
# Install the programs for a Fedora KDE Plasma desktop.
#
# Idempotent: every step checks for its result before it acts, so a rerun only
# fills in what is missing. dnf and flatpak already skip installed packages.
#
# This script installs packages only. The root install.sh links the config
# files, and fedora/kde/plasma.sh applies the Plasma settings. install.sh
# --desktop-env runs all three in that order.
#
# Usage: fedora/kde/install.sh [--personal]
#
#   --personal   Also install Discord and Steam. Leave this off on a work machine.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

PERSONAL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --personal) PERSONAL=1 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

group() {
  echo
  echo "--- $1 ---"
}

# --- dnf ------------------------------------------------------------------
dnf_setup() {
  group "dnf"

  if ! cmp -s "$REPO/fedora/dnf.conf" /etc/dnf/dnf.conf; then
    sudo cp "$REPO/fedora/dnf.conf" /etc/dnf/dnf.conf
    echo "installed /etc/dnf/dnf.conf"
  fi

  local fv
  fv="$(rpm -E %fedora)"

  if ! rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1; then
    sudo dnf install -y \
      "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$fv.noarch.rpm" \
      "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$fv.noarch.rpm"
  fi

  sudo dnf install -y dnf-plugins-core
  sudo dnf group install -y c-development
}

# Add a repo file from a URL, unless a repo file with that name already exists.
add_repo() {
  local url="$1" name="$2"

  [ -f "/etc/yum.repos.d/$name.repo" ] && return 0
  sudo dnf config-manager addrepo --from-repofile="$url"
}

# --- packages -------------------------------------------------------------
packages() {
  group "packages"

  sudo dnf install -y \
    zsh \
    neovim python3-neovim \
    tmux \
    zoxide fzf fd-find ripgrep \
    htop jq \
    git gh \
    wl-clipboard \
    syncthing \
    wireguard-tools \
    zig \
    curl \
    google-noto-emoji-color-fonts

  # ghostty build dependencies, from https://ghostty.org/docs/install/build.
  # A Git checkout also needs blueprint-compiler (HACKING.md). libglvnd-devel
  # provides egl.pc, which the docs leave out. pandoc is optional; with it the
  # build installs the man pages.
  sudo dnf install -y \
    gtk4-devel \
    gtk4-layer-shell-devel \
    libadwaita-devel \
    libglvnd-devel \
    gettext \
    pkgconf-pkg-config \
    blueprint-compiler \
    pandoc-cli
}

# --- vendor repos ---------------------------------------------------------
vendor_apps() {
  group "vendor apps"

  # docker
  add_repo https://download.docker.com/linux/fedora/docker-ce.repo docker-ce
  sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  if ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    echo "added $USER to the docker group; log out and in to use it"
  fi

  # brave
  add_repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo brave-browser
  sudo dnf install -y brave-browser

  # 1password
  if [ ! -f /etc/yum.repos.d/1password.repo ]; then
    sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
    sudo tee /etc/yum.repos.d/1password.repo >/dev/null <<'REPO'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
REPO
  fi
  sudo dnf install -y 1password
}

# --- flatpaks -------------------------------------------------------------
# Run as root: a user install goes through flatpak-system-helper and
# revokefs-fuse, and a killed run leaves their mounts behind and blocks the
# next run.
flatpaks() {
  group "flatpaks"

  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  sudo flatpak install -y --noninteractive flathub \
    com.slack.Slack \
    com.spotify.Client \
    md.obsidian.Obsidian

  if [ "$PERSONAL" -eq 1 ]; then
    sudo flatpak install -y --noninteractive flathub \
      com.discordapp.Discord \
      com.valvesoftware.Steam
  fi
}

# --- zen ------------------------------------------------------------------
# Zen ships no RPM. The official tarball goes to /opt/zen, root-owned with
# mode 755, because the 1Password app only talks to a browser whose executable
# is root-owned and not user-writable. A Flatpak cannot pass that check.
# Reruns compare the installed version with the latest GitHub release.
zen() {
  group "zen"

  local latest installed tmp
  latest="$(curl -fsSL https://api.github.com/repos/zen-browser/desktop/releases/latest | jq -r .tag_name)"
  installed="$(sed -n 's/^Version=//p' /opt/zen/application.ini 2>/dev/null || true)"

  if [ "$installed" = "$latest" ]; then
    echo "OK       zen $installed"
  else
    tmp="$(mktemp -d)"
    curl -fL https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz \
      | tar -xJ -C "$tmp"
    sudo rm -rf /opt/zen
    sudo mv "$tmp/zen" /opt/zen
    sudo chown -R root:root /opt/zen
    sudo chmod 755 /opt/zen
    rm -rf "$tmp"
    echo "installed zen $latest"
  fi

  sudo install -m 644 "$REPO/fedora/kde/zen.desktop" /usr/share/applications/zen.desktop
  sudo install -m 644 /opt/zen/browser/chrome/icons/default/default128.png \
    /usr/share/icons/hicolor/128x128/apps/zen.png

  # 1Password browser allowlist
  if ! sudo cmp -s "$REPO/fedora/kde/1password-allowed-browsers" /etc/1password/custom_allowed_browsers; then
    sudo install -D -m 644 "$REPO/fedora/kde/1password-allowed-browsers" /etc/1password/custom_allowed_browsers
    echo "installed /etc/1password/custom_allowed_browsers; restart 1Password to apply"
  fi
}

# --- fonts ----------------------------------------------------------------
fonts() {
  group "fonts"

  local dir="$HOME/.local/share/fonts"
  local file="$dir/JetBrainsMonoNLNerdFont-Regular.ttf"

  [ -f "$file" ] && return 0

  # The nerd-fonts repo no longer holds the patched fonts, so take the one
  # file out of the release archive.
  mkdir -p "$dir"
  curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
    | tar -xJ -C "$dir" "$(basename "$file")"
  fc-cache -f "$dir"
}

# --- ghostty --------------------------------------------------------------
# Built from a pinned commit on main. The Fedora zig package (0.16) is newer
# than the zig that the latest ghostty release accepts, and main tracks the
# current zig.
#
# The pin is the last commit before ghostty-org/ghostty#14052 (merged
# 2026-09-14). That change removed GtkGLArea: ghostty now renders in its own
# EGL context and passes each frame to GTK as a DMA-BUF exported with
# eglExportDMABUFImageMESA. The proprietary NVIDIA EGL does not provide that
# extension, so glvnd hands the display to Mesa, Mesa has no driver for the
# card, and ghostty renders in software with llvmpipe. The result is heavy
# artifacting. Move the pin forward once upstream supports NVIDIA on the new
# path.
GHOSTTY_COMMIT=d30379c5b

ghostty() {
  group "ghostty"

  local src="$HOME/.local/src/ghostty"

  if [ -d "$src/.git" ]; then
    git -C "$src" fetch origin
  else
    mkdir -p "$(dirname "$src")"
    git clone https://github.com/ghostty-org/ghostty.git "$src"
  fi
  git -C "$src" checkout --detach "$GHOSTTY_COMMIT"

  # -p installs bin/, share/applications/, share/icons/ under ~/.local, which
  # is on PATH and in the XDG data dirs, so Plasma sees the launcher.
  (cd "$src" && zig build -p "$HOME/.local" -Doptimize=ReleaseFast)

  # The desktop file is DBusActivatable, so Plasma starts ghostty through the
  # bus name, which a systemd user unit provides. Both the bus and systemd read
  # their service files at login, so reload them for the first launch.
  systemctl --user daemon-reload
  busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig
}

# --- shell ----------------------------------------------------------------
shell() {
  group "shell"

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  fi

  local zsh
  zsh="$(command -v zsh)"
  if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh" ]; then
    sudo usermod -s "$zsh" "$USER"
  fi

  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  fi
}

# --- AI tools -------------------------------------------------------------
# Each vendor installer puts its binary under ~/.local/bin.
ai_tools() {
  group "AI tools"

  local name url
  for name in herdr pi claude; do
    if command -v "$name" >/dev/null 2>&1; then
      echo "OK       $name"
      continue
    fi

    case "$name" in
      herdr)  url=https://herdr.dev/install.sh ;;
      pi)     url=https://pi.dev/install.sh ;;
      claude) url=https://claude.ai/install.sh ;;
    esac

    curl -fsSL "$url" | sh
  done
}

# --- services -------------------------------------------------------------
services() {
  group "services"
  systemctl --user enable --now syncthing.service
}

## MAIN

dnf_setup
packages
vendor_apps
flatpaks
zen
fonts
ghostty
shell
ai_tools
services

cat <<'HINT'

Done. Docker is installed but not enabled. To start it at boot, run:
  sudo systemctl enable --now docker
HINT
