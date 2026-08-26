# PARSED REQUIREMENTS: simple_speed_reader

**Date:** 2026-08-26. Parsed from `.eiffel-workflow/research/` (all 8 documents, written 2026-08-26).

## Problem Summary

Read long-form real text at high speed (ramping to a user comfy-max, default 900 WPM) with
comprehension **retained and verified**. RSVP streams deliver speed but destroy the two things
reading science says comprehension needs: regression (re-reading — Schotter et al. 2014) and
verification. This product is an RSVP **reader** (not a trainer) whose spine is a
comprehension-recovery loop and a local-AI quiz pipeline. Drill mode is secondary.

## Scope

### In Scope
- Video-parity dark RSVP stage: fixed ORP pivot (red) + tick marks + live WPM readout
- Two-state GUI: RUNNING = stream only (stage + flow map + WPM); PAUSED/STOPPED = cockpit
- Recovery loop: stop → context page → mark last-comprehended word → re-ramp from recovery WPM
- Speed governance: ramp, hold-at-current, back-off −100/−50/−25, comfy-max
- Flow map: whole-text miniature, live word cursor, scrubber when paused
- Local-AI (Ollama): preprocessor, quiz generated BEFORE reading (opt-in, SQ3R preview, scored after)
- Persistent log: nominal + effective WPM, rewinds, quiz scores; trends
- Intake: paste + .txt/.md; settable font/size/speeds; dark-only
- Drill mode (secondary): AI-generated graded texts

### Out of Scope
- Light mode; EPUB/PDF/MOBI parsing; cloud AI; mobile/web; phrase grouping (deferred)

## Functional Requirements

Carried verbatim from research/03-REQUIREMENTS.md — FR-001…FR-029 (29 items) grouped:
stage FR-001–005 · state GUI FR-006–008 (refined to three postures by D-012 / FR-034–036) ·
flow map FR-009–011 · recovery FR-012–016 ·
governance FR-017–020 · AI FR-021–026 · log FR-027–028 · drill FR-029.
Priorities: 24 MUST, 5 SHOULD. Acceptance criteria as recorded there.

