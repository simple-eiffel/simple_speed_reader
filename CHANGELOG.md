# Changelog

All notable changes to simple_speed_reader are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning: [SemVer](https://semver.org/).

## [0.9.0] - 2026-08-26 (the night build)

Feature-complete in one evening, on top of the same day's design + v0.1:
- **Persistence**: SR_SETTINGS profile (simple_config, UTF-8-safe paths) +
  SR_LOG SQLite ledger (every sealed run: speeds, rewinds, quiz score);
  crash-safe bookmark on every pause/seal; Continue-where-I-left-off.
- **Fisheye ribbon** (D-015) above the paused context page - clickable resume points.
- **Speed drawer** (D-012): live dial, hold/release, back-offs, nudges.
- **BRAKING** (D-016): hold the stage to glide to 300 with the ribbon flowing live;
  drag left = halt + proportional scrub-back, drag right = re-engage; release eases
  back to cruise and restores a held pin. simple_widgets gained handle_release.
- **AI quiz pipeline** (D-007): speed_reader_worker exe (spawned, never blocks the
  pump) asks local Ollama for questions as strict JSON; think-blocks stripped;
  every quote verified verbatim against the text (hallucinations dropped and
  counted); SQ3R preview drawer; post-seal self-judged administration; score into
  the ledger. Live-verified on Ollama 11435 / Qwen3-8B: 5/5 real questions.
- **Installer**: SimpleSpeedReader-0.9.0-Setup.exe (Inno, 7 MB, 7.8 s build) -
  per-user, both exes + cairo.dll + icon + demo + guide, ledger-preserving
  uninstall prompt (UninstallSilent-guarded per the ocr lesson).
- Engine tests 35/35 F_code; widgets 198/198.
- **Late-night round**: Explorer drag-and-drop onto any surface or the cockpit drop tray
  (SW_DROPZONE + canvas file agents); **PDF intake** via simple_pdf's bundled pdftotext
  (live-verified on the ECMA-367 Eiffel standard), honest refusals for scans/missing extractor;
  file dialog filters .txt/.md/.pdf; **the deck** - drawn VCR transport (PLAY/HERE/STOP/BRAKE
  pedal/SPEED dial) with the automotive brake-warning glyph; pedal-hold in paused resumes
  braked. Factored back to simple_widgets as ecosystem courtesy: SW_CANVAS grew
  key/char/release/file agents (SR_SURFACE dissolved), SW_PAINTER grew triangle_fill +
  arc_stroke; suite 198/198.

## [Unreleased]

### Added
- 2026-08-26 — Pre-phase research complete (7/7): landscape (Spritz, chislerr/rsvp-reader,
  speeedy, Stutter), reading-science grounding (Schotter et al. 2014, Rayner et al. 2016, SQ3R),
  recommendation BUILD/HIGH. `.eiffel-workflow/research/`
- 2026-08-26 — Specification complete (8/8, verdict READY): 26 classes, 42 functional
  requirements traced, contracts drafted, SCOOP AI-gateway architecture. `.eiffel-workflow/spec/`
- 2026-08-26 — Design decisions D-011–D-014: adaptive word timing (length bands, Hebrew/Greek
  script linger + WPM floor, transliteration/numeric/acronym classes), three GUI postures
  (running / paused-drawered / stopped-cockpit), foreign-script skip filter, media-transport
  keymap with in-flow micro-rewind.
- 2026-08-26 — Repo scaffolded: README, docs/, USER_GUIDE, timeline tracking.
- 2026-08-26 — D-015 fisheye ribbon (paused focus+context strip, clickable resume points);
  D-016 analog BRAKING (hold: glide to 300 with live ribbon; drag left stop+scrub / right
  re-engage; release: ease back to cruise) completing the intervention ladder.
- 2026-08-26 — Program icon generated (scripts/make_icon.py): "r·e·ad"+ticks mark, 7-size
  speed_reader.ico + docs logo.svg + icon-256.png.
- 2026-08-26 — DESIGN_STORY.md: rolling interaction narrative beside the specifications.

### Added — v0.1 hand-test build (2026-08-26, same day)
- Engine (src/): SR_TOKEN (ORP law frame-corrected to 1/2-5/6-9/10-13/14+ bands, combining-mark
  avoidance, script/diacritic/numeric/acronym classification), SR_TOKENIZER (paragraph/sentence/
  clause structure, closing-quote-aware), SR_GOVERNOR (ramp/hold/back-off/recovery, hold-aware
  back-off), SR_TIMING_MODEL (linger classes, foreign 350-WPM floor, breathers), SR_PACER
  (deadline-anchored, drift-free, sleep-tolerant), SR_SESSION (three states, seal-on-stop,
  micro-rewind/skip, foreign-skip accounting), SR_RUN_RECORD, SR_TEXT, SIMPLE_SPEED_READER facade.
- Tests (testing/): 26 contract-assault tests — **26/26 passing, F_code**.
- GUI (app/): SR_APP three postures over the 12 ms shell fast tick; SR_STAGE_VIEW (pinned red
  pivot + ticks, blank breathers, WPM readout, foreign centered/no-pivot); SR_CONTEXT_VIEW
  (readable recovery page, click-to-mark); SR_FLOW_MAP_VIEW (whole-text texture, cursor,
  paused backward scrubbing); SR_COCKPIT (paste/file intake, speed anchors, foreign-skip,
  honest run summary); SR_SURFACE key-hearing canvas. demo/sample_text.md exercises every
  linger class (Hebrew, Greek, translits, Strong's refs, LXX).
- simple_widgets gained SW_WINDOW.give_focus (additive; its suite re-run: 193/193).

Deferred to next iteration (specified, not built): AI preprocessor + quiz, persistent log,
fisheye ribbon, braking gesture, drawers, position autosave, installer.
