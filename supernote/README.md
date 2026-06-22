# supernote-export

Turns handwritten Supernote `.note` files (synced into `~/notes/supernotes` by
Syncthing) into **dark-mode PDFs** placed at the mirrored path inside the
Obsidian vault, so they're viewable on mobile and live alongside the rest of the
vault.

## How it works

`supernotes/` is kept as an exact mirror of the vault layout, so conversion is a
straight prefix swap:

```
~/notes/supernotes/meetings/<subdir>/20240115.note  ->  ~/notes/meetings/<subdir>/20240115.pdf
```

- Decoding/rendering: [`supernotelib`](https://github.com/jya-dev/supernote-tool),
  pinned in the script's PEP 723 header and run via `uv` (no venv to manage).
- Dark mode: pages are rendered to raster, inverted, then tone-mapped so the
  background lands on `SOFT_BG` and ink on `SOFT_INK` — the same effect the
  Obsidian plugin gets from `filter: invert(1)`, baked into the PDF. A palette
  can't do this (the empty page is transparent in the .note, so there's no
  "white" to recolour). Set `DARK_STYLE = "invert"` for the exact plugin look,
  or tune `SOFT_BG`/`SOFT_INK`. Output is raster, not vector: a dark background
  has no vector representation without fragile PDF post-processing, and the
  source is fixed-resolution e-ink handwriting anyway.
- Idempotency: each `.note` is hashed; it's only reconverted when its bytes
  change or its output PDF is missing. State lives in
  `~/.local/state/supernote-export/state.json`.
- Safe writes: PDFs are written to a temp file and atomically renamed.

`supernotes/` was restructured once to mirror the vault exactly, so future
notes filed on the device under the same paths flow straight through. New
folders on the device just appear at the mirrored path under `~/notes`.

## One-time setup

1. **Smoke test** the converter (no writes):
   ```sh
   uv run --script ~/dev/dotfiles/supernote/supernote_export.py --dry-run
   ```
2. **Install the timer** (runs every 10 min):
   ```sh
   ln -s ~/dev/dotfiles/supernote/supernote-export.service ~/.config/systemd/user/
   ln -s ~/dev/dotfiles/supernote/supernote-export.timer   ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now supernote-export.timer
   ```
   Logs: `journalctl --user -u supernote-export.service -f`
   Run now: `systemctl --user start supernote-export.service`

## Manual use

```sh
uv run --script supernote_export.py            # convert changed notes
uv run --script supernote_export.py --force    # reconvert everything
uv run --script supernote_export.py --retry-failed
```

## Later: OCR to markdown

`supernotelib` exposes a `TextConverter` that returns the device's on-device
handwriting recognition (firmware permitting) — the cheap path. For messy
handwriting a vision model does better: render the **original** (non-inverted)
page to PNG and send it for transcription. Either is a separate pass over the
same files; this pipeline already gives you the per-note iteration and
change-tracking to hang it off.
