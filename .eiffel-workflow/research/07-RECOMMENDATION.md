# RECOMMENDATION: simple_speed_reader

**Date:** 2026-08-26

## Executive Summary

Build simple_speed_reader as a Windows desktop RSVP **reader** (not trainer) on the simple_widgets
stack: video-parity dark stage with fixed ORP pivot, ramping speed to a user comfy-max (default
900 WPM), and the two features no existing reader has — a comprehension-recovery loop (stop →
mark last-comprehended word → re-ramp from ~250) and a local-AI quiz pipeline (generated before
reading, reviewable beforehand per SQ3R, scored after, logged). Every required capability is
verified present in the ecosystem; the reading-science literature directly endorses the two novel
loops as fixes to RSVP's documented weaknesses.

## Recommendation
**Action:** BUILD
**Confidence:** HIGH

## Rationale
- No existing solution (Spritz, chislerr/rsvp-reader, speeedy, Stutter) closes the comprehension
  loop or recovers from lost attention; adopting/adapting buys only the easy 20%.
- The hard-sounding parts are verified cheap: cadence (shell fast tick + tick_ms deadlines), ORP
  alignment (cairo x_advance), custom drawing (SW_CANVAS/SW_PAINTER), local AI (OLLAMA_CLIENT),
  persistence (simple_sql).
- Schotter et al. 2014 / Rayner et al. 2016 give the design scientific footing: regressions and
  comprehension verification are what RSVP lacks — they are this product's spine.

## Proposed Approach

### Phase 1 (MVP — the reader, zero AI)
- Word engine: tokenizer (words + punctuation/paragraph structure), timing model (D-005), ORP (D-006)
- SPEED_GOVERNOR: ramp / hold / back-off (−100/−50/−25) / recovery re-ramp (D-004)
- Two-state GUI (D-002): running = stage + flow map + WPM only; paused = cockpit
- Recovery loop (D-003): context page, click-to-mark, sentence-start default
- Intake: paste + .txt/.md file dialog; settings (font, sizes, speeds) via simple_config
- Log: runs/stops/effective-WPM to simple_sql; minimal history list
- Keyboard map: Space stop/resume, H hold, arrows nudge, 1/2/3 back-off 100/50/25, Esc stop-mode

### Phase 2 (the comprehension product)
- PRE_PROCESSOR worker: Ollama cleanup of unfriendly sources (opt-in, diff view)
- QUIZ_MAKER worker: pre-read generation, quote-anchored validation, SQ3R preview pane,
  post-read administration + scoring into the log
- History charts (sparkline: nominal vs effective WPM vs quiz score)
- Drill mode: cached AI-generated graded texts through the same engine

## Key Features
1. **Video-parity RSVP stage** — dark-only, red ORP pivot pinned with tick marks, live WPM readout
2. **Recovery loop** — one key out of the stream, click the last word you truly read, ramp back up
3. **Speed governance** — ramp to comfy-max, hold-at-current, three back-off buttons
4. **Flow map** — whole-text miniature with live word cursor; scrubber when paused
5. **Quiz-before-reading** — local AI writes the test first; preview it to prime comprehension (SQ3R)
6. **Honest log** — nominal WPM, achieved WPM, rewinds, quiz scores, trends

## Success Criteria
- A 1-minute 900-WPM run delivers 900±5 words (measured, logged)
- Distraction → recovered reading position in ≤ 3 user actions
- A real simple_ocr_capture .md chapter streams clean after preprocessing
- Quiz on a known text: 100% of surviving questions carry verbatim-verified quotes
- Log rows and trend chart survive app restart

## Dependencies

| Library | Purpose | simple_* Preferred |
|---------|---------|--------------------|
| simple_widgets | window, theme, canvas stage, cockpit widgets | YES |
| simple_shell (transitive) | pump, fast tick, tick_ms, keys | YES |
| simple_cairo (transitive) | text metrics, rendering | YES |
| simple_ai_client | OLLAMA_CLIENT for preprocessor/quiz/drill | YES |
| simple_sql | reading + comprehension log | YES |
| simple_config | settings incl. Ollama base URL | YES |
| simple_file, simple_encoding | .txt/.md intake, UTF-8→32 | YES |
| ISE base | kernel | allowed |

## Next Steps
1. Run `/eiffel.spec d:\prod\simple_speed_reader` to transform this research into the specification
2. Then `/eiffel.intent` to capture refined intent (resolve OQ-1…OQ-5 from 04-DECISIONS.md)
3. Continue the Eiffel Spec Kit workflow

## Open Questions (carried to spec/intent)
- OQ-1 flow map visible while running (assumed YES)
- OQ-2 recovery WPM fixed vs proportional
- OQ-3 quiz density default
- OQ-4 preview = questions only vs questions + AI outline
- OQ-5 default local model (bake-off on Larry's GPU, 11435)
