#! /bin/bash -e
#
# Trial setup for the Sway window manager alongside an existing Plasma/SDDM
# install. Safe to run in parallel with KDE: it only installs packages and
# symlinks the sway config -- SDDM lets you pick Sway or Plasma per-login.
#
# Usage: ./fedora/sway.sh   (run from the repo root, or anywhere)

# Repo root, derived from this script's location (fedora/sway.sh -> ..)
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

packages() {
    # swaywm:          sway core + swaybg/swayidle/swaylock, waybar, grim, slurp
    # swaywm-extended: the Fedora Sway spin layer (rofi-wayland, kanshi,
    #                  wl-clipboard, playerctl, etc.)
    #
    # Exclude sddm-wayland-sway: it's an alternative SDDM *greeter* (the login
    # screen's own compositor) and conflicts with the sddm-wayland-plasma
    # greeter already installed by KDE. It has nothing to do with running Sway
    # as a session, so we skip it to avoid uninstalling the Plasma greeter.
    sudo dnf group install -y swaywm swaywm-extended --exclude=sddm-wayland-sway
}

dotconfig() {
    # Matches the symlink pattern from install.sh's dotconfig(): config/<x>
    # is linked into ~/.config/<x>.
    if [ -e ~/.config/sway ] || [ -L ~/.config/sway ]; then
        echo "~/.config/sway already exists, leaving it alone"
    else
        ln -s "$repo/config/sway" ~/.config/sway
        echo "linked ~/.config/sway -> $repo/config/sway"
    fi
}

## MAIN

packages
dotconfig

cat <<'EOF'

Done. To start Sway:
  1. Log out of Plasma.
  2. At the SDDM login screen, use the session picker and choose "Sway".
  3. Log in. KDE stays selectable in the same menu.

In Sway: Super+Return = ghostty, Super+d = rofi, Super+Shift+e = exit.
EOF
