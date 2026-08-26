# INNOVATIONS: simple_speed_reader

**Date:** 2026-08-26

## What Makes This Different

### I-001: The comprehension-recovery loop (regression restored)
**Problem Solved:** RSVP's documented fatal flaw — Schotter, Tran & Rayner (2014) showed that
eliminating regressions (re-reading), which is exactly what word-streams do, measurably harms
comprehension. Every surveyed RSVP app either ignores this or offers only a dumb scrub bar.
**Approach:** One key stops the stream and swaps the stage for a readable context page (the
regression). The user marks the last-comprehended word with a click (or accepts the
start-of-sentence default), and the stream resumes THERE at ~250 WPM, re-ramping toward the
session max. Getting lost costs seconds, not the chapter.
**Novelty:** No comparable (Spritz, chislerr/rsvp-reader, speeedy, Stutter) has any
lost-attention recovery flow, let alone one that re-ramps.
**Design Impact:** Stage is a two-mode widget (stream / context page with word hit-testing);
SPEED_GOVERNOR owns the ramp state machine.

### I-002: Quiz-before-reading (SQ3R operationalized by AI)
**Problem Solved:** Speed without verified comprehension is self-deception; and readers comprehend
better when they know what to look for (SQ3R's Survey+Question steps, Robinson 1941).
**Approach:** For ANY text the user loads, the local model generates a comprehension quiz BEFORE
reading begins. Opt-in, two uses: (a) preview the questions beforehand — the mental-model-forming
ritual Larry described as reading a book's ToC/index before its interior; (b) take the quiz after,
score joins the log. Answers must carry supporting quotes verified to occur in the text
(anti-hallucination gate).
**Novelty:** No surveyed reader tests comprehension at all; none pre-generates study questions.
**Design Impact:** QUIZ_MAKER worker (SCOOP separate), quiz stored keyed by text hash for reuse.

### I-003: The flow map (spatial anchor for a streamed text)
**Problem Solved:** A word-stream amputates the page — readers lose the "where am I in this text"
geography that physical pages give for free.
**Approach:** The left edge renders the entire text as unreadable word-proportional blocks — pure
texture — with a cursor marking the flowing word, read-portion brighter. Paused, it becomes the
scrubber.
**Novelty:** Comparables show a progress bar at best; a full-text minimap with a live word cursor
is a code-editor idiom imported into reading.
**Design Impact:** Second SW_CANVAS; needs block virtualization/sampling for 200k-word texts.

### I-004: All-local AI pipeline
**Problem Solved:** Real sources (OCR output, pasted web text) are stream-hostile: headers, page
numbers, broken hyphenation, footnote markers. Cloud cleanup is a privacy/cost non-starter for
whole books.
**Approach:** Ollama on the user's own GPU (simple_ai_client) does cleanup, quiz generation, and
drill-text generation. Reader is fully functional with AI absent.
**Novelty:** None of the comparables preprocess at all; pairing with simple_ocr_capture makes a
scan→clean→speed-read pipeline entirely on-machine.

### I-005: Zero-chrome running state
**Problem Solved:** RSVP holds the eye on one fixation point; every visible control is competition.
**Approach:** Running shows ONLY the stream (stage, flow map, WPM). Everything else exists in
pause/stop. Keyboard-first control while running.
**Novelty:** Comparables mostly float toolbars over the stream; full modal separation is cleaner
and matches the video's aesthetic.

### I-006: Honest speed accounting
**Problem Solved:** Speed readers report the dial setting, not reality.
**Approach:** Log the achieved effective WPM (words ÷ wall time, breathers and rewinds included)
alongside nominal WPM and quiz score — the three-axis truth: dialed speed, real speed, retention.
**Design Impact:** Session recorder accumulates per-word timestamps (cheap, from tick_ms).

## Differentiation from Existing Solutions

| Aspect | Existing (best of) | Our Approach | Benefit |
|--------|--------------------|--------------|---------|
| Lost attention | Scrub bar, bookmarks (chislerr) | Context page → click last-comprehended → re-ramp | Recovery in seconds; regression restored |
| Comprehension | Never measured | Pre-generated, quote-anchored quiz; opt-in; logged | Speed claims become verifiable |
| Pre-reading | Nothing | SQ3R question preview | Mental model before the stream starts |
| Dirty sources | Fail or garbage stream | Local-AI preprocessor | OCR/book-scan pipeline works end-to-end |
| Position sense | Progress bar | Full-text flow map + word cursor | Page geography restored |
| Stats | Speed only (speeedy) | Speed + rewinds + comprehension trend | Trains the actual goal |
