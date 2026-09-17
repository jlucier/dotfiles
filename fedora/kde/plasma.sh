#!/usr/bin/env bash
# Apply the KDE Plasma settings: Caps Lock as Meta, five virtual desktops, and
# the global shortcuts.
#
# Idempotent: every write sets the same value on a rerun. Nothing in the repo
# is linked into ~/.config for these files, because Plasma writes other keys
# into the same files at runtime.
#
# KWin shortcuts go through the kglobalaccel D-Bus API, the same path the
# System Settings module uses. The daemon keeps its own copy of every
# registered component and writes that copy back to kglobalshortcutsrc at
# session start and end, so a direct edit of the [kwin] group is lost at the
# next login. The daemon applies the D-Bus call live and saves it itself.
#
# Application launch shortcuts live in [services][app.desktop] _launch and are
# not a registered component, so a direct file write works for them. A tab
# separates alternative keys inside one value.
set -euo pipefail

SHORTCUTS=kglobalshortcutsrc
TAB=$'\t'

# Qt key codes and modifier bits, from qnamespace.h.
declare -A QT_KEY=(
  [Meta]=$((0x10000000)) [Ctrl]=$((0x04000000)) [Alt]=$((0x08000000)) [Shift]=$((0x02000000))
  [Space]=$((0x20)) [Return]=$((0x01000004)) [Esc]=$((0x01000000))
  [Left]=$((0x01000012)) [Up]=$((0x01000013)) [Right]=$((0x01000014)) [Down]=$((0x01000015))
  [PgUp]=$((0x01000016)) [PgDown]=$((0x01000017))
  [F1]=$((0x01000030)) [F2]=$((0x01000031)) [F3]=$((0x01000032)) [F4]=$((0x01000033))
  ['!']=$((0x21)) ['@']=$((0x40)) ['#']=$((0x23)) ['$']=$((0x24)) ['%']=$((0x25))
)

# Encode one key combination such as "Meta+Shift+Q" as a Qt key code.
# Letters and digits use their ASCII code. Meta+Shift+1 is written "Meta+!",
# as KDE does, because the daemon matches the shifted symbol.
qt_code() {
  local combo="$1" part code=0

  IFS=+ read -ra parts <<<"$combo"
  for part in "${parts[@]}"; do
    if [ -n "${QT_KEY[$part]+x}" ]; then
      code=$((code | QT_KEY[$part]))
    elif [ "${#part}" -eq 1 ]; then
      code=$((code | $(printf '%d' "'${part^^}")))
    else
      echo "unknown key: $part in $combo" >&2
      return 1
    fi
  done

  echo "$code"
}

# Set the keys of a kwin action through the daemon. Alternatives are
# separated by a tab. Flag 4 is NoAutoloading: apply even if a stored value
# exists.
kwin_key() {
  local action="$1" keys="$2" combo seqs=()

  IFS="$TAB" read -ra combos <<<"$keys"
  for combo in "${combos[@]}"; do
    seqs+=("([$(qt_code "$combo"),0,0,0],)")
  done

  gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method org.kde.KGlobalAccel.setShortcutKeys \
    "['kwin','$action','','']" "[$(IFS=,; echo "${seqs[*]}")]" 4 >/dev/null
  echo "kwin     $action = $keys"
}

# Set the launch keys of an application.
launch_key() {
  local desktop="$1" keys="$2"

  kwriteconfig6 --file "$SHORTCUTS" --group services --group "$desktop" --key _launch "$keys"
  echo "launch   $desktop = $keys"
}

# --- keyboard -------------------------------------------------------------
echo "--- keyboard ---"

# Caps Lock acts as a second Meta (Super) key.
kwriteconfig6 --file kxkbrc --group Layout --key Options caps:super
kwriteconfig6 --file kxkbrc --group Layout --key ResetOldOptions true
echo "kxkbrc   Options = caps:super"

# --- virtual desktops -----------------------------------------------------
echo
echo "--- virtual desktops ---"

kwriteconfig6 --file kwinrc --group Desktops --key Number 5
kwriteconfig6 --file kwinrc --group Desktops --key Rows 1
echo "kwinrc   Desktops = 5 in 1 row"

# Switch desktops with no slide animation.
kwriteconfig6 --file kwinrc --group Plugins --key slideEnabled --type bool false
echo "kwinrc   slide effect = off"

# --- kwin shortcuts -------------------------------------------------------
echo
echo "--- kwin shortcuts ---"

# Meta+N switches to desktop N. Meta+Shift+N moves the window there.
kwin_key "Switch to Desktop 1" "Meta+1"
kwin_key "Switch to Desktop 2" "Meta+2"
kwin_key "Switch to Desktop 3" "Meta+3"
kwin_key "Switch to Desktop 4" "Meta+4"
kwin_key "Switch to Desktop 5" "Meta+5"
kwin_key "Window to Desktop 1" 'Meta+!'
kwin_key "Window to Desktop 2" 'Meta+@'
kwin_key "Window to Desktop 3" 'Meta+#'
kwin_key "Window to Desktop 4" 'Meta+$'
kwin_key "Window to Desktop 5" 'Meta+%'
kwin_key "Switch One Desktop to the Left"  "Meta+Ctrl+Left"
kwin_key "Switch One Desktop to the Right" "Meta+Ctrl+Right"

kwin_key "Window Close"    "Meta+Shift+Q${TAB}Alt+F4"
kwin_key "Window Maximize" "Meta+F${TAB}Meta+PgUp"
kwin_key "Window Minimize" "Meta+M${TAB}Meta+PgDown"

# Quick tile is the Plasma default. Set it anyway so a default change upstream
# does not remove it.
kwin_key "Window Quick Tile Left"   "Meta+Left"
kwin_key "Window Quick Tile Right"  "Meta+Right"
kwin_key "Window Quick Tile Top"    "Meta+Up"
kwin_key "Window Quick Tile Bottom" "Meta+Down"

# --- application shortcuts ------------------------------------------------
echo
echo "--- application shortcuts ---"

launch_key com.mitchellh.ghostty.desktop "Meta+Return"
launch_key zen.desktop                   "Meta+Shift+Return"
launch_key org.kde.krunner.desktop       "Meta+Space${TAB}Alt+Space${TAB}Alt+F2${TAB}Search"

# --- default browser ------------------------------------------------------
echo
echo "--- default browser ---"

# xdg-settings writes ~/.config/mimeapps.list, which Plasma reads.
if [ "$(xdg-settings get default-web-browser)" = zen.desktop ]; then
  echo "OK       default browser is Zen"
else
  xdg-settings set default-web-browser zen.desktop
  echo "browser  default = Zen"
fi

# --- reload ---------------------------------------------------------------
echo
echo "--- reload ---"

# The kwin shortcuts are already live. The keyboard layout and the desktop
# count reload here. The launch shortcuts load at the next login.
dbus-send --session --type=signal /Layouts org.kde.keyboard.reloadConfig
gdbus call --session --dest org.kde.KWin --object-path /KWin --method org.kde.KWin.reconfigure >/dev/null

cat <<'HINT'
Log out and in to load the application launch shortcuts.
HINT