**Added by this phase (see 03-CHALLENGED-ASSUMPTIONS.md):**

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-030 | Font chooser offers a curated installed-monospace list plus free entry; unknown family falls back visibly, never crashes | MUST | spec/03 | pick nonsense name → stage still renders, status notes fallback |
| FR-031 | Window resize while running: stage re-centers, pivot pin X recomputed, no restart | MUST | spec/03 | resize mid-run → pivot stays pinned |
| FR-032 | Position autosave: current text + word index survive app crash/exit; offer resume on reload | MUST | spec/03 | kill app mid-book → reopen → offered same position |
| FR-033 | Text identity = content hash (simple_hash); quiz and log rows key on it so re-loading a text reuses its quiz | MUST | spec/03 | reload same file → quiz not regenerated |
| FR-034 | A dim PAUSE affordance is always visible, even while RUNNING; the whole stage is also a pause hit-target | MUST | D-012 | pause reachable by mouse alone mid-stream |
| FR-035 | PAUSED posture: context page + live scrubber; controls present as drawered SW_DRAWER panels (Speed, Quiz preview, Settings) summoned from slim edge tabs | MUST | D-012 | drawers open/close without leaving paused |
| FR-036 | STOPPED posture: full cockpit un-drawered (intake, settings, quiz administration, history, Continue-at-N); Stop SEALS the sitting (record logged, position saved) | MUST | D-012 | Esc from reading → cockpit, run row logged |
| FR-037 | Adaptive presentation time: graduated length multiplier (1-5/6-8/9-11/12+ → ×1.0/1.1/1.3/1.5), foreign script ×2.5 + effective-WPM floor 350, Latin diacritics ×1.6, numerics ×1.8, acronyms ×1.4, stack capped ×3.0 | MUST | D-011 | H7225, ἀγάπη, agapē each measurably linger |
| FR-038 | Foreign-script tokens render centered, whole-word, no red pivot; pivot indexing skips combining marks in every script | MUST | D-011 | niqqud never colored as pivot |
| FR-039 | AI enrichment pass (opt-in, SR_AI_JOB family) tags bare-ASCII transliterations as foreign-linger class; deterministic classes stand without AI | SHOULD | D-011 | "bereshit" lingers after enrichment |
| FR-040 | Foreign-script skip filter (opt-in, default OFF): stream skips non-Latin tokens; transliterations kept (Latin); context page + flow map always show full text; skipped count logged | MUST | D-013 | Hebrew glyphs absent from stream, present on context page |
| FR-041 | In-flow micro-rewind (Left): replay from previous sentence start, stream keeps flowing, speed unchanged; in-flow skip-forward (Right): next sentence, skipped words logged | MUST | D-014 | tap Left mid-stream → sentence replays without pause posture |
| FR-042 | Transport keymap per media convention (Space/K, Esc/S, Left/Right, Ctrl+arrows, Up/Down, ,/., Home) incl. hardware media keys; full table in spec/06 | MUST (media keys SHOULD) | D-014 | every binding drives the documented command |
| FR-043 | Fisheye ribbon in PAUSED posture, above the context page: one-line focus+context strip of real surrounding words, sizes tapering from tiny edges to the biggest center current word (scale max(0.24, 0.72^distance)); left=streamed normal, right=upcoming dimmer; click any ribbon word → resume point | MUST | D-015 | glanceable "where am I" without reading; click seeks |
| FR-044 | Program icon: multi-res .ico (256…16, per-size rendered — full "r·e·ad"+ticks mark ≥48, "r"+ticks ≤32) embedded in exe (window/taskbar), used by installer (SetupIconFile + UninstallDisplayIcon), logo.svg + icon-256.png in docs | MUST (ship) | Larry 2026-08-26 | icon shows in taskbar, installer, README |
| FR-045 | BRAKING (hold stage / brake affordance / key B): speed eases from present to 300 over ~1.5 s; fisheye ribbon overlays the running stage and flows live in sync; release → ease back to pre-brake speed, then normal governance resumes. Stage quick-tap (<~250 ms, no drag) remains Pause | MUST | D-016 | hold → glide + live ribbon; release → back to cruise |
| FR-046 | Brake-drag gesture while held: drag left → decelerate to full stop, continued left scrubs position backward (rate ∝ distance); drag right → re-engage forward flow ramping to 300; release anywhere → resume toward pre-brake speed. Brake events (depth, scrub span) logged | MUST | D-016 | left-stop-rewind / right-re-engage / release-cruise works one-handed |

## Non-Functional Requirements

| ID | Requirement | Category | Measure | Target |
|----|-------------|----------|---------|--------|
| NFR-001 | Cadence honesty at 900 WPM (66 ms/word) | PERFORMANCE | jitter vs deadline | ≤ 15 ms (one fast tick) |
| NFR-002 | Stop latency | PERFORMANCE | keypress → frozen | ≤ one tick |
| NFR-003 | AI never blocks UI | ARCHITECTURE | UI thread awaits no HTTP | separate worker + mailbox |
| NFR-004 | Book scale | CAPACITY | 200k-word text | loads, maps, streams smoothly |
| NFR-005 | Local-only | PRIVACY | outbound | localhost Ollama only |
| NFR-006 | Quality gates | QUALITY | ec.sh test green, contracts everywhere | 100% |

## Constraints (simple_* First)

| ID | Constraint | Type |
|----|------------|------|
| C-001 | simple_* over ISE/Gobo: simple_widgets, simple_ai_client, simple_sql, simple_config, simple_file, simple_encoding, simple_hash, simple_diff | ECOSYSTEM |
| C-002 | SCOOP-compatible (concurrency=scoop); AI worker is a separate processor | TECHNICAL |
| C-003 | Void-safe (void_safety=all) | TECHNICAL |
| C-004 | Dark-only product | PRODUCT |
| C-005 | Ollama base URL configurable (Larry: 11435; world default 11434) | ENVIRONMENT |
| C-006 | F_code releases via ec.sh; cairo.dll beside exe | BUILD |
| C-007 | Test targets: simple_testing (TEST_SET_BASE) + ISE testing; testing/test_app.e runner | ECOSYSTEM (oracle Testing Standard) |

## Decisions Already Made (research/04-DECISIONS.md)

