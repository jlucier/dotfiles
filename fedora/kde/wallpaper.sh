#!/usr/bin/env bash
# Set the Plasma desktop, lock screen, and Plasma Login wallpaper to one image.
set -euo pipefail

fail() {
  echo "ERROR    $*" >&2
  exit 1
}

if [ "$#" -ne 1 ]; then
  echo "Usage: fedora/kde/wallpaper.sh IMAGE_PATH" >&2
  exit 2
fi

case "$1" in
  /*) ;;
  *) fail "image path must be absolute: $1" ;;
esac

image="$(realpath -e -- "$1")" || fail "image path does not exist: $1"
[ -f "$image" ] || fail "image path is not a regular file: $image"
[ -r "$image" ] || fail "image is not readable: $image"

case "${XDG_CURRENT_DESKTOP:-}" in
  *KDE*) ;;
  *) fail "run this from an active KDE Plasma session" ;;
esac
[ -f /etc/fedora-release ] || fail "wallpaper sync is supported on Fedora KDE only"

mime_type="$(file --mime-type --brief -- "$image")"
case "$mime_type" in
  image/*) ;;
  *) fail "not a recognized image file: $image ($mime_type)" ;;
esac

for command in plasma-apply-wallpaperimage kwriteconfig6 python3 systemctl cmp; do
  command -v "$command" >/dev/null 2>&1 || fail "required command not found: $command"
done

[ -f /etc/plasmalogin.conf ] || fail "Plasma Login configuration not found: /etc/plasmalogin.conf"
manager="$(systemctl show --property=FragmentPath --value display-manager.service 2>/dev/null || true)"
case "$manager" in
  */plasmalogin.service) ;;
  *) fail "the configured display manager is not Plasma Login: ${manager:-unknown}" ;;
esac

if [ "$EUID" -eq 0 ]; then
  SUDO=()
else
  command -v sudo >/dev/null 2>&1 || fail "sudo is required to configure Plasma Login"
  if [ -t 0 ]; then
    sudo -v || fail "administrator authorization failed"
  else
    sudo -n true || fail "run wallpaper sync from a terminal that can authenticate with sudo"
  fi
  SUDO=(sudo)
fi

root_run() {
  if [ "${#SUDO[@]}" -gt 0 ]; then
    "${SUDO[@]}" "$@"
  else
    "$@"
  fi
}

system_wallpaper_dir=/usr/local/share/wallpapers/dotfiles
system_image="$system_wallpaper_dir/$(basename -- "$image")"
image_url="$(python3 -c 'from urllib.parse import quote; import sys; print("file://" + quote(sys.argv[1], safe="/"))' "$system_image")"

root_run install -d -m 755 -- "$system_wallpaper_dir"
if ! cmp -s -- "$image" "$system_image"; then
  root_run install -m 644 -- "$image" "$system_image"
fi

root_run kwriteconfig6 --file /etc/plasmalogin.conf \
  --group Greeter --key WallpaperPlugin org.kde.image
root_run kwriteconfig6 --file /etc/plasmalogin.conf \
  --group Greeter --group Wallpaper --group org.kde.image --group General \
  --key Image "$image_url"
root_run kwriteconfig6 --file /etc/plasmalogin.conf \
  --group Greeter --group Wallpaper --group org.kde.image --group General \
  --key PreviewImage "$image_url"

plasma-apply-wallpaperimage "$image"
kwriteconfig6 --file kscreenlockerrc \
  --group Greeter --key WallpaperPlugin org.kde.image
kwriteconfig6 --file kscreenlockerrc \
  --group Greeter --group Wallpaper --group org.kde.image --group General \
  --key Image "$image"
kwriteconfig6 --file kscreenlockerrc \
  --group Greeter --group Wallpaper --group org.kde.image --group General \
  --key PreviewImage "$image"

echo "wallpaper  desktop and lock screen = $image"
echo "wallpaper  Plasma Login = $system_image"
echo "hint       lock and login screens use the new image the next time they are shown"
