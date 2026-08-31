#!/usr/bin/env bash
# Set up symlinks from the harness config directories in $HOME to this repo.
# Idempotent: rerunning leaves correct links alone and repoints wrong ones.
#
# Explicit `link` calls handle one-off paths. `link_dir` covers every
# top-level entry of a repo directory, so dropping a new file into
# ai/claude/ or ai/pi/ gets linked automatically on the next run.
#
# Behavior per link path:
#   symlink pointing at the right target  -> left alone
#   symlink pointing elsewhere            -> repointed
#   regular file or directory             -> replaced with a symlink
#   missing                               -> created
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

created=0
fixed=0
ok=0
replaced=0

link() {
  local link="$1" target="$2"

  if [ ! -e "$target" ]; then
    echo "SKIP     $link  (target missing: $target)"
    return
  fi

  mkdir -p "$(dirname "$link")"

  if [ -L "$link" ]; then
    if [ "$(readlink "$link")" = "$target" ]; then
      echo "OK       $link"
      ok=$((ok + 1))
      return
    fi
    ln -sfn "$target" "$link"
    echo "FIXED    $link -> $target"
    fixed=$((fixed + 1))
    return
  fi

  if [ -e "$link" ]; then
    rm -rf "$link"
    ln -s "$target" "$link"
    echo "REPLACED $link -> $target"
    replaced=$((replaced + 1))
    return
  fi

  ln -s "$target" "$link"
  echo "CREATED  $link -> $target"
  created=$((created + 1))
}

# Link every top-level entry (file or directory) of src into dest.
link_dir() {
  local src="$1" dest="$2" entry name

  [ -d "$src" ] || { echo "SKIP     $src (not a directory)"; return; }

  for entry in "$src"/*; do
    [ -e "$entry" ] || continue
    name="$(basename "$entry")"
    link "$dest/$name" "$entry"
  done
}

# --- claude: everything in ai/claude -> ~/.claude -------------------------
link_dir "$REPO/ai/claude" "$HOME/.claude"

# --- opencode: everything in ai/opencode -> ~/.config/opencode ------------
link_dir "$REPO/ai/opencode" "$HOME/.config/opencode"

# --- pi: everything in ai/pi -> ~/.pi/agent -------------------------------
link_dir "$REPO/ai/pi" "$HOME/.pi/agent"

# --- cross-harness --------------------------------------------------------
# pi reads its instructions from AGENTS.md; share the claude CLAUDE.md.
link "$HOME/.pi/agent/AGENTS.md" "$REPO/ai/claude/CLAUDE.md"

echo
echo "created=$created fixed=$fixed ok=$ok replaced=$replaced"
