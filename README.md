<p align="center">
  <img src="docs/images/logo.svg" alt="simple_speed_reader logo" width="180">
</p>

<h1 align="center">simple_speed_reader</h1>

<p align="center">
  <a href="https://simple-eiffel.github.io/simple_speed_reader/">Documentation</a> •
  <a href="https://github.com/simple-eiffel/simple_speed_reader">GitHub</a> •
  <a href="docs/USER_GUIDE.md">User Guide</a> •
  <a href="#watch-it-run">Demos</a> •
  <a href="docs/THE_NIGHT_BUILD.md">The Night Build</a> •
  <a href=".eiffel-workflow/DESIGN_STORY.md">Design Story</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT">
  <img src="https://img.shields.io/badge/Eiffel-25.02-purple.svg" alt="Eiffel 25.02">
  <img src="https://img.shields.io/badge/DBC-Contracts-green.svg" alt="Design by Contract">
  <img src="https://img.shields.io/badge/tests-51%2F51-brightgreen.svg" alt="Tests 51/51">
  <img src="https://img.shields.io/badge/Windows-tests%20pass-0078D6?logo=windows&logoColor=white" alt="Windows: tests pass">
  <img src="https://img.shields.io/badge/Linux-tests%20pass-FCC624?logo=linux&logoColor=black" alt="Linux: tests pass">
  <img src="https://img.shields.io/badge/macOS-tests%20pass-000000?logo=apple&logoColor=white" alt="macOS: tests pass">
</p>

