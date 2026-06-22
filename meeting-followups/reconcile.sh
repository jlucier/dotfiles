#!/usr/bin/env bash
# Reconcile recent meeting notes against the Trello-style task board and queue
# any uncovered follow-ups as cards in the "Meeting Follow Ups" stage.
#
# Usage:
#   reconcile.sh              # LIVE: create cards, print what it made
#   reconcile.sh --dry-run    # report proposed cards, write nothing
#
# Invoked unattended by meeting-followups.timer. Scoped to ~/notes; the tool
# allowlist below is the only surface the session can touch.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
NOTES="$HOME/notes"
MODEL="claude-sonnet-4-6"
SYSTEM_PROMPT_FILE="$HERE/system-prompt.md"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

TODAY="$(date +%Y-%m-%d)"

# Read tools + the exact Bash commands the agent needs (PDF text extraction and
# date-aware file listing). No blanket Bash, no permission bypass.
ALLOWED_TOOLS="Read Glob Grep Bash(pdftotext:*) Bash(find:*) Bash(ls:*) Bash(stat:*)"

if [[ "$DRY_RUN" == 1 ]]; then
  MODE_PROMPT="Run in DRY-RUN mode. Today is ${TODAY}. Analyse the last 7 days of \
meetings against the task board and report the follow-up cards you WOULD create. \
Write nothing."
  # Belt and suspenders: read-only, and Write/Edit physically disallowed.
  EXTRA_ARGS=(--disallowedTools "Write" "Edit")
else
  MODE_PROMPT="Run in LIVE mode. Today is ${TODAY}. Create the uncovered follow-up \
cards in ~/notes/trello/tickets/ as specified, then print a summary of what you created."
  ALLOWED_TOOLS="$ALLOWED_TOOLS Write Edit"
  EXTRA_ARGS=(--permission-mode acceptEdits)
fi

exec "$CLAUDE" -p "$MODE_PROMPT" \
  --model "$MODEL" \
  --append-system-prompt "$(cat "$SYSTEM_PROMPT_FILE")" \
  --add-dir "$NOTES" \
  --allowedTools $ALLOWED_TOOLS \
  "${EXTRA_ARGS[@]}"
