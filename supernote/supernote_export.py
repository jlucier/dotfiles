#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12,<3.14"
# dependencies = [
#     "supernotelib==0.7.1",
# ]
# ///
"""Convert Supernote .note files (synced into notes/supernotes) into dark-mode
PDFs placed at the mirrored path inside the Obsidian vault.

supernotes/ is kept as an exact mirror of the vault layout, so the mapping is a
straight prefix swap: notes/supernotes/<rel>/x.note -> notes/<rel>/x.pdf.

State is tracked by content hash in an XDG state file, so a .note is only
reconverted when its bytes change (or its output PDF goes missing). Run on a
timer; see supernote-export.timer.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import traceback
from pathlib import Path

import supernotelib as sn
from supernotelib.converter import ImageConverter
from PIL import Image, ImageOps

# --- configuration -----------------------------------------------------------

HOME = Path.home()
SRC_ROOT = HOME / "notes" / "supernotes"
DST_ROOT = HOME / "notes"

STATE_PATH = Path(
    os.environ.get("XDG_STATE_HOME", HOME / ".local" / "state")
) / "supernote-export" / "state.json"

# Dark mode is done by transforming rendered pixels (not a palette): render the
# page, invert it (white page -> dark, dark ink -> light), then for "soft" tone
# the result so the background lands on SOFT_BG and the ink on SOFT_INK instead
# of pure black/white. A palette can't do this -- the empty page is transparent
# in the .note, so there's no "white" to recolor; only the rendered pixels carry
# the background. This is the same effect the Obsidian plugin gets from
# filter: invert(1), baked into the PDF.
DARK_STYLE = "soft"         # "soft" (tuned) or "invert" (exact plugin look)
SOFT_BG = 0x1E              # page background level for soft style
SOFT_INK = 0xDC             # ink level for soft style

PDF_DPI = 200               # nominal page size; visual quality is unaffected
LOAD_POLICY = "loose"       # tolerate firmware quirks
QUIET_SECONDS = 30          # skip files modified within this window (mid-sync)

# Syncthing scratch / OS cruft we never want to touch.
IGNORE_DIR_NAMES = {".stfolder", ".stversions"}
IGNORE_FILE_PREFIXES = ("~syncthing~", ".syncthing.")


# --- helpers -----------------------------------------------------------------

def soft_lut() -> list[int]:
    # Linear map of [0,255] -> [SOFT_BG, SOFT_INK], applied after inversion so
    # the (now-dark) background lands on SOFT_BG and the (now-light) ink on
    # SOFT_INK. Tripled because point() wants one entry per channel value.
    span = SOFT_INK - SOFT_BG
    return [round(SOFT_BG + v * span / 255) for v in range(256)] * 3


def darken(img: Image.Image, lut: list[int]) -> Image.Image:
    inverted = ImageOps.invert(img.convert("RGB"))
    return inverted.point(lut) if DARK_STYLE == "soft" else inverted


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def load_state(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return {}
    except json.JSONDecodeError:
        print(f"warning: state file {path} is corrupt; starting fresh", file=sys.stderr)
        return {}


def save_state(path: Path, state: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(state, indent=2, sort_keys=True))
    tmp.replace(path)


def is_ignored(note: Path) -> bool:
    if note.name.startswith(IGNORE_FILE_PREFIXES):
        return True
    return any(part in IGNORE_DIR_NAMES for part in note.parts)


def find_notes(src_root: Path) -> list[Path]:
    return sorted(p for p in src_root.rglob("*.note") if not is_ignored(p))


def output_for(note: Path, src_root: Path, dst_root: Path) -> Path:
    rel = note.relative_to(src_root)
    return (dst_root / rel).with_suffix(".pdf")


def convert_note(note: Path, out: Path, lut: list[int]) -> int:
    notebook = sn.load_notebook(str(note), policy=LOAD_POLICY)
    converter = ImageConverter(notebook)
    pages = notebook.get_total_pages()

    images = [darken(converter.convert(i), lut) for i in range(pages)]
    if not images:
        raise RuntimeError("note has no pages")

    out.parent.mkdir(parents=True, exist_ok=True)
    tmp = out.with_suffix(out.suffix + ".tmp")
    images[0].save(tmp, "PDF", save_all=True, append_images=images[1:],
                   resolution=PDF_DPI)
    tmp.replace(out)  # atomic: Obsidian/Syncthing never see a partial PDF
    return pages


# --- main --------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--src", type=Path, default=SRC_ROOT)
    ap.add_argument("--dst", type=Path, default=DST_ROOT)
    ap.add_argument("--state", type=Path, default=STATE_PATH)
    ap.add_argument("--force", action="store_true",
                    help="reconvert every note regardless of state")
    ap.add_argument("--retry-failed", action="store_true",
                    help="retry notes previously recorded as failed")
    ap.add_argument("--dry-run", action="store_true",
                    help="report what would be converted, change nothing")
    args = ap.parse_args()

    if not args.src.is_dir():
        print(f"error: source {args.src} not found", file=sys.stderr)
        return 1

    lut = soft_lut()
    state = load_state(args.state)
    now = time.time()

    notes = find_notes(args.src)
    converted = skipped = failed = 0

    for note in notes:
        rel = str(note.relative_to(args.src))
        out = output_for(note, args.src, args.dst)

        # Skip files Syncthing may still be writing.
        if now - note.stat().st_mtime < QUIET_SECONDS:
            print(f"skip (just modified): {rel}")
            skipped += 1
            continue

        digest = sha256_of(note)
        prior = state.get(rel)

        if not args.force and prior and prior.get("hash") == digest:
            if prior.get("status") == "ok" and out.exists():
                skipped += 1
                continue
            if prior.get("status") == "failed" and not args.retry_failed:
                skipped += 1
                continue

        if args.dry_run:
            print(f"would convert: {rel} -> {out.relative_to(args.dst)}")
            converted += 1
            continue

        try:
            pages = convert_note(note, out, lut)
            state[rel] = {"hash": digest, "status": "ok", "pages": pages,
                          "output": str(out)}
            converted += 1
            print(f"ok: {rel} -> {out.relative_to(args.dst)} ({pages}p)")
        except Exception as exc:  # noqa: BLE001 - one bad note shouldn't stop the batch
            state[rel] = {"hash": digest, "status": "failed", "error": str(exc)}
            failed += 1
            print(f"FAILED: {rel}: {exc}", file=sys.stderr)
            traceback.print_exc()

    if not args.dry_run:
        save_state(args.state, state)

    print(f"done: {converted} converted, {skipped} skipped, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
