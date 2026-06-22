# meeting-followups

A daily unattended Claude session (Sonnet 4.6) that reads the last week of
meeting notes, compares them against the Trello-style task board, and queues any
follow-ups that aren't already tracked as cards in a **"Meeting Follow Ups"**
stage.

## How it works

- **Inputs**
  - Task board: `~/notes/trello/tickets/*.md` (one card per file; frontmatter
    `stage / archived / done / completed / created / tags`).
  - Meetings: `~/notes/meetings/**` (`.md` and `.pdf`).
- **Recency** is read from the `YYYYMMDD` prefix in meeting filenames, *not*
  mtime — mtimes here are unreliable (files get bulk-touched by a sync job).
- The agent extracts user-owned action items, drops any already represented by
  a card, and proposes the rest. The comparison set is every card **except**
  those that are *both* archived *and* older than ~2 weeks, so a just-completed
  task won't be re-proposed.
- New cards land in `~/notes/trello/tickets/` with `stage: "Meeting Follow Ups"`
  and a `Source: [[...]]` backlink to the originating meeting. The board groups
  by `stage`, so the new column appears automatically.

Pieces:

- `system-prompt.md` — the agent's instructions (appended to the default Claude
  Code system prompt).
- `reconcile.sh` — wrapper that invokes `claude -p` with the model, prompt,
  `--add-dir ~/notes`, and a tight tool allowlist. `--dry-run` reports without
  writing.
- `meeting-followups.service` / `.timer` — systemd user units, fire daily ~07:00.

The session is scoped by `--add-dir ~/notes` and an `--allowedTools` allowlist
(read tools + `pdftotext`/`find`/`ls`/`stat`, plus `Write`/`Edit` only in live
mode). No permission bypass.

## One-time setup

1. **Auth** must be available to a non-interactive `claude` (logged in via
   `claude` once, or `ANTHROPIC_API_KEY` exported for the user service).
2. **Dry run** — confirm what it would create, write nothing:
   ```sh
   ~/dev/dotfiles/meeting-followups/reconcile.sh --dry-run
   ```
3. **Install the timer:**
   ```sh
   ln -s ~/dev/dotfiles/meeting-followups/meeting-followups.service ~/.config/systemd/user/
   ln -s ~/dev/dotfiles/meeting-followups/meeting-followups.timer   ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now meeting-followups.timer
   ```
   Logs: `journalctl --user -u meeting-followups.service -f`
   Run now: `systemctl --user start meeting-followups.service`

## Manual use

```sh
reconcile.sh --dry-run   # report proposed cards, write nothing
reconcile.sh             # LIVE: create the cards
```
