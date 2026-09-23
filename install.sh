#!/usr/bin/env bash
# Link the configuration in this repo into $HOME.
#
# Idempotent: a rerun leaves correct links alone and repoints wrong ones.
#
# Explicit `link` calls handle one-off paths. `link_dir` covers every top-level
# entry of a repo directory, so a new file in ai/claude/, ai/omp/, or
# config/herdr/ gets linked on the next run. Use `link_dir` when the
# destination directory also holds runtime state that must not enter the repo.
#
# Behavior per link path:
#   symlink pointing at the right target  -> left alone
#   symlink pointing elsewhere            -> repointed
#   regular file or directory             -> replaced with a symlink
#   missing                               -> created
#
# The systemd group is Linux only, and you must opt in to it with --systemd.
# Those timers suit a desktop that runs all the time, not a laptop.
#
# --desktop-env sets up the whole desktop on Fedora KDE Plasma:
#   fedora/kde/install.sh   packages, flatpaks, fonts, ghostty, shell, AI tools
#   (the links below)
#   fedora/kde/plasma.sh    Caps Lock as Meta, virtual desktops, shortcuts
#
# These files are in the repo but are not linked:
#   config/bspwm              legacy bspwm desktop, superseded by KDE Plasma
#   config/polybar            legacy bspwm desktop
#   config/picom.conf         legacy bspwm desktop
#   bg.jpg                    config/bspwm/reloadablerc reads it by absolute path
#   keychron/*.json           imported through the VIA web app
#   fedora/dnf.conf           the fedora install scripts copy it with sudo
#   fedora/kde/zen.desktop    fedora/kde/install.sh copies it with sudo
#   fedora/kde/1password-allowed-browsers   same
#   fedora/bspwm/*            legacy bspwm desktop, see fedora/bspwm/install.sh
#   supernote/*.py            the systemd units run it by absolute path
#   meeting-followups/*.sh    the systemd unit runs it by absolute path
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
WANT_SYSTEMD=0
WANT_DESKTOP=0
PERSONAL=0

usage() {
  cat <<'USAGE'
Usage: install.sh [--dry-run] [--systemd] [--desktop-env [--personal]]

  --dry-run      Report the changes, write nothing.
  --systemd      Also link the systemd user units. Linux only. Use this on a
                 desktop that runs all the time, not on a laptop.
  --desktop-env  Also install the programs and apply the desktop settings.
                 Fedora KDE Plasma only.
  --personal     With --desktop-env, also install Discord and Steam.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --systemd) WANT_SYSTEMD=1 ;;
    --desktop-env) WANT_DESKTOP=1 ;;
    --personal) PERSONAL=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "$(uname -s)" in
  Darwin) PLATFORM=mac ;;
  Linux)  PLATFORM=linux ;;
  *)      PLATFORM=other ;;
esac

created=0
fixed=0
ok=0
replaced=0
skipped=0

# Run a command, unless this is a dry run.
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi
  "$@"
}

say() {
  local prefix=""
  if [ "$DRY_RUN" -eq 1 ]; then
    prefix="WOULD "
  fi
  echo "$prefix$1"
}

skip() {
  echo "SKIP     $1  ($2)"
  skipped=$((skipped + 1))
}

