#!/usr/bin/env bash
# Build the morning brief: read calendar / board / Jira / inbox, synthesise a
# prioritised note into the Obsidian vault, then fire a zero-content ntfy push
# that deep-links to the note.
#
# Usage:
#   brief.sh              # LIVE: write the brief, snooze inbox items, push ntfy
#   brief.sh --dry-run    # read + write the note only; NO Gmail writes, NO push
#                         #   (also bypasses the weekday guard so you can test)
#
# Invoked unattended by daily-briefing.timer, weekdays ~04:00 (after the
# meeting-followups reconciler at 03:30). Org-specific values come from an untracked
# config file outside this repo (see CONFIG below); nothing sensitive lives here.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
NOTES="$HOME/notes"
BRIEFS="$NOTES/briefs"
MODEL="claude-opus-4-8"
EFFORT="medium"
SYSTEM_PROMPT_FILE="$HERE/system-prompt.md"

# Everything org-specific (config + sub-skills) is colocated in one untracked
# directory outside this repo.
PRIVATE_DIR="${DAILY_BRIEFING_PRIVATE:-$HOME/work_sync/dev/daily-briefing}"
CONFIG="${DAILY_BRIEFING_ENV:-$PRIVATE_DIR/daily-briefing.env}"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

# DRY-RUN vs LIVE only changes whether the wrapper fires the ntfy push (below)
# and the weekday guard; the agents' behaviour is identical either way.
MODE="$([[ "$DRY_RUN" == 1 ]] && echo DRY-RUN || echo LIVE)"

# --- config -----------------------------------------------------------------
if [[ ! -f "$CONFIG" ]]; then
  echo "config not found: $CONFIG (see README)" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$CONFIG"
: "${JIRA_CLOUD_ID:?}" "${JIRA_PROJECT:?}" "${USER_EMAIL:?}"
: "${OBSIDIAN_VAULT:?}" "${NTFY_TOPIC:?}"
IGNORED_MEETINGS="${IGNORED_MEETINGS:-}"   # optional; semicolon-separated

# --- weekday guard ----------------------------------------------------------
# Mon..Fri only. Persistent=true can fire a missed run on a weekend; skip it.
# Dry runs are allowed any day for testing.
if [[ "$DRY_RUN" == 0 && "$(date +%u)" -ge 6 ]]; then
  echo "weekend ($(date +%A)); skipping live brief." >&2
  exit 0
fi

TODAY="$(date +%Y-%m-%d)"
WEEKDAY="$(date +%A)"
PREFIX="$(date +%Y%m%d)"
NOTE_REL="briefs/${PREFIX} - ${WEEKDAY}"
NOTE_PATH="$NOTES/${NOTE_REL}.md"

# --- archive briefs from prior weeks -----------------------------------------
# Anything dated before this week's Monday moves to archive/, so the Monday run
# sweeps the whole previous week and the folder only ever holds the current week.
mkdir -p "$BRIEFS/archive"
WEEK_START="$(date -d "-$(( $(date +%u) - 1 )) days" +%Y%m%d)"
shopt -s nullglob
for f in "$BRIEFS"/*.md; do
  base="$(basename "$f")"
  d="${base:0:8}"
  [[ "$d" =~ ^[0-9]{8}$ ]] || continue
  if [[ "$d" -lt "$WEEK_START" ]]; then
    mv -- "$f" "$BRIEFS/archive/"
    echo "archived prior-week brief: $base" >&2
  fi
done
shopt -u nullglob

# --- private sub-skills (in PRIVATE_DIR, next to the env file) ---------------
# Optional extra brief sections. Each sub-skill is a directory holding an
# executable run.sh with the contract:
#   run.sh <output-report.md> <MODE>
# It writes a markdown report for the main brief to fold in, or exits nonzero
# (the section is skipped, never the whole brief). No sub-skills = no-op.
SNIPPET_DIR="$(mktemp -d)"
trap 'rm -rf "$SNIPPET_DIR"' EXIT
SNIPPETS=()
shopt -s nullglob
for run in "$PRIVATE_DIR"/sub-skills/*/run.sh; do
  name="$(basename "$(dirname "$run")")"
  out="$SNIPPET_DIR/${name}.md"
  echo "sub-skill ${name}: running..." >&2
  if "$run" "$out" "$MODE" && [[ -s "$out" ]]; then
    SNIPPETS+=("$out")
  else
    echo "sub-skill ${name} failed; skipping its section" >&2
  fi
