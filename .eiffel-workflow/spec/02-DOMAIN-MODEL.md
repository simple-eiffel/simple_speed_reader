# DOMAIN MODEL: simple_speed_reader

**Date:** 2026-08-26

## Domain Concepts

### Concept: Text
**Definition:** A work the reader chose — raw source, optionally AI-cleaned, tokenized, identified by content hash.
**Attributes:** title, raw source, clean source, tokens, paragraph/sentence structure, hash, word count
**Behaviors:** none (value); produced by intake + tokenizer
**Related to:** Token (has-many), Quiz (identified-by-hash), Run (read-in)
**Will become:** `SR_TEXT`

### Concept: Token
**Definition:** One streamable word with its display and timing metadata.
**Attributes:** word (STRING_32), pivot index (ORP, combining-mark-aware), sentence index,
paragraph index, flags (ends_sentence, ends_paragraph, has_clause_break), source offset,
script (latin/hebrew/greek/other/numeric), has_diacritics, is_numeric, is_acronym,
is_foreign_term (AI-enrichable for bare-ASCII transliterations)
**Behaviors:** none (immutable value; enrichment produces an upgraded copy)
**Will become:** `SR_TOKEN`

### Concept: Tokenizer
**Definition:** The rule that turns clean text into the token stream and its structure.
**Behaviors:** tokenize (text → tokens + sentence/paragraph map); single place ORP + flags are computed
**Will become:** `SR_TOKENIZER`

### Concept: Pace (Governor)
**Definition:** The speed law of a session: where speed is now, where it is climbing to, what it may never exceed.
**Attributes:** start_wpm, recovery_wpm, current_wpm, target_wpm (session), comfy_max_wpm (profile), is_held
**Behaviors:** ramp advance per word; hold/release; back_off (25/50/100); reset_for_recovery
**Will become:** `SR_GOVERNOR`

### Concept: Timing Model
**Definition:** How long one token owns the stage at a given WPM, and the blank breathers after it.
**Behaviors:** display_ms (token, wpm); breather_ms (token, wpm) — pure functions
**Will become:** `SR_TIMING_MODEL`

### Concept: Pacer
**Definition:** The deadline scheduler binding wall-clock ticks to token advances.
**Attributes:** next_deadline_ms, carry (accumulated error)
**Behaviors:** on_tick (now_ms): zero or more advances; never drifts (remainder carried)
**Will become:** `SR_PACER`

### Concept: Session
**Definition:** One sitting with one text: the state machine (stopped → running ⇄ paused → stopped),
the position, the record of what happened. PAUSE keeps the sitting alive (context page, drawered
controls); STOP seals it (record logged, position autosaved). Reaching the end seals too.
**Attributes:** text, position (token index), state, governor, stop events, per-word timestamps,
streamed/skipped counts
**Behaviors:** start, pause (to context), resume_at (index), advance (honors the foreign-skip
presentation filter), stop_and_seal
**Will become:** `SR_SESSION`

### Concept: Recovery Point
**Definition:** The reader-designated token where comprehension was last solid; where resume begins.
**Attributes:** token index (≤ stop index); default = first token of the stopped sentence
**Enforced by:** SR_SESSION.resume_at precondition

### Concept: Run Record
**Definition:** The honest account of one session: dialed vs achieved vs retained.
**Attributes:** date, text hash/title, words read, nominal avg/max WPM, effective WPM, stop count,
back-off count, quiz score (detachable), is_drill
**Will become:** `SR_RUN_RECORD`

### Concept: Quiz / Question
**Definition:** Comprehension test generated from the text BEFORE reading; questions previewable
(SQ3R); answers quote-anchored in the text.
**Attributes:** Question: prompt, expected answer, supporting quote, verified flag, user answer, is_correct
**Behaviors:** Quiz: score; Question: judge (user answer → correct?)
**Will become:** `SR_QUIZ`, `SR_QUIZ_QUESTION`

### Concept: Quiz Validator
**Definition:** The anti-hallucination gate: a question survives only if its supporting quote occurs
verbatim (whitespace-normalized) in the text.
**Will become:** `SR_QUIZ_VALIDATOR`

### Concept: AI Gateway
**Definition:** The only door to the local model. A separate processor owning the synchronous
OLLAMA_CLIENT (curl-based, blocking — verified 2026-08-26); jobs go in, results appear in a mailbox.
**Behaviors:** submit (job); probe availability; work loop
**Will become:** `SR_AI_GATEWAY` (separate), `SR_MAILBOX` (separate), `SR_AI_JOB` (deferred) with
`SR_CLEAN_JOB`, `SR_QUIZ_JOB`, `SR_DRILL_JOB`

### Concept: Reading Log
**Definition:** Persistent memory: texts, quizzes (by hash), run records, resume positions.
**Will become:** `SR_LOG` (simple_sql/SQLite)