# If the directory that holds the new link is itself a symlink into this repo,
# replace it with a real directory. Without this the new link lands inside the
# repo. fedora/install.sh links whole config/* directories in that way.
unnest_parent() {
  local dir="$1" resolved

  [ -L "$dir" ] || return 0

  resolved="$(cd "$dir" 2>/dev/null && pwd -P)" || return 0
  case "$resolved" in
    "$REPO"|"$REPO"/*) ;;
    *) return 0 ;;
  esac

  run rm -f "$dir"
  run mkdir -p "$dir"
  say "UNNESTED $dir  (was a symlink into the repo)"
}

link() {
  local link="$1" target="$2"

  if [ ! -e "$target" ]; then
    skip "$link" "target missing: $target"
    return
  fi

  unnest_parent "$(dirname "$link")"
  run mkdir -p "$(dirname "$link")"

  if [ -L "$link" ]; then
    if [ "$(readlink "$link")" = "$target" ]; then
      echo "OK       $link"
      ok=$((ok + 1))
      return
    fi
    run ln -sfn "$target" "$link"
    say "FIXED    $link -> $target"
    fixed=$((fixed + 1))
    return
  fi

  if [ -e "$link" ]; then
    run rm -rf "$link"
    run ln -s "$target" "$link"
    say "REPLACED $link -> $target"
    replaced=$((replaced + 1))
    return
  fi

  run ln -s "$target" "$link"
  say "CREATED  $link -> $target"
  created=$((created + 1))
}

# Link every top-level entry (file or directory) of src into dest.
link_dir() {
  local src="$1" dest="$2" entry name

  [ -d "$src" ] || { skip "$src" "not a directory"; return; }

  for entry in "$src"/*; do
    [ -e "$entry" ] || continue
    name="$(basename "$entry")"
    link "$dest/$name" "$entry"
  done
}

group() {
  echo
  echo "--- $1 ---"
}

echo "repo=$REPO platform=$PLATFORM"

# --- desktop environment: packages ----------------------------------------
# Runs before the links so that oh-my-zsh exists when the theme is linked.
desktop_supported() {
  [ "$PLATFORM" = linux ] || return 1
  [ -f /etc/fedora-release ] || return 1
  case "${XDG_CURRENT_DESKTOP:-}" in
    *KDE*) return 0 ;;
    *) return 1 ;;
  esac
}

if [ "$WANT_DESKTOP" -eq 1 ]; then
  group "desktop environment: packages"

  if ! desktop_supported; then
    skip "fedora/kde/install.sh" "not a Fedora KDE Plasma session"
  elif [ "$DRY_RUN" -eq 1 ]; then
    say "RUN      fedora/kde/install.sh"
  else
    personal_flag=()
    [ "$PERSONAL" -eq 1 ] && personal_flag=(--personal)
    "$REPO/fedora/kde/install.sh" "${personal_flag[@]}"
  fi
fi

# --- shell ----------------------------------------------------------------
group "shell"
link "$HOME/.zshrc" "$REPO/zshrc"

# oh-my-zsh owns the themes directory. Link the theme only when it is present,
# so the script does not create a stray directory on a machine without it.
if [ -d "$HOME/.oh-my-zsh" ]; then
  link "$HOME/.oh-my-zsh/themes/jlucier.zsh-theme" "$REPO/jlucier.zsh-theme"
else
  skip "$HOME/.oh-my-zsh/themes/jlucier.zsh-theme" "oh-my-zsh is not installed"
fi

# --- ssh ------------------------------------------------------------------
# ~/.ssh/config only includes config.d/*. The personal hosts and keys come from
# ~/ssh_sync (a Syncthing folder) and are linked when that folder is present;
# a work config goes into config.d/ by hand. The synced config refers to keys
# as ~/.ssh/personal/<name>. Syncthing does not keep file modes, so the private
# keys get chmod 600 on every run.
group "ssh"
run mkdir -p -m 700 "$HOME/.ssh/config.d"
link "$HOME/.ssh/config" "$REPO/ssh/config"

if [ -d "$HOME/ssh_sync" ]; then
  link "$HOME/.ssh/config.d/personal" "$HOME/ssh_sync/config"
  link "$HOME/.ssh/personal"          "$HOME/ssh_sync/keys"
  run find "$HOME/ssh_sync/keys" -type f ! -name '*.pub' -exec chmod 600 {} +
else
  skip "$HOME/.ssh/config.d/personal, $HOME/.ssh/personal" "no ~/ssh_sync"
fi

# --- terminals and editor -------------------------------------------------
group "terminals and editor"
link "$HOME/.config/ghostty"   "$REPO/config/ghostty"
link "$HOME/.config/nvim"      "$REPO/config/nvim"
link "$HOME/.config/tmux"      "$REPO/config/tmux"

# --- herdr ----------------------------------------------------------------
group "herdr"
# ~/.config/herdr also holds runtime state (sockets, logs, session.json), so
# link the config file into the directory instead of linking the directory.
link_dir "$REPO/config/herdr" "$HOME/.config/herdr"

# --- AI harnesses ---------------------------------------------------------
group "AI harnesses"
link_dir "$REPO/ai/claude"   "$HOME/.claude"
link_dir "$REPO/ai/opencode" "$HOME/.config/opencode"
link_dir "$REPO/ai/omp"      "$HOME/.omp/agent"

# OMP shares the Claude instructions and appended style without copying them.
link "$HOME/.omp/agent/AGENTS.md" "$REPO/ai/claude/CLAUDE.md"
link "$HOME/.omp/agent/APPEND_SYSTEM.md" "$REPO/ai/claude/output-styles/simplified-technical-english.md"

# --- systemd user units (Linux only, opt in) ------------------------------
group "systemd user units"
if [ "$PLATFORM" != linux ]; then
  skip "supernote-export, meeting-followups units" "systemd, Linux only"
elif [ "$WANT_SYSTEMD" -eq 0 ]; then
  skip "supernote-export, meeting-followups units" "opt in with --systemd"
else
  units="$HOME/.config/systemd/user"

  link "$units/supernote-export.service"  "$REPO/supernote/supernote-export.service"
  link "$units/supernote-export.timer"    "$REPO/supernote/supernote-export.timer"
  link "$units/meeting-followups.service" "$REPO/meeting-followups/meeting-followups.service"
  link "$units/meeting-followups.timer"   "$REPO/meeting-followups/meeting-followups.timer"
fi

# --- desktop environment: settings ----------------------------------------
if [ "$WANT_DESKTOP" -eq 1 ]; then
  group "desktop environment: settings"

  if ! desktop_supported; then
    skip "fedora/kde/plasma.sh" "not a Fedora KDE Plasma session"
  elif [ "$DRY_RUN" -eq 1 ]; then
    say "RUN      fedora/kde/plasma.sh"
  else
    "$REPO/fedora/kde/plasma.sh"
  fi
fi

echo
echo "created=$created fixed=$fixed ok=$ok replaced=$replaced skipped=$skipped"

if [ "$PLATFORM" = linux ] && [ "$WANT_SYSTEMD" -eq 1 ]; then
  cat <<'HINT'

This script only links the systemd units. To activate the timers, run:
  systemctl --user daemon-reload
  systemctl --user enable --now supernote-export.timer
  systemctl --user enable --now meeting-followups.timer
HINT
fi