done
shopt -u nullglob

# --- assemble the run -------------------------------------------------------
if [[ -n "$IGNORED_MEETINGS" ]]; then
  IGNORE_CLAUSE="Skip per-attendee ticket scrubbing for any calendar event whose \
title matches one of these ignored meetings: ${IGNORED_MEETINGS//;/, }."
else
  IGNORE_CLAUSE="No ignored meetings are configured; scrub attendees for all \
relevant standups/1:1s."
fi

SNIPPET_CLAUSE=""
EXTRA_DIRS=()
if (( ${#SNIPPETS[@]} )); then
  SNIPPET_CLAUSE=" Sub-skill reports to fold in (read each): ${SNIPPETS[*]}."
  EXTRA_DIRS=(--add-dir "$SNIPPET_DIR")
fi

COMMON_FACTS="Today is ${WEEKDAY}, ${TODAY}. Jira cloudId: ${JIRA_CLOUD_ID}. \
Jira project key: ${JIRA_PROJECT}. Your work email: ${USER_EMAIL}. \
${IGNORE_CLAUSE}${SNIPPET_CLAUSE} Write the brief to: ${NOTE_PATH}"

# Read tools, the board/meeting helpers, file writing for the note, and the
# read-only Calendar / Jira / Gmail tools. The agent never mutates Gmail — it
# only suggests inbox actions — so no Gmail write tools are allowlisted.
ALLOWED_TOOLS="Read Glob Grep Write Edit \
Bash(pdftotext:*) Bash(find:*) Bash(ls:*) Bash(stat:*) Bash(date:*) \
mcp__claude_ai_Google_Calendar__list_events \
mcp__claude_ai_Google_Calendar__get_event \
mcp__claude_ai_Google_Calendar__list_calendars \
mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql \
mcp__claude_ai_Atlassian__lookupJiraAccountId \
mcp__claude_ai_Atlassian__getJiraIssue \
mcp__claude_ai_Gmail__search_threads \
mcp__claude_ai_Gmail__get_thread \
mcp__claude_ai_Gmail__list_labels"

MODE_PROMPT="Run in ${MODE} mode. ${COMMON_FACTS}"

run_claude() {
  "$CLAUDE" -p "$MODE_PROMPT" \
    --model "$MODEL" \
    --effort "$EFFORT" \
    --append-system-prompt "$(cat "$SYSTEM_PROMPT_FILE")" \
    --add-dir "$NOTES" \
    "${EXTRA_DIRS[@]}" \
    --allowedTools $ALLOWED_TOOLS \
    --permission-mode acceptEdits
}

# One retry to ride out a cold-start connector failure.
if ! run_claude; then
  echo "brief run failed; retrying once after 20s..." >&2
  sleep 20
  run_claude
fi

# --- notify (LIVE only): zero-content push that deep-links to the note ------
if [[ "$DRY_RUN" == 0 ]]; then
  # URL-encode the note path for the obsidian:// link: spaces -> %20 and the
  # path separator -> %2F (Obsidian requires reserved chars encoded, esp. mobile).
  enc_file="${NOTE_REL// /%20}"
  enc_file="${enc_file//\//%2F}"
  deeplink="obsidian://open?vault=${OBSIDIAN_VAULT}&file=${enc_file}"
  curl -fsS \
    -H "Title: 🗞️ Morning brief ready" \
    -H "Tags: newspaper" \
    -H "Click: ${deeplink}" \
    -d "Tap to open today's brief in Obsidian." \
    "https://ntfy.sh/${NTFY_TOPIC}" >/dev/null \
    || echo "ntfy push failed (brief was still written)" >&2
fi