### Concept: Settings
**Definition:** The profile: font family/size, start/recovery/comfy-max WPM, Ollama URL + model,
opt-ins (preprocess, quiz), last text + position (autosave).
**Will become:** `SR_SETTINGS` (simple_config)

### Concept: Stage / Context Page / Flow Map / Cockpit (presentation)
**Definition:** Stage = the RSVP frame (word, red pivot pinned at fixed X, ticks, WPM readout).
Context page = the readable regression surface with word hit-testing. Flow map = whole-text
miniature with live cursor; scrubber when paused. Cockpit = every control, visible only outside RUNNING.
**Will become:** `SR_STAGE_VIEW`, `SR_CONTEXT_VIEW`, `SR_FLOW_MAP_VIEW`, `SR_COCKPIT` (app target),
composed over SW_CANVAS / stock simple_widgets; `SR_APP` owns the two-state switch; `SR_KEYS` the keymap.

## Concept Relationships

```
SR_TEXT ──── has-many ───> SR_TOKEN
SR_TEXT ──── identified-by ───> hash (simple_hash)
SR_SESSION ─── reads ───> SR_TEXT
SR_SESSION ─── governed-by ───> SR_GOVERNOR
SR_SESSION ─── paced-by ───> SR_PACER ─── consults ───> SR_TIMING_MODEL
SR_SESSION ─── yields ───> SR_RUN_RECORD ─── persisted-in ───> SR_LOG
SR_QUIZ ──── has-many ───> SR_QUIZ_QUESTION (each verified-by SR_QUIZ_VALIDATOR)
SR_QUIZ ──── keyed-by ───> SR_TEXT.hash ─── stored-in ───> SR_LOG
SR_AI_GATEWAY ─── executes ───> SR_AI_JOB (is-a: CLEAN | QUIZ | DRILL)
SR_AI_GATEWAY ─── posts-to ───> SR_MAILBOX <─── polled-by ─── SR_APP tick
SIMPLE_SPEED_READER (facade) ─── coordinates ───> {SR_TEXT, SR_SESSION, SR_GOVERNOR, SR_AI_GATEWAY, SR_LOG, SR_SETTINGS}
SR_APP (GUI) ─── drives ───> SIMPLE_SPEED_READER  (GUI is a view; engine is headless-testable)
```

## Domain Rules

| Rule | Description | Enforcement |
|------|-------------|-------------|
| DR-001 | Pivot index always inside its word: `1 <= pivot_index <= word.count` | SR_TOKEN invariant |
| DR-002 | Speed order: `Min_wpm <= current_wpm <= target_wpm <= comfy_max_wpm` | SR_GOVERNOR invariant |
| DR-003 | Recovery point never after the stop point | SR_SESSION.resume_at precondition |
| DR-004 | Resume always re-ramps: after resume_at, `current_wpm = recovery_wpm` | SR_SESSION.resume_at postcondition |
| DR-005 | A surviving quiz question is quote-verified | SR_QUIZ invariant (all questions verified) |
| DR-006 | Quiz administered only after reading completed, generated only before | SR_SESSION state preconditions |
| DR-007 | RUNNING shows only the stream | SR_APP layout invariant (stage+map only when running) |
| DR-008 | Every advance is timestamped (effective WPM computable) | SR_SESSION.advance postcondition |
| DR-009 | UI never calls the gateway synchronously except probe/submit (bounded); results only via mailbox | SR_AI_GATEWAY interface design |
| DR-010 | Display durations strictly positive | SR_TIMING_MODEL postconditions |

## Glossary

| Term | Definition |
|------|------------|
| RSVP | Rapid Serial Visual Presentation — words shown one at a time at a fixed point |
| ORP / pivot | Optimal Recognition Point — the letter (~1/3 in, red) pinned at fixed screen X |
| WPM (nominal) | The dialed words-per-minute rate |
| WPM (effective) | words ÷ wall time actually elapsed, breathers and stops included |
| Breather | Blank stage time after clause/sentence/paragraph (video's blank frames) |
| Comfy-max | The user's persisted ceiling speed (default 900) |
| Hold | Pin the ramp: target := current until released |
| Back-off | Immediate target reduction by 25/50/100 WPM |
| Recovery point | Reader-marked token where comprehension was last solid |
| Context page | Readable paragraph view shown on stop — the regression surface |
| Flow map | Unreadable whole-text miniature with live word cursor (left edge) |
| SQ3R | Survey-Question-Read-Recite-Review (Robinson 1941); quiz preview = S+Q |
| Drill | Secondary mode: AI-generated graded practice text |
| Paused | Mid-sitting halt: context page shown, controls drawered, sitting still live |
| Stopped | Session boundary: sitting sealed (record logged, position saved), full cockpit shown |
| Drawer | Titled slide-in panel (SW_DRAWER) carrying controls in the paused posture |
| Foreign skip | Opt-in stream filter: non-Latin-script tokens not streamed (transliterations kept); text itself untouched |
| Linger class | Token property raising display time: length band, foreign script, diacritics, numeric, acronym (cap ×3) |
