# RISKS: simple_speed_reader

**Date:** 2026-08-26

## Risk Register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| RISK-001 | Cadence jitter at high WPM | MED | HIGH | Deadline scheduler on fast tick; measure & display truth |
| RISK-002 | Quiz generation too slow before long texts | MED | MED | Generate during preview dwell; chunked; skippable |
| RISK-003 | Ollama absent / wrong port | HIGH (env) | LOW | Detect, degrade gracefully, configurable URL |
| RISK-004 | AI hallucinates quiz content | MED | HIGH | Quote-anchored answers, verified against text |
| RISK-005 | Spritz-adjacent patents | LOW | LOW | Open-source, non-commercial; prior-art-rich field |
| RISK-006 | RSVP comprehension harm (the science) | — | HIGH | The recovery + quiz loops ARE the mitigation |
| RISK-007 | User font unavailable/metrics odd in cairo | LOW | MED | Font list from system; fallback stack; pivot from measured advances only |
| RISK-008 | Flow map cost on book-scale texts | MED | MED | Virtualize: sample blocks to pixel budget; redraw only cursor band per word |

## Technical Risks

### RISK-001: Cadence jitter / timer resolution
**Description:** At 900 WPM a word owns 66 ms. If word advance rode a coarse UI timer, real WPM
would silently fall below nominal (a 100 ms tick = max 600 WPM).
**Indicators:** Effective WPM (logged) persistently below nominal at high settings.
**Mitigation:** Arm simple_shell's app-settable fast tick (verified: shell_window.e:94, per-ms
argument) at ~10–15 ms; per-word deadlines computed on tick_ms; advance fires on first tick past
deadline; carry remainder so error doesn't accumulate. Windows timer coalescing may need
timeBeginPeriod(1) — verify during Phase 1 with a measured 1-minute run.
**Contingency:** Dedicated SCOOP ticker or waitable-timer external in simple_shell.

### RISK-002: Pre-read quiz latency on long texts
**Description:** Larry requires quiz generation BEFORE reading. A 100k-word book through a local
model could take minutes.
**Indicators:** User waits at the stopped screen with nothing to do.
**Mitigation:** Kick off generation the moment a text loads (worker); the user meanwhile previews
questions as they arrive (streamed per-chunk), tunes settings, or starts reading — the quiz merely
must be READY before it is administered, and per-chunk generation keeps early chapters' questions
available almost immediately. Chunked map (per ~2k words) → reduce (dedupe/select best N).
**Contingency:** Cap quiz scope to the first N words for huge texts; user-visible note.

### RISK-004: Quiz hallucination
**Description:** Local models invent facts; a wrong "correct answer" corrupts the comprehension log.
**Mitigation:** Prompt contract: every question ships `supporting_quote`; app verifies the quote
appears verbatim (whitespace-normalized) in the source text; failures are dropped; if >half drop,
quiz is marked low-confidence and offered anyway or regenerated with a stricter prompt.
**Contingency:** Restrict to extractive question styles (who/what/where verbatim) if abstractive
questions prove unreliable on Larry's model.

### RISK-007: Font metrics
**Description:** ORP alignment depends on exact prefix advances; a user-picked font with odd
metrics (ligatures, kerning) could wobble the pivot.
**Mitigation:** Pivot X computed from text_extents of the actual prefix in the actual font each
word (never estimated); monospace default (video uses one); kerning between prefix-end and pivot
glyph is the only theoretical wobble — imperceptible at stage sizes, verified by eye in Phase 1.

## Ecosystem Risks

### RISK-003: Ollama environment drift
**Description:** Larry's machine: WSL Ollama 0.11.10 owns 11434; native GPU 0.32.5 serves 11435;
tray app rewrites hosts. simple_ai_client defaults to 11434 — the WRONG instance here.
**Mitigation:** Base URL is a first-class setting (default 11434 for the world, Larry's profile
11435); startup probe reports which instance/model answered; all AI features degrade to disabled
with an honest status line (FR-026).

### RISK-005: Spritz patents
**Description:** Spritz Technology filed patents around ORP display (2013-era). RSVP itself is
old open research (Forster 1970; Potter 1984) and ORP-style highlighting is implemented by many
open-source readers without incident.
**Mitigation:** Non-commercial MIT ecosystem library; no Spritz trademark use; note kept here.

## Resource Risks

### RISK-R1: Scope creep from AI features
**Description:** Preprocessor/quiz/drill each hide deep rabbit holes (prompting, model bake-offs).
**Mitigation:** Phase 1 ships the reader with NO AI (fully useful); Phase 2 adds the pipeline
behind the already-designed seams (PRE_PROCESSOR, QUIZ_MAKER as separate workers). Model bake-off
is a bounded task on real simple_ocr_capture output.
