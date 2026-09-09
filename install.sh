#!/usr/bin/env bash
# Link the configuration in this repo into $HOME.
#
# Idempotent: a rerun leaves correct links alone and repoints wrong ones.
#
# Explicit `link` calls handle one-off paths. `link_dir` covers every top-level
# entry of a repo directory, so a new file in ai/claude/, ai/pi/, or
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
# These files are in the repo but are not linked:
#   config/bspwm              legacy bspwm desktop, superseded by KDE Plasma
#   config/polybar            legacy bspwm desktop
#   config/picom.conf         legacy bspwm desktop
#   bg.jpg                    config/bspwm/reloadablerc reads it by absolute path
#   keychron/*.json           imported through the VIA web app
#   kde_keys.kksrc            imported through KDE System Settings
#   kde6_keys.kksrc           imported through KDE System Settings
#   fedora/dnf.conf           fedora/install.sh copies it with sudo
#   fedora/ly.pp              fedora/install.sh loads it with semodule
#   supernote/*.py            the systemd units run it by absolute path
#   meeting-followups/*.sh    the systemd unit runs it by absolute path
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
WANT_SYSTEMD=0

usage() {
  cat <<'USAGE'
Usage: install.sh [--dry-run] [--systemd]

  --dry-run   Report the changes, write nothing.
  --systemd   Also link the systemd user units. Linux only. Use this on a
              desktop that runs all the time, not on a laptop.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --systemd) WANT_SYSTEMD=1 ;;
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
link_dir "$REPO/ai/pi"       "$HOME/.pi/agent"

# pi reads its instructions from AGENTS.md; share the claude CLAUDE.md.
link "$HOME/.pi/agent/AGENTS.md" "$REPO/ai/claude/CLAUDE.md"

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
