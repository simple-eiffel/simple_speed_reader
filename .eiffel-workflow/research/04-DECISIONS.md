# DECISIONS: simple_speed_reader

**Date:** 2026-08-26

## Decision Log

### D-001: Product identity — reader first, drill second
**Question:** Is this a training drill (the video's filename) or a reading tool?
**Options:**
1. Trainer identity: sessions are exercises, texts are practice material
2. Reader identity: user reads real texts; drill is one optional mode
**Decision:** Reader identity (Larry, explicitly: "This is not about 'drilling' but about actually reading").
**Rationale:** The recovery loop, quiz pipeline, and log all serve real reading; a trainer framing would misprioritize them.
**Implications:** Intake of real texts (incl. simple_ocr_capture .md output) is first-class; drill mode is FR-029, SHOULD.
**Reversible:** NO (identity decision)

### D-002: Two-state GUI — running is chrome-free
**Question:** Where do controls live relative to the stream?
**Decision:** Two states. RUNNING = only the word-stream (stage + left flow map + WPM readout);
zero interactive widgets. PAUSED/STOPPED = the cockpit: text intake, settings, speed buttons,
quiz, history. While running, control is keyboard-first.
**Rationale:** Larry, 2026-08-26: "The GUI ought to be ONLY the word-stream when the word-stream
is active and running. All else is in a pause or stop mode." RSVP demands total visual focus; any
chrome is competition for the single fixation point.
**Implications:** SW_CANVAS stage fills the window while running; keyboard map is a core deliverable;
back-off/hold have both key bindings (running) and buttons (paused). The flow map is interpreted as
part of the stream (Larry specified its cursor "marks each word as it flows") — confirm at intent phase.
**Reversible:** YES (layout), but treat as settled.

### D-003: Recovery loop mechanics
**Question:** How does "back up to a last-comprehended point" actually work — the app cannot know where comprehension died.
**Options:**
1. Fixed rewind (N words / one paragraph): fast but usually wrong
2. Scrub bar: precise but fiddly, breaks flow
3. Context page: on stop, show surrounding paragraphs as normal readable text with the stopped word marked; user clicks the word where they were last solid; resume from there
**Decision:** Option 3, with option 1 as the zero-click default (quick resume = start of current
sentence). Resume always re-ramps: recovery WPM (default 250) climbing back to session max.
**Rationale:** Only the reader knows the point of last comprehension; a readable context page IS the
regression that Schotter et al. 2014 showed RSVP fatally lacks. The zero-click default keeps the
common case (brief distraction) at two keypresses.
**Implications:** Stage widget needs a second rendering mode (flowed readable paragraphs with
word-level hit testing). Word positions from cairo extents make click→word index direct.
**Reversible:** YES (defaults tunable)

### D-004: Ramp and governance model
**Question:** How does speed evolve during a session?
**Decision:**
- Session begins at start_wpm (default 250, range 200–300) and ramps toward target max_wpm
  (default 900, user's "comfy max" persisted per user)
- Ramp is linear in words: +ramp_step every ramp_interval words (defaults sized so 250→900 takes
  ~3–4 minutes of reading; tunable)
- HOLD pins the target at current WPM (toggle; ramp resumes on release)
- Back-off −100/−50/−25 lowers the current target immediately (does not change stored comfy-max)
- After every recovery resume, ramp restarts from recovery_wpm toward the (possibly held/backed-off) target
**Rationale:** Matches the video (300→803 observed, re-drop to 300 at a segment break); back-offs and
hold are Larry's explicit controls; separating session target from stored comfy-max means one bad
day doesn't rewrite the profile.
**Implications:** A SPEED_GOVERNOR class owning {start, target, held?, current} with contracts
(e.g., `current_wpm <= target_wpm`, `target_wpm <= comfy_max`).
**Reversible:** YES (curve shape tunable; consider logistic later)

### D-005: Timing model (per-word duration)
**Decision:** base_ms = 60000/current_wpm, then modulated: long words (>8 chars) ×~1.3; comma/semicolon
+1 beat; sentence end +2 beats; paragraph break +3 beats (a beat = one base_ms). Blank frame during
breathers, as in the video.
**Rationale:** "Smart pausing" is standard in the better comparables (chislerr, Spritz); the video
shows blank sentence gaps. Displayed WPM remains the nominal rate; log records effective rate.
**Reversible:** YES (constants in one place, contract-checked positive)

### D-006: ORP (pivot) heuristic
**Decision:** Pivot index by word length, Spritz-convention (~35%, left of center): 1 char→1st;
2–4→2nd; 5–9→3rd; 10+→4th. Pivot glyph drawn accent-red at fixed stage X; prefix measured via
cairo x_advance so the pivot lands exactly on the pin; tick marks above/below the pin.
**Rationale:** Matches the video frames (reading→'a' 3rd char; But→'u' 2nd; narrowing→'r' 3rd;
inner→'n' 2nd... wait, video shows inner→2nd 'n' = 3rd char — heuristic table reproduces observed frames).
**Implications:** Needs per-prefix text measurement each word — one text_extents call per word at
display time, trivial cost.
**Reversible:** YES

### D-007: AI architecture — local Ollama, pre-generated, non-blocking, optional
**Decision:** simple_ai_client OLLAMA_CLIENT with configurable base URL (default the standard 11434,
Larry's profile set to 11435). Three AI jobs: (1) preprocessor cleanup, (2) quiz generation
(BEFORE reading — Larry explicit), (3) drill-text generation. All run in a SCOOP separate worker;
UI never blocks. Quiz answers must be text-anchored (prompt requires supporting quotes; app verifies
the quote occurs in the text, else the question is dropped). With no Ollama reachable: reader fully
functional, AI affordances disabled with a status line.
**Rationale:** Larry: "developed BEFORE on any random text"; privacy/cost/offline; anchored-quote
validation is the anti-hallucination gate.
**Implications:** Quiz generation happens while the user is in the stopped state (loading/previewing);
progress shown; user may start reading without waiting — quiz simply arms when ready (still before
its administration).
**Reversible:** Model choice YES; local-only NO (product stance).

### D-008: Persistence
**Decision:** simple_sql (SQLite) for the reading log (runs, speed profiles, stops/rewinds, quiz
results, per-text records incl. generated quizzes); simple_config for settings (fonts, speeds,
comfy-max, Ollama URL, opt-ins).
**Rationale:** Ecosystem standard (oracle itself runs on simple_sql); quiz reuse requires storing
generated Q&A with a text hash.
**Reversible:** YES

### D-009: UI stack and cadence source
**Decision:** simple_widgets throughout: SW_WINDOW (dark theme) + SW_CANVAS for stage/flow map/context
page + stock widgets for the paused cockpit. Cadence: arm the simple_shell fast tick (~10–15 ms);
each tick compares tick_ms against the current word's deadline (deadline scheduler — tick granularity
bounds jitter, not cadence).
**Rationale:** Larry specified simple_widgets; fast tick verified at shell_window.e:94; deadline
scheduling keeps 66 ms words honest at 900 WPM (NFR-001).
**Reversible:** NO (ecosystem mandate)

### D-010: Name
**Decision:** simple_speed_reader (Larry picked from candidates incl. simple_rsvp, simple_read_drill).
**Reversible:** NO once repo published.

### D-011: Adaptive word-presentation time (2026-08-26, Larry's throttling question)
**Question:** Should display time vary with word size (chars/syllables) and language?
**Decision:**
- Length: graduated character-count multiplier (1–5→×1.0, 6–8→×1.1, 9–11→×1.3, 12+→×1.5) —
  replaces the single >8-chars cliff. **Syllables rejected**: they add little beyond chars
  (strong correlation), matter mainly for subvocalization (which RSVP suppresses), and syllable
  heuristics fail exactly on foreign/transliterated words.
- Script: tokens in non-Latin scripts (Hebrew U+0590–05FF incl. niqqud, Greek U+0370–03FF and
  polytonic U+1F00–1FFF) detected deterministically in the tokenizer → linger ×~2.5 AND an
  effective-WPM floor (display as if ≤350 WPM regardless of dial).
- Transliterations with diacritics (agapē, ḥesed): extended-Latin diacritic code points → ×~1.6.
- Numerics (digits: 1,234 · Gen 1:3 · H7225) → ×~1.8. Acronyms/all-caps (LXX, MT, YHWH) → ×~1.4.
- Stacked multiplier capped at ×3.0.
- Display rule for foreign-script tokens: rendered centered, whole-word, NO red pivot — ORP
  research is Latin-specific, Hebrew is RTL, and a pivot index could land on a combining mark.
  Corollary contract: pivot indexing skips combining marks in every script.
- Bare-ASCII transliterations (bereshit): undetectable by rule → optional AI enrichment pass
  (same SR_AI_JOB family) tags foreign terms; without AI the deterministic 90% stands.
- Phase 2 upgrade path: static word-frequency (Zipf) list — the strongest predictor of
  time-on-word in eye-tracking literature (rarity-aware linger).
**Rationale:** Larry's corpus is English theology laced with Hebrew/Greek/transliterations/Strong's
refs; frequency > length > syllables per fixation research (Rayner).
**Implications:** SR_TOKEN gains script/has_diacritics/is_numeric/is_acronym (computed in
SR_TOKenizer — Single Choice); SR_TIMING_MODEL consumes them; SR_STAGE_VIEW branches on script.
**Reversible:** YES (constants and classes tunable; structure additive)

### D-012: Three GUI states — running / paused (drawered) / stopped (full cockpit)
**Question:** Larry 2026-08-26: pause affordance always present; paused controls as drawers;
stopped un-drawers everything. Refines D-002's two-state model.
**Decision:** Three postures:
1. **RUNNING** — the stream (stage + flow map + WPM) plus ONE dim pause affordance; the whole
   stage is also a pause hit-target. Otherwise zero chrome; keyboard-first stands.
2. **PAUSED** (mid-sitting) — context page + live flow-map scrubber, controls present but
   **drawered**: titled SW_DRAWER panels (Speed, Quiz preview, Settings) summoned via
   window.show_drawer from slim edge tabs. Focus stays on getting back into the text.
3. **STOPPED** (session boundary) — full cockpit deployed: intake, settings, quiz
   administration, history, "Continue at word N" when a position is saved.
**Semantics:** Pause (Space / stage click / pause affordance) keeps the sitting alive. Stop (Esc,
or cockpit action) SEALS the sitting: run record logged, position autosaved (FR-032). Reaching
the text's end seals and lands in STOPPED with the quiz offer.
**Implications:** SR_SESSION states become stopped/running/paused (+ sealed records per sitting);
DR-007 amended (one dim pause affordance allowed in RUNNING); SR_APP owns three layouts;
SW_DRAWER (verified present) carries the paused-state controls.
**Reversible:** YES (posture composition), state semantics settled.

### D-013: Foreign-script skip filter (2026-08-26, Larry)
**Question:** "A feature that turns off presentation of all non-English except for transliterations?"
**Decision:** Opt-in stream filter (default OFF): when ON, tokens whose script is not Latin are
skipped by the stream — never displayed, no display time. Transliterations are Latin-script and
therefore kept automatically (no extra classification needed; the predicate is `script /= latin`).
**Boundaries:** The filter affects PRESENTATION ONLY. The context page and flow map always show
the full true text (skipped tokens dimmed in the map); the text model is never mutated. The log
records streamed vs skipped counts so effective WPM stays honest.
**Rationale:** In academic theology text the glyph is usually adjacent to its transliteration or
gloss; streaming Hebrew/Greek glyphs can be pure friction. When the glyph IS load-bearing, the
reader has the context page one keypress away.
**Implications:** SR_SESSION.advance consults a presentation predicate; SR_RUN_RECORD gains
skipped_count; a settings switch (with_foreign_skip) + cockpit/Speed-drawer toggle.
**Reversible:** YES

### D-014: Transport conventions (2026-08-26, Larry's key-combo question)
**Question:** What are the standard Play/Pause/Stop/Rewind/Forward/Skip keys and state behaviors?
**Decision:** Adopt media-player muscle memory (YouTube/VLC/podcast apps) with the sentence as our
seek unit: Space/K play-pause toggle · Esc/S stop · Left/Right sentence rewind/forward
(Ctrl+ = paragraph) · Up/Down and ,/. speed ∓25 · Home resume-point to start · hardware media
keys mirror Space/Esc. Ours on top: H hold, 1/2/3 back-off 100/50/25.
**Two deliberate deviations from media convention, both comprehension-driven:**
(1) Resume after pause restarts at recovery WPM and re-ramps (players resume at speed; D-003);
the in-flow **micro-rewind** (Left while running: replay from previous sentence start, stream
keeps flowing, speed unchanged) is the light-touch middle for momentary lapses.
(2) Stop preserves position (audiobook convention), never resets to start (VLC convention).
**Implications:** SR_SESSION gains replay_sentence / skip_sentence_forward; forward skips log
skipped words (honesty); full keymap table in spec/06-INTERFACE-DESIGN.md.
**Reversible:** YES (bindings), semantics settled.

### D-015: Fisheye ribbon in the PAUSED posture (2026-08-26, Larry)
**Question:** Larry sketched a where-am-I strip: words (not letters) on one line, tiny at the
left edge growing to the biggest center-current-word, then tapering smaller to the right —
"a word-cloud thing except in a straight line of a sentence or sentence fragment."
**Decision:** Add SR_RIBBON_VIEW to the paused posture, ABOVE the context page: a one-line
focus+context (fisheye) strip of the real surrounding words, centered on the current word.
- Sizing: geometric falloff by word distance d from center — scale(d) = max(0.24, 0.72^|d|)
  of the center size (center ≈ 2× context-page body); span = as many whole words as fit the
  width, drawn from the surrounding sentences.
- Left of center = already-streamed words (normal brightness), right = upcoming (dimmer);
  center word brightest with a small red tick echoing the stage pin (no ORP pivot — the ribbon
  is about position, not recognition).
- Interaction: click any ribbon word → sets the resume point (same command path as the context
  page click). Hover-magnify (dock effect) deferred — SHOULD, not MVP.
- PAUSED only. RUNNING stays chrome-free (D-012); the running-state position sense remains the
  flow map.
**Rationale:** The context page answers "what did it say?"; the ribbon answers "where am I in
the flow?" in a single glance without reading. Classic Furnas fisheye / focus+context.
**Implications:** New app class SR_RIBBON_VIEW (SW_CANVAS painter; reuses facade
context_window (radius) — no engine change); app classes 6→7, total 27.
**Reversible:** YES

### D-016: Analog BRAKING control (2026-08-26, Larry)
**Question:** Larry: a "braking" control — hold to ease the flow down from present speed to 300
while the fisheye ribbon flows in sync; release → gentle ramp back to the speed you were reading
at. While holding: mouse LEFT = full-brake to stop and rewind a little; mouse RIGHT = re-engage
flow ramping to 300; release = resume ramp to full comfy speed.
**Decision:** Braking is a transient overlay on RUNNING (not a posture change):
- **Hold** (stage press-and-hold, dim brake affordance, or key B held): current_wpm eases
  from pre_brake_wpm down toward Brake_floor (300, floored at Min_wpm) over ~1.5 s — a
  deceleration glide, not a jump. The fisheye ribbon fades in over the running stage and flows
  live, centered on the streaming word, at the same slowing rate — context without stopping.
- **Drag while held:** left of press origin → decelerate to full stop, further leftward drag
  scrubs position backward through the ribbon (rate ∝ drag distance); drag right → forward flow
  re-engages, ramping to Brake_floor.
- **Release:** speed eases back up to pre_brake_wpm, then the normal governance resumes
  (prior hold state restored; ramp law continues toward the session target).
- Stage QUICK-TAP (press-release, no drag, < ~250 ms) still = Pause (FR-034 refined);
  hold = brake. Keyboard: Space pause, B-held brake.
- Words re-streamed after a brake-scrub are simply re-streamed (timestamps make effective WPM
  honest); a brake event (depth, scrub span) joins the run record.
**Rationale:** Completes the graduated intervention ladder: Left-tap micro-rewind (lapse) →
BRAKE (wobble — slow down, see context, maybe nudge back, never leave the stream) → Pause
(comprehension loss — context page + marked recovery) → Stop (end sitting). Analog control over
an analog problem.
**Implications:** SR_GOVERNOR gains brake state (is_braking, pre_brake_wpm, eased glide;
invariant: braking implies current_wpm >= Min_wpm and glide monotone toward floor);
SR_SESSION gains scrub_back (running, position decreases, no posture change);
SR_RIBBON_VIEW rides both PAUSED and the braking overlay; SR_APP press/drag/release routing.
**Reversible:** YES (curve constants, gesture thresholds); the ladder concept is settled.

## Open Questions (for /eiffel.intent)
- OQ-1: Flow map during RUNNING — confirmed in? (D-002 says yes; confirm with Larry)
- OQ-2: Recovery WPM — fixed 250 or proportional to session max (e.g., max/3)?
- OQ-3: Quiz size — questions per 1000 words? (default proposal: 3 per ~800 words, cap 10)
- OQ-4: Does the pre-read preview show questions only, or also an AI outline (fuller SQ3R survey)?
- OQ-5: Which local model default (qwen-class on Larry's GPU)? Needs a bake-off on real OCR text.