| ID | Decision | Rationale |
|----|----------|-----------|
| D-001 | Reader identity; drill secondary | Larry explicit |
| D-002 | Two-state GUI; running chrome-free; keyboard-first | Larry explicit (2026-08-26) |
| D-003 | Recovery = context page + click-to-mark; zero-click default = sentence start; always re-ramp | only reader knows comprehension point |
| D-004 | Ramp linear in words to target; HOLD pins; back-offs lower session target, not comfy-max | matches video + Larry's controls |
| D-005 | Timing: 60000/wpm base × length modifier + punctuation/paragraph beats (blank breathers) | video + comparables |
| D-006 | ORP index by length (1→1, 2–4→2, 5–9→3, 10+→4); pivot pinned via measured prefix advance | video frames reproduced |
| D-007 | AI local Ollama via simple_ai_client; pre-generated quiz, quote-anchored validation; graceful absence | Larry + anti-hallucination |
| D-008 | simple_sql log; simple_config settings | ecosystem standard |
| D-009 | simple_widgets + shell fast tick deadline scheduler | verified capabilities |
| D-010 | Name simple_speed_reader | Larry chose |

## Innovations to Implement (research/05)

| ID | Innovation | Design Impact |
|----|------------|---------------|
| I-001 | Comprehension-recovery loop | SR_SESSION state machine + SR_CONTEXT_VIEW hit-testing + governor re-ramp |
| I-002 | Quiz-before-reading (SQ3R) | SR_QUIZ_JOB pre-generation + SR_QUIZ_VALIDATOR quote gate + preview panel |
| I-003 | Flow map spatial anchor | SR_FLOW_MAP_VIEW with virtualized blocks + cursor band |
| I-004 | All-local AI | SR_AI_GATEWAY (separate) over OLLAMA_CLIENT; absence-tolerant |
| I-005 | Zero-chrome running state | SR_APP two-state layout switch; SR_KEYS map |
| I-006 | Honest speed accounting | SR_SESSION per-word timestamps → effective WPM in SR_RUN_RECORD |

## Risks to Address in Design (research/06)

| ID | Risk | Mitigation Strategy in Design |
|----|------|-------------------------------|
| RISK-001 | Cadence jitter | SR_PACER deadline scheduler on tick_ms; fast timer ~12 ms; remainder carry |
| RISK-002 | Quiz latency | chunked generation in worker; questions stream into mailbox; reading never gated |
| RISK-003 | Ollama env drift | SR_SETTINGS url; SR_AI_GATEWAY.is_available probe; disabled-with-status affordances |
| RISK-004 | Quiz hallucination | SR_QUIZ_VALIDATOR verbatim-quote gate; drop-and-count |
| RISK-007 | Font metrics | pivot X from measured prefix advance each word; curated font list (FR-030) |
| RISK-008 | Flow map cost | pixel-budget sampling; per-word redraw limited to cursor band |

## Use Cases

### UC-001: Read with recovery (the spine)
**Actor:** Reader
**Precondition:** Text loaded (session ready)
**Main Flow:**
1. Reader starts; window becomes stream-only; ramp climbs from start_wpm
2. Mind wanders at word N; reader hits Space — stream freezes ≤ one tick
3. Stage swaps to context page (surrounding paragraphs, word N marked)
4. Reader re-reads normally, clicks word M (M ≤ N) where comprehension was last solid
5. Reader hits Space; stream resumes at word M, recovery_wpm, re-ramping to session target
**Postcondition:** position = M at resume; stop recorded (count, N−M span) in run record

### UC-002: Quiz cycle (opt-in)
**Precondition:** Quiz opt-in ON; Ollama reachable
**Main Flow:**
1. Text loads → hash computed → log checked: existing quiz? reuse : SR_QUIZ_JOB submitted
2. While reader previews questions (SQ3R) / tunes settings, worker streams validated questions in
3. Reader reads (UC-001); finishes
4. Cockpit offers the quiz; reader answers; score computed
**Postcondition:** run record carries quiz score; questions+answers persisted under text hash

### UC-003: Intake + preprocess
**Main Flow:** paste or open .txt/.md → (opt-in) SR_CLEAN_JOB → diff view (simple_diff) →
accept/reject → tokenize → ready
**Postcondition:** SR_TEXT with tokens, structure, hash

### UC-004: Drill session (secondary)
**Main Flow:** pick difficulty → cached/generated drill text → UC-001 + UC-002 on it → log tagged drill

### UC-005: Review history
**Main Flow:** cockpit history panel → per-run rows + WPM/score trend chart
