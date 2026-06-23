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
# Invoked unattended by daily-briefing.timer, weekdays ~07:30 (after the
# meeting-followups reconciler). Org-specific values come from an untracked
# config file outside this repo (see CONFIG below); nothing sensitive lives here.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
NOTES="$HOME/notes"
BRIEFS="$NOTES/briefs"
MODEL="claude-opus-4-8"
EFFORT="medium"
SYSTEM_PROMPT_FILE="$HERE/system-prompt.md"
CONFIG="${DAILY_BRIEFING_ENV:-$HOME/work_sync/dev/daily-briefing.env}"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

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

# --- archive briefs older than 7 days ---------------------------------------
mkdir -p "$BRIEFS/archive"
CUTOFF="$(date -d '7 days ago' +%Y%m%d)"
shopt -s nullglob
for f in "$BRIEFS"/*.md; do
  base="$(basename "$f")"
  d="${base:0:8}"
  [[ "$d" =~ ^[0-9]{8}$ ]] || continue
  if [[ "$d" -lt "$CUTOFF" ]]; then
    mv -- "$f" "$BRIEFS/archive/"
    echo "archived old brief: $base" >&2
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

COMMON_FACTS="Today is ${WEEKDAY}, ${TODAY}. Jira cloudId: ${JIRA_CLOUD_ID}. \
Jira project key: ${JIRA_PROJECT}. Your work email: ${USER_EMAIL}. \
${IGNORE_CLAUSE} Write the brief to: ${NOTE_PATH}"

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

# DRY-RUN vs LIVE only changes whether the wrapper fires the ntfy push (below)
# and the weekday guard; the agent's behaviour is identical either way.
MODE="$([[ "$DRY_RUN" == 1 ]] && echo DRY-RUN || echo LIVE)"
MODE_PROMPT="Run in ${MODE} mode. ${COMMON_FACTS}"

run_claude() {
  "$CLAUDE" -p "$MODE_PROMPT" \
    --model "$MODEL" \
    --effort "$EFFORT" \
    --append-system-prompt "$(cat "$SYSTEM_PROMPT_FILE")" \
    --add-dir "$NOTES" \
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