**Read fast without lying to yourself.** An RSVP speed reader — one word at a
time, the red pivot letter pinned at center, dark screen, ramping toward 900
WPM — built around the two things every other word-streamer lacks: a one-key
**recovery loop** for the moment your mind wanders (the regression that
reading science says comprehension needs), and a **local-AI comprehension
quiz** written from your text *before* you read it, every question verified
verbatim against the source. Part of the
[Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Watch it run

Two unscripted one-take recordings of the installed application — no narration,
no edits, nothing staged.

<table>
<tr>
<td width="50%" align="center" valign="top">
  <a href="https://youtu.be/MTSQbIyAej0"><img src="https://img.youtube.com/vi/MTSQbIyAej0/hqdefault.jpg" width="400" alt="One word - or ten: speed-reading a 99,547-word book"></a>
  <br><br><b>One word — or ten</b><br>
  <sub><i>The reading window, on 99,547 words of academic PDF.</i><br>
  Five words on the stage, then three, then four — the red pivot pinned
  through all of it. A pause into the readable page, the book's own word
  cloud, a resume at recovery speed, and the honest ledger to close:
  <b>900 WPM dialled, 232 achieved</b>.</sub>
</td>
<td width="50%" align="center" valign="top">
  <a href="https://youtu.be/KKIEJ3J0yhQ"><img src="https://img.youtube.com/vi/KKIEJ3J0yhQ/hqdefault.jpg" width="400" alt="A speed reader reads its own build story"></a>
  <br><br><b>It reads its own build story</b><br>
  <sub><i>The first film — before the reading window shipped.</i><br>
  The whole intervention ladder in one take: the ramp to 725, a back-off,
  Space into the context page, the recovery click, the brake gliding down
  to a 300 crawl and easing home, then the seal —
  <b>725 dialled, 255 achieved</b>.</sub>
</td>
</tr>
</table>

## Status

✅ **v0.9.0 — feature-complete, hardened, installer built.** Specified,
implemented, hand-tested and hardened in one day (2026-08-26 — the whole
story is in [The Night Build](docs/THE_NIGHT_BUILD.md)); the **1–9 reading
window** joined the stage the next morning, before first publish. Engine
**51/51** F_code contract-assault tests including a nine-test adversarial
pass; simple_widgets 198/198 and simple_shell 13/13 with the thirteen
features this application factored back into them. Awaiting the 1.0 tag.

- Ships as two finalized Eiffel executables (the reader and its AI worker),
  cairo.dll, and a DLL-isolated Poppler `pdftotext` — no runtime, no Python,
  **no Vision2**: the GUI is [simple_widgets](https://github.com/simple-eiffel/simple_widgets)
  over [simple_shell](https://github.com/simple-eiffel/simple_shell)
- Local-only by design: the quiz talks to your own Ollama; nothing leaves the machine
- The reading ledger (SQLite), profile, and bookmarks live beside the exe

## The idea

Reading science has two standing objections to RSVP speed reading: it
eliminates *regressions* — the backward glances that repair comprehension
(Schotter, Tran & Rayner 2014) — and it never verifies that anything was
understood. simple_speed_reader is RSVP with both objections engineered out:

- **The intervention ladder.** Tap Left: this sentence replays at pace.
  **Hold the stage (or the pedal): the BRAKE** — speed glides to a crawl
  while a fisheye ribbon of the surrounding words flows along; drag left to
  scrub back; release to ease home. Press Space: the readable context page,
  click the word you last truly read, resume there at recovery speed.
  Esc: the sitting seals into the ledger.
- **Quiz before reading (SQ3R).** A local model writes questions from your
  text at load time — in a worker process, never blocking the stream. Every
  question carries a supporting quote verified **verbatim** or it is dropped
  and counted. Preview the questions first; self-judge after; the score joins
  that run's ledger row beside dialed WPM and *achieved* WPM.

## What ships today

**The stage** — video-faithful ORP pivot with tick marks, settable font
(Alt +/− live), WPM readout that shows the ramp's intent (`425 -> 900`),
optional crossfade pacing that scales with the word's own display slot, and a
**1–9 reading window**: key 1 is the classic single word; higher keys flank
the primary with its real neighbors, fisheye-small and dimmer with distance,
inked by word-cloud significance — the red pivot stays pinned throughout.

**Governance** — ramp to a persisted comfy-max, hold (H), back-offs (Speed
drawer), speed tiers on +/− (Shift ×2, Ctrl+Shift ×4), the analog brake
(mouse-hold or B toggle).

**Navigation** — an eleven-button drawn VCR deck: start-over with a fresh
ramp, paragraph and section jumps (sections detected from markdown headings
and standalone title lines; the buttons ghost when a text has none),
play/pause, replay/here, stop, brake, speed, cloud.

**Orientation** — full-text flow map (click-to-seek when paused), progress
bar, the colorized fisheye ribbon (word-cloud significance tiers), and a
scoped **word cloud** drawer — Document / Section / Paragraph — on the W key,
the deck, or the right-edge peek-and-pin tab.

**Scholarly timing** — Hebrew and Greek linger (never faster than an
effective 350 WPM) and render centered without a fake pivot; transliterations,
numerics, and acronyms carry their own linger classes; an optional
foreign-script skip streams past glyphs while every text view shows them.

**Intake** — paste, a drive-hopping file dialog, Explorer drag-and-drop onto
any surface, and PDFs through bundled Poppler with honest refusals for
text-free scans. UTF-8 clean end to end.

**Honesty** — every sealed sitting logged: dialed peak, achieved WPM,
pauses, rewinds, skips, quiz score. Crash-safe bookmarks;
continue-where-you-left-off.

## Install

Download `SimpleSpeedReader-0.9.0-Setup.exe` from the
[latest Release](https://github.com/simple-eiffel/simple_speed_reader/releases/latest)
and run it (per-user, no UAC; ~12 MB). The uninstaller asks before touching
your reading history — and never asks silently.

## Build from source

```
/d/prod/ec.sh test -config simple_speed_reader.ecf -target simple_speed_reader_tests
./EIFGENs/simple_speed_reader_tests/F_code/simple_speed_reader.exe    # 51/51
/d/prod/ec.sh test -config simple_speed_reader.ecf -target speed_reader
/d/prod/ec.sh test -config simple_speed_reader.ecf -target speed_reader_worker
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\simple_speed_reader.iss
```

Copy `cairo.dll`, `speed_reader.ico`, and the `pdf\` extractor folder beside
the finalized exe (every finalize wipes F_code; the installer stages all of
it for shipped installs).

## Architecture

A headless, contract-first engine (`SIMPLE_SPEED_READER` facade over
tokenizer, ORP law, timing model, deadline pacer, speed governor, session
state machine, word-significance ranks, quiz gate) that a scripted clock can
drive without a window — the GUI is a view. The speed governor's invariant
*is* the product rule (`Min <= current <= target <= comfy_max`); the recovery
command's postcondition *is* the science (resume re-ramps from recovery
speed). AI runs in a spawned worker process polled by mailbox file: the pump
never meets a blocking call, by construction.

## Dependencies

| Library | Purpose |
|---------|---------|
| simple_widgets / simple_shell / simple_cairo | the drawn Win32 face |
| simple_ai_client | Ollama (worker process only) |
| simple_sql | the reading ledger |
| simple_config | the profile |
| simple_file / simple_encoding | UTF-8 intake |
| simple_pdf | bundled Poppler pdftotext |
| simple_logger / simple_process / simple_json | log, worker spawn, quiz payloads |
| base + testing (ISE), simple_testing | kernel and the assault harness |

## License

MIT — see [LICENSE](LICENSE). Bundled `pdftotext` and companions are
Poppler (GPL); they ship as separate executables in `pdf\`.
