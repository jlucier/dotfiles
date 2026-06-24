#!/usr/bin/env bash
# Custom Claude Code status line: model · dir (branch±) · context%
# stdin receives the session JSON payload documented at
# https://code.claude.com/docs/en/statusline
#
# Install on a new machine (this file lives in ~/dev/dotfiles/claude/):
#   ln -s ~/dev/dotfiles/claude/statusline.sh ~/.claude/statusline.sh
#   then add to ~/.claude/settings.json:
#     "statusLine": { "type": "command", "command": "~/.claude/statusline.sh", "padding": 0 }
# Requires: jq, git.

input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // .model.id // "?"')

cur_dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
proj_dir=$(printf '%s' "$input" | jq -r '.workspace.project_dir // empty')

# Context window: prefer the precomputed used_percentage; fall back to summing
# the current_usage token buckets against the window size.
ctx_pct=$(printf '%s' "$input" | jq -r '
  .context_window as $c
  | if ($c.used_percentage != null) then ($c.used_percentage | floor)
    elif ($c.context_window_size // 0) > 0 then
      ((((($c.current_usage.input_tokens // 0)
         + ($c.current_usage.cache_read_input_tokens // 0)
         + ($c.current_usage.cache_creation_input_tokens // 0))
        / $c.context_window_size) * 100) | floor)
    else empty end')

# ANSI colors
dim=$'\033[2m'; reset=$'\033[0m'
cyan=$'\033[36m'; blue=$'\033[34m'; magenta=$'\033[35m'
sep=" ${dim}·${reset} "

out="${cyan}${model}${reset}"

# Working directory: show path relative to the project root, else the basename.
if [ -n "$cur_dir" ]; then
  label="$cur_dir"
  if [ -n "$proj_dir" ] && [ "$cur_dir" = "$proj_dir" ]; then
    label=$(basename "$cur_dir")
  elif [ -n "$proj_dir" ] && [ "${cur_dir#"$proj_dir"/}" != "$cur_dir" ]; then
    label="$(basename "$proj_dir")/${cur_dir#"$proj_dir"/}"
  else
    label=$(basename "$cur_dir")
  fi
  out="${out}${sep}${blue}${label}${reset}"

  # Git branch + dirty marker.
  branch=$(git -C "$cur_dir" symbolic-ref --quiet --short HEAD 2>/dev/null \
           || git -C "$cur_dir" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    dirty=""
    git -C "$cur_dir" diff --quiet --ignore-submodules HEAD 2>/dev/null || dirty="±"
    out="${out} ${magenta}${branch}${dirty}${reset}"
  fi
fi

if [ -n "$ctx_pct" ]; then
  if   [ "$ctx_pct" -ge 80 ]; then ctx_color=$'\033[31m'   # red
  elif [ "$ctx_pct" -ge 50 ]; then ctx_color=$'\033[33m'   # yellow
  else ctx_color=$'\033[32m'; fi                            # green
  out="${out}${sep}${ctx_color}${ctx_pct}%${reset}${dim} ctx${reset}"
fi

printf '%b' "$out"
