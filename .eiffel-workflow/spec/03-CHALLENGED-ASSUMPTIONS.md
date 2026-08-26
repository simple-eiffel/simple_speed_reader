# CHALLENGED ASSUMPTIONS: simple_speed_reader

**Date:** 2026-08-26

## Assumptions Challenged

### A-1 (research): shell fast tick gives ≤15 ms scheduling jitter
**Challenge:** `set_fast_timer` (shell_window.e:93) uses Win32 timers; WM_TIMER coalesces and its
floor is USER_TIMER_MINIMUM (10 ms) — worse under load. Also UNVERIFIED whether SW_WINDOW.on_tick
fires per fast-timer event or only on the ambient clock.
**Evidence for:** simple_ocr_capture's strip rode this plumbing at ~1 Hz happily; sw_window.e
comments name "the fast tick" among pumped shell events.
**Evidence against:** none measured at 60–80 Hz rates yet.
**Verdict:** NEEDS_VALIDATION
**Action:** Phase 1 gate test: arm 12 ms timer, count on_tick callbacks + measure word-deadline
error over a 60 s scripted run; contingency = waitable-timer external added to simple_shell.
Design already tolerates jitter (deadline scheduler with carry — SR_PACER), so the risk is bounded
to ±one tick of display time, never cumulative drift.

### A-2 (research): local model can generate faithful quizzes
**Challenge:** Small local models hallucinate and drift from instructions (memory: olmOCR-2
silently "corrects" content even when prompted not to).
**Verdict:** NEEDS_VALIDATION (bounded)
**Action:** The design does not trust the model: SR_QUIZ_VALIDATOR drops any question whose
supporting quote is not verbatim in the text (DR-005). A quiz can arrive short or empty — the
product degrades to "no quiz available", never to a wrong quiz. Model bake-off is a Phase 2 task.

### A-3 (research): cairo extents suffice for ORP pinning in any font
**Challenge:** Kerning between prefix and pivot glyph makes advance(prefix) ≠ exact pivot origin.
**Evidence for:** Stage font default is monospace (video uses one) — zero kerning; at 60–90 px
sizes a sub-pixel kern wobble is invisible anyway.
**Verdict:** VALID (with FR-030's curated-font guard)
**Action:** none beyond FR-030; eyeball check in Phase 1 demo.

### A-4 (research): quiz generation fits a preview dwell
**Challenge:** A 100k-word book through a local model does NOT finish in 90 s.
**Verdict:** INVALID as stated — and already superseded by design.
**Action:** Requirement reworded (see FR-022 note below): generation *starts* before reading and
questions stream in per chunk; administration (the only thing that needs the full quiz) happens
after reading, by which time generation has had the whole session. "BEFORE" is preserved where it
matters: questions are authored from the text, not from the reader's answers, and preview shows
whatever has arrived.

### A-NEW: simple_ai_client can be called from the UI loop
**Challenge (new fact, verified 2026-08-26):** `OLLAMA_CLIENT.execute_chat` is SYNCHRONOUS —
"Ollama AI client using curl via SIMPLE_PROCESS_HELPER" (ollama_client.e:2,137). A chapter-sized
cleanup call would freeze the pump for seconds-to-minutes.
**Verdict:** INVALID to call from UI — architecture consequence.
**Action:** SR_AI_GATEWAY is a `separate` processor owning the client; UI submits jobs
(non-blocking command) and polls SR_MAILBOX (a tiny separate result box locked only for handoff)
from the tick. DR-009. This is the SCOOP mailbox pattern; no UI stall is possible by construction.

## Requirements Questioned

### FR-022: Quiz "generated BEFORE reading"
**Challenge:** Strict-blocking interpretation would gate reading on minutes of inference (A-4).
**Verdict:** MODIFY (semantics, not intent)
**New reading:** Generation is *launched* at text load, streams per-chunk, and must be complete
before quiz *administration*; preview shows arrived questions live. Larry's intent — the test
exists independent of and prior to the reading experience — is preserved.

### FR-011: Flow map scrubber (SHOULD)
**Challenge:** Redundant with context-page click?
**Verdict:** KEEP — context page covers local regression (sentences); scrubber covers gross
navigation (chapters). Different granularities.

### FR-016: Zero-click resume = sentence start
**Challenge:** Is sentence start enough after a long mind-wander?
**Verdict:** KEEP as default; the click path (FR-014) exists precisely for the long-wander case.
Recovery-WPM re-ramp makes an over-shallow rewind self-correcting (re-reading at 250 is cheap).

### FR-029: Drill mode
**Challenge:** Scope creep magnet (generation UI, difficulty grading, text library).
**Verdict:** KEEP as SHOULD/Phase 2; engine-reuse only (a drill is a session whose text came from
SR_DRILL_JOB and whose record is tagged `is_drill`). No separate engine.

## Missing Requirements Identified

| ID | Missing Requirement | How Discovered |
|----|---------------------|----------------|
| FR-030 | Curated font list + safe fallback | A-3 challenge (cairo silently substitutes unknown families) |
| FR-031 | Resize-safe pivot pinning | walking the running-state layout: pin X is a function of live width |
| FR-032 | Position autosave + resume offer | UC-001 walkthrough: a crash mid-book must not lose the place |
| FR-033 | Content-hash text identity | UC-002 walkthrough: quiz reuse and log joins need a stable key (simple_hash) |

## Design Constraints Validated

| Constraint | Valid? | Notes |
|------------|--------|-------|
| simple_* first | YES | widgets, shell (transitive), cairo (transitive), ai_client, sql, config, file, encoding, hash, diff — all present in D:\prod |
| SCOOP-compatible | YES | one separate processor (gateway) + one separate mailbox; GUI and engine in the creator region; no separate calls on the hot path |
| Void-safe | YES | detachable only where domain-real: quiz score, active text, mailbox slots |
| Dark-only | YES | SW_THEME.make_dark at creation; no toggle surface |
| Oracle Testing Standard | YES | simple_testing + ISE testing; testing/test_app.e; TEST_SET_BASE asserts (finalized `check` is vacuous — recorded gotcha) |
| Oracle gotchas applied | YES | across-as element binding (use `ic` as element, or `@ic` cursor forms per ES 25.02); no PROCEDURE [TUPLE […]] single-arg intents (flattening gotcha) — view agents take scalar args; SW containers need preferred_width; rrect radius > 0 |
