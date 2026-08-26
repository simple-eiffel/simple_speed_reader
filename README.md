<p align="center">
  <img src="docs/images/logo.svg" alt="simple_speed_reader logo" width="160">
</p>

<h1 align="center">simple_speed_reader</h1>

<p align="center">
  <a href="https://simple-eiffel.github.io/simple_speed_reader/">Documentation</a> •
  <a href="https://github.com/simple-eiffel/simple_speed_reader">GitHub</a> •
  <a href="docs/USER_GUIDE.md">User Guide</a> •
  <a href=".eiffel-workflow/DESIGN_STORY.md">Design Story</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT">
  <img src="https://img.shields.io/badge/Eiffel-25.02-purple.svg" alt="Eiffel 25.02">
  <img src="https://img.shields.io/badge/DBC-Contracts-green.svg" alt="Design by Contract">
  <img src="https://img.shields.io/badge/Platform-Windows%20x64-lightgrey.svg" alt="Windows x64">
  <img src="https://img.shields.io/badge/Status-In%20Design-orange.svg" alt="Status: In Design">
</p>

**Read fast without lying to yourself.** An RSVP speed reader (one word at a
time, red pivot letter, dark screen, ramping to 900 WPM) built around the two
things every other word-streamer lacks: a one-key **recovery loop** for the
moment your mind wanders, and a local-AI **comprehension quiz** written from
your text *before* you read it. Part of the
[Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

🚀 **v0.9.0 — feature-complete, installer built, in final hand-test (2026-08-26,
the same day the idea arrived).** Engine **35/35 F_code tests**; simple_widgets
suite 198/198 (this project grew the toolkit: give_focus, handle_release,
drive chips, typed paths). Built and working: three postures + the analog
**braking pedal** (hold the stage: glide to 300 with the live fisheye ribbon;
drag to scrub; release to ease home), recovery loop, fisheye ribbon, Speed
drawer, scholarly timing with foreign-script skip, **local-AI comprehension
quiz** (worker process, quote-verified against your text — live-tested on a
local Qwen3), SQLite reading ledger + Continue-where-you-left-off, UTF-8-clean
intake, `SimpleSpeedReader-0.9.0-Setup.exe` (7 MB, per-user, ledger-preserving
uninstall). Awaiting Larry's approval to tag 1.0.

```
/d/prod/ec.sh test -config simple_speed_reader.ecf -target simple_speed_reader_tests
./EIFGENs/simple_speed_reader_tests/F_code/simple_speed_reader.exe    # 35/35
/d/prod/ec.sh test -config simple_speed_reader.ecf -target speed_reader
/d/prod/ec.sh test -config simple_speed_reader.ecf -target speed_reader_worker
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\simple_speed_reader.iss
```

## The idea

Reading science has two objections to RSVP speed reading: it eliminates
regressions (re-reading repairs comprehension — Schotter, Tran & Rayner 2014),
and it never verifies that anything was understood. simple_speed_reader is
RSVP with both objections engineered out:

- **Recovery loop** — Space stops the stream instantly and shows the
  surrounding paragraphs as readable text. Click the word where you were last
  solid; the stream resumes *there*, at ~250 WPM, re-ramping toward your
  comfy-max. Getting lost costs seconds, not the chapter.
- **Quiz before reading** — a local model (Ollama, on your GPU, nothing
  leaves the machine) writes a quote-anchored quiz from your text at load
  time. Preview the questions first (the SQ3R move), take it after, and the
  score joins your log next to *dialed* WPM and *actually achieved* WPM.

## Designed features (planned — not yet built)

- Video-parity dark stage: fixed ORP pivot, tick marks, live WPM readout; settable font
- Three postures: **running** (stream only + one dim pause affordance),
  **paused** (context page + drawered controls), **stopped** (full cockpit)
- Speed governance: ramp to comfy-max (default 900), hold-at-current, back-off −100/−50/−25
- Media-player transport keys: Space/K, Esc/S, Left/Right sentence seeks,
  in-flow micro-rewind, Up/Down speed
- Whole-text flow map with live word cursor; scrubber when paused
- Scholar-grade timing: Hebrew/Greek script detection (linger + no fake pivot),
  transliteration and acronym linger, numerals, optional foreign-script skip
- Local-AI text preprocessor for OCR-grade sources; honest speed + comprehension log (SQLite)
- Drill mode with AI-generated graded practice texts

## Planned stack

[simple_widgets](https://github.com/simple-eiffel/simple_widgets) (drawn GUI) ·
simple_shell · simple_cairo · simple_ai_client (Ollama) · simple_sql ·
simple_config · simple_file · simple_hash · simple_diff — SCOOP-compatible,
void-safe, contracts everywhere.

## License

MIT — see [LICENSE](LICENSE).
