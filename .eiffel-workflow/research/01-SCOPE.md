# SCOPE: simple_speed_reader

**Date:** 2026-08-26
**Idea source:** Larry's video `C:\Users\LJR19\Videos\read-speed-drill.mp4` (55s screen capture of a
Spritz-style RSVP reader: one word at a time, red pivot letter fixed at screen center with tick
marks, dark screen, `SPEED: NNN WPM` readout ramping 300 → 803 WPM, blank breathers at sentence ends).

## Problem Statement

In one sentence: **Reading long-form text at high speed (up to ~900 WPM) while actually retaining
comprehension — RSVP readers deliver the speed but lose the reader the moment attention lapses,
because they eliminate the natural ability to regress (re-read).**

What's wrong today: Existing RSVP apps stream words at a fixed or ramping pace. When the reader is
distracted or lost-in-thought, the stream marches on; recovery means fumbling with a scrub bar and
guessing where comprehension stopped. Research (Schotter, Tran & Rayner 2014) shows that removing
regressions — exactly what RSVP does — measurably damages comprehension.

Who experiences this: Larry, reading real texts (books, articles, OCR output from
simple_ocr_capture) — not doing exercises. Secondary: anyone consuming long-form text on a desktop.

Impact of not solving: Speed reading remains a party trick — fast consumption, poor retention,
no honest feedback about whether anything was understood.

## Identity (CRITICAL)

This is a **reader**, not a trainer. The user is consuming real text they chose. A **drill mode**
(AI-generated practice texts) exists as a secondary feature, not the identity.

## Target Users

| User Type | Needs | Pain Level |
|-----------|-------|------------|
| Primary reader (Larry) | Read real texts fast, recover gracefully when lost, verify comprehension | HIGH |
| Self-improver | Track speed/comprehension over time, drill upward | MED |

## Success Criteria

| Level | Criterion | Measure |
|-------|-----------|---------|
| MVP | Video parity: dark RSVP stage, red ORP pivot fixed-X, tick marks, WPM readout, ramping speed | Side-by-side with video |
| MVP | Recovery loop works: stop → pick last-comprehended word → resume at ~250 WPM → re-ramp | Hand test |
| MVP | Cadence honest at 900 WPM (66 ms/word) | Measured jitter < 1 frame |
| Full | Quiz generated BEFORE reading on any user text; reviewable beforehand; scored after | Hand test with real chapter |
| Full | Reading log persists speed profile + rewinds + quiz scores across sessions | DB rows survive restart |

## Scope Boundaries

### In Scope (MUST)
- RSVP stage exactly as the video: dark-only, settable font/size, settable text, ramping WPM
- Two-state GUI: while the stream runs, the window shows ONLY the stream (stage + flow map +
  WPM readout); every control/setting/quiz surface lives in pause/stop mode
- Left-side flow map: unreadable miniature of the whole text, word-cursor tracking the stream
- Recovery loop: stop → back up to last-comprehended point → restart at 200–300 WPM → re-ramp
  toward max (900 default, user-settable comfy-max)
- Speed governance while reading: hold-at-current control; back-off steps (−100 / −50 / −25)
- Local-AI text preprocessor (Ollama via simple_ai_client) for unclean sources
- Comprehension quiz: generated BEFORE reading from the actual text, opt-in, reviewable
  beforehand (SQ3R survey/question step), administered and scored after
- Persistent log of reading speed and comprehension results

### In Scope (SHOULD)
- Punctuation/word-length-aware timing (linger on long words, beats at commas/sentence ends)
- Flow map as scrubber (click to seek) when paused
- History view with speed/comprehension trend (SW_SPARKLINE / SW_LINE_CHART)
- Drill mode: series of AI-generated graded practice texts (secondary mode)

### Out of Scope
- Light mode: Larry specified dark-only
- EPUB/PDF/MOBI parsing: intake is paste + .txt/.md files (simple_ocr_capture already produces .md)
- Cloud AI: local Ollama only (privacy, cost, offline)
- Mobile/web: Windows desktop (simple_widgets is Win32 today)

### Deferred to Future
- Phrase grouping / multi-word chunking (AI glues function words): after single-word engine is solid
- Voice narration pairing (simple_speech exists): unrelated to core loop

## Constraints

| Type | Constraint |
|------|------------|
| Technical | SCOOP-compatible; void-safe; contracts everywhere; F_code releases |
| Ecosystem | simple_* first: simple_widgets UI, simple_ai_client AI, simple_sql log, simple_config settings |
| Technical | AI must never block the reading loop; app fully usable with no Ollama running |
| Environment | Larry's native Windows Ollama listens on 11435 (WSL relic owns 11434) — base URL must be configurable |

## Assumptions to Validate

| ID | Assumption | Risk if False |
|----|------------|---------------|
| A-1 | simple_shell fast tick (`set_fast_tick`, ms-granular) gives ≤15 ms scheduling jitter | Cadence dishonest at high WPM; would need dedicated timer path |
| A-2 | A local Ollama model (e.g. qwen-class) can generate faithful quiz Q&A anchored in the text | Quiz feature unreliable; needs stronger prompting/validation |
| A-3 | cairo text extents via SW_PAINTER suffice for per-glyph ORP alignment in any user font | Pivot drifts; would need per-char advance measurement loop |
| A-4 | Pre-generating a quiz on a chapter-sized text completes within a preview-reading dwell (~30–90 s) | User waits; mitigate with progress + chunking + skip |

## Research Questions
- What do existing RSVP readers do about losing one's place? (Landscape)
- What does reading science say about RSVP and comprehension? (Landscape — answered: regressions matter)
- Is "review the questions before reading" a validated technique? (Yes — SQ3R, Robinson 1941)
- What ORP position do implementations use? (~1/3 into the word, length-dependent)
