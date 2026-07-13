# daily-briefing

A weekday unattended Claude session (Opus 4.8, medium effort) that assembles a
"morning brief" and saves it as a note in the Obsidian vault, then fires a
zero-content [ntfy](https://ntfy.sh) push that deep-links straight to the note.

It runs at ~04:00, after the [`meeting-followups`](../meeting-followups) reconciler
(03:30), so it can pick up the follow-up cards that job just created.

## What the brief contains

1. **Today's agenda** (Google Calendar), tailored per event — interviews flagged
   for prep; standups / 1:1s annotated with each *other* attendee's open Jira
   tickets (so you can ask for updates) plus relevant recent meeting/board context.
2. **Near-term priorities** — active cards in the `In Progress` / `P1` /
   `Meeting Follow Ups` stages of the task board (`stage` is the column:
   `In Progress` is in-flight work, then priority `P1` > `P2` > `P3`).
3. **Stale tasks** — cards you keep carrying: `In Progress` or `P1` older than
   7 days, `P2` older than 14 days (`P3` backlog is skipped). For each, it tells
   you to finish, reschedule, or drop it.
4. **Inbox** (Gmail, read-only) — surfaces unarchived items and suggests what to
   do with each (respond / review PR / archive / snooze). It only recommends; it
   never changes your mailbox.
5. **Private sub-skill sections** (optional; see below).
6. A prompt to add anything uncaptured / reprioritize.

The brief is written to `~/notes/briefs/YYYYMMDD - <Weekday>.md`. Briefs from
prior weeks (anything dated before the current week's Monday) are moved to
`~/notes/briefs/archive/` at the start of each run, so the folder only holds
the current week.

## Inputs and access

- **Board**: `~/notes/trello/tickets/*.md` (frontmatter `stage` is authoritative;
  `created` drives the stale rule).
- **Meetings**: `~/notes/meetings/**` (`.md`/`.pdf`; recency from the `YYYYMMDD`
  filename prefix, not mtime).
- **Calendar / Jira / Gmail**: the claude.ai MCP connectors, all **read-only**.
  The brief only *suggests* inbox actions (respond / review / archive / snooze);
  it never modifies Gmail, Jira, or the calendar. The only thing it writes is the
  brief note in `~/notes`.

The session is scoped by `--add-dir ~/notes` and an explicit `--allowedTools`
allowlist; no permission bypass.

## Configuration (not in this repo)

All org-specific values live in an untracked directory outside the repo so
nothing sensitive is committed (override the directory with
`DAILY_BRIEFING_PRIVATE`):

`~/work_sync/dev/daily-briefing/daily-briefing.env`

```sh
JIRA_CLOUD_ID="<atlassian cloud id>"
JIRA_PROJECT="<project key>"
USER_EMAIL="<your work email>"
IGNORED_MEETINGS="<semicolon-separated event titles to skip ticket-scrubbing; optional>"
OBSIDIAN_VAULT="<vault name for the obsidian:// link>"
NTFY_TOPIC="<your private ntfy topic>"
```

Override the env file path alone with `DAILY_BRIEFING_ENV` if you keep it
elsewhere. Subscribe your phone's ntfy app to the same topic to receive the
morning push.

## Private sub-skills (not in this repo)

Extra brief sections whose content is org-specific live in the same private
directory, next to the env file:

`~/work_sync/dev/daily-briefing/sub-skills/<name>/run.sh`

Before the main brief runs, `brief.sh` executes each sub-skill's `run.sh` with
the contract `run.sh <output-report.md> <MODE>`. The script writes a markdown
report (typically its own small `claude -p` with a tight tool allowlist), or
exits nonzero to have its section skipped. The main brief reads the reports and
folds each in as its own section, deduping against recent prior briefs. A
missing private dir is a no-op.

## Pieces

- `system-prompt.md` — the agent's instructions (appended to the default Claude
  Code system prompt). Generic; runtime specifics come from the config via the
  task message.
- `brief.sh` — wrapper: sources config, archives old briefs, runs `claude -p`
  (with a one-shot retry for cold-start connector failures), then pushes ntfy.
  `--dry-run` writes the note but skips the push and ignores the weekday guard.
- `daily-briefing.service` / `.timer` — systemd user units, weekdays ~04:00.

## One-time setup

1. **Auth** — `claude` logged in non-interactively, and the Calendar / Atlassian /
   Gmail claude.ai connectors authenticated (`/mcp`).
2. **Config** — create `~/work_sync/dev/daily-briefing.env` as above.
3. **Dry run** — confirm the brief reads well and makes no Gmail changes:
   ```sh
   ~/dev/dotfiles/daily-briefing/brief.sh --dry-run
   ```
4. **Install the timer:**
   ```sh
   ln -s ~/dev/dotfiles/daily-briefing/daily-briefing.service ~/.config/systemd/user/
   ln -s ~/dev/dotfiles/daily-briefing/daily-briefing.timer   ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now daily-briefing.timer
   ```
   Logs: `journalctl --user -u daily-briefing.service -f`
   Run now: `systemctl --user start daily-briefing.service`

## Manual use

```sh
brief.sh --dry-run   # write the note; no push
brief.sh             # LIVE: write the note, then ntfy push
```
