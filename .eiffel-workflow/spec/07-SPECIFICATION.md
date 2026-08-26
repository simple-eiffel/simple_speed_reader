# SPECIFICATION: simple_speed_reader

**Date:** 2026-08-26

## Overview

Windows desktop RSVP reader (simple_widgets, dark-only): video-parity stage with fixed red ORP
pivot; speed ramps to a persisted comfy-max (default 900 WPM) under hold/back-off governance;
one-key recovery to a reader-marked comprehension point with re-ramp; local-AI (Ollama)
preprocessing and quote-verified comprehension quizzes generated before reading (SQ3R preview);
honest speed+comprehension log in SQLite. Engine is headless-testable; GUI is a view.

## Class Specifications (core; full contract detail in 05-CONTRACT-DESIGN.md)

### SR_TOKEN (immutable value)

```eiffel
note
    description: "One streamable word: text, ORP pivot, structure flags, timing hints"
    author: "Larry Rix"

class
    SR_TOKEN

create
    make

feature {NONE} -- Initialization

    make (a_word: READABLE_STRING_32; a_sentence, a_paragraph, a_source_start: INTEGER;
          a_ends_sentence, a_ends_paragraph, a_has_clause_break: BOOLEAN)
            -- One tokenized word with its place in the text's structure.
        require
            word_not_empty: not a_word.is_empty
            positive_sentence: a_sentence >= 1
            positive_paragraph: a_paragraph >= 1
            positive_source: a_source_start >= 1
            paragraph_closes_sentence: a_ends_paragraph implies a_ends_sentence
        do
            create word.make_from_string_general (a_word)
            sentence_index := a_sentence
            paragraph_index := a_paragraph
            source_start := a_source_start
            ends_sentence := a_ends_sentence
            ends_paragraph := a_ends_paragraph
            has_clause_break := a_has_clause_break
            pivot_index := pivot_for_length (word.count)
        ensure
            word_kept: word.same_string_general (a_word)
            pivot_lawful: pivot_index = pivot_for_length (word.count)
        end

feature -- Access

    word: STRING_32
    pivot_index: INTEGER
            -- ORP: the letter pinned (red) at the stage's fixed X.
            -- Combining-mark-aware; meaningful for Latin script only (D-011).
    sentence_index, paragraph_index, source_start: INTEGER
    ends_sentence, ends_paragraph, has_clause_break: BOOLEAN

feature -- Classification (D-011/D-013; computed at creation, AI-enrichable)

    script: INTEGER
            -- One of Script_latin | Script_hebrew | Script_greek | Script_other,
            -- from Unicode blocks (Hebrew U+0590-05FF, Greek U+0370-03FF, U+1F00-1FFF).
    is_latin, is_foreign_script: BOOLEAN
    has_diacritics: BOOLEAN
            -- Extended-Latin diacritics (agapē, ḥesed) → transliteration linger.
    is_numeric, is_acronym: BOOLEAN
            -- Digits (Gen 1:3, H7225) · all-caps len>=2 (LXX, MT, YHWH).
    is_foreign_term: BOOLEAN
            -- AI-enriched: bare-ASCII transliteration (bereshit). Default False.

    streams_under_filter (a_skip_foreign: BOOLEAN): BOOLEAN
            -- D-013: foreign-skip keeps Latin (transliterations included).
        do
            Result := is_latin or not a_skip_foreign
        ensure
            latin_always: is_latin implies Result
        end

feature -- The ORP law (Single Choice: the only place this rule exists)

    pivot_for_length (a_count: INTEGER): INTEGER
            -- Spritz-convention pivot: 1→1, 2-4→2, 5-9→3, 10+→4.
        require
            positive: a_count >= 1
        do
            if a_count = 1 then Result := 1
            elseif a_count <= 4 then Result := 2
            elseif a_count <= 9 then Result := 3
            else Result := 4
            end
        ensure
            inside: Result >= 1 and Result <= a_count
        end

invariant
    word_present: not word.is_empty
    pivot_inside: pivot_index >= 1 and pivot_index <= word.count
    paragraph_end_is_sentence_end: ends_paragraph implies ends_sentence

end
```

### SR_GOVERNOR (the speed law)

```eiffel
note
    description: "Session speed governance: ramp toward target, hold, back-off, recovery re-ramp"

class
    SR_GOVERNOR

create
    make

feature {NONE} -- Initialization

    make (a_start, a_recovery, a_comfy_max: INTEGER)
        require
            floor: a_start >= Min_wpm and a_recovery >= Min_wpm
            order: a_start <= a_comfy_max and a_recovery <= a_comfy_max
            ceiling: a_comfy_max <= Max_wpm
        do
            start_wpm := a_start; recovery_wpm := a_recovery
            comfy_max_wpm := a_comfy_max
            current_wpm := a_start; target_wpm := a_comfy_max
            session_target := a_comfy_max
        ensure
            starts_at_start: current_wpm = a_start
            aiming_at_comfy: target_wpm = a_comfy_max
        end

feature -- Access

    current_wpm, target_wpm, comfy_max_wpm: INTEGER
    start_wpm, recovery_wpm: INTEGER
    is_held: BOOLEAN

feature -- Constants

    Min_wpm: INTEGER = 100
    Max_wpm: INTEGER = 1500
    Ramp_step: INTEGER = 25
    Ramp_interval_words: INTEGER = 12
            -- +25 WPM per 12 words: 250→900 in ~312 words (~1.5 min at mid-speeds).

feature -- Commands

    note_word_advanced
            -- One word consumed; climb if a ramp interval completed.
        do ... end
        -- ensure: see 05-CONTRACT-DESIGN (monotone_up, target/comfy frames)

    hold ... release_hold ... back_off (a_amount: INTEGER) ...
    reset_for_recovery ... set_comfy_max (a_wpm: INTEGER) ...
        -- contracts as specified in 05-CONTRACT-DESIGN.md verbatim

invariant
    floor: Min_wpm <= current_wpm
    order: current_wpm <= target_wpm
    ceiling: target_wpm <= comfy_max_wpm
    held_pins: is_held implies current_wpm = target_wpm

end
```

### SR_TIMING_MODEL (pure service)

```eiffel
note
    description: "How long a token owns the stage, and the breather after it (video's blank frames)"

class
    SR_TIMING_MODEL

feature -- Queries (all pure)

    display_ms (a_token: SR_TOKEN; a_wpm: INTEGER): INTEGER
            -- Base 60000/wpm × graduated length band (1-5:×1.0, 6-8:×1.1,
            -- 9-11:×1.3, 12+:×1.5) × linger classes: foreign script ×2.5
            -- with effective floor base(350); diacritics ×1.6; numeric ×1.8;
            -- acronym ×1.4. Stack capped at ×3.0. (D-011/FR-037)
        require
            speed_lawful: a_wpm >= {SR_GOVERNOR}.Min_wpm
        ensure
            positive: Result > 0
            capped: Result <= 3 * (60000 // a_wpm).max (60000 // Foreign_ceiling_wpm)

    breather_ms (a_token: SR_TOKEN; a_wpm: INTEGER): INTEGER
            -- 0 plain · 1 beat clause · 2 beats sentence · 3 beats paragraph (beat = base ms).
        require
            speed_lawful: a_wpm >= {SR_GOVERNOR}.Min_wpm
        ensure
            non_negative: Result >= 0
            plain_flows: (not a_token.ends_sentence and not a_token.has_clause_break
                and not a_token.ends_paragraph) implies Result = 0

feature -- Constants

    Foreign_ceiling_wpm: INTEGER = 350
            -- A foreign-script word displays as if the dial read at most this.

end
```

### SR_SESSION (state machine — signatures; contracts in 05)

```eiffel
class SR_SESSION
create make_with_text
feature -- States (exactly one; D-012)
    is_stopped, is_running, is_paused: BOOLEAN
    is_sealed: BOOLEAN              -- sitting ended: record logged, position kept
feature -- Access
    text: SR_TEXT
    position: INTEGER               -- token index on stage (0 before start)
    governor: SR_GOVERNOR
    pause_count, skipped_count, streamed_count: INTEGER
    rewind_spans: ARRAYED_LIST [INTEGER]
    effective_wpm: INTEGER          -- streamed words ÷ wall time, breathers included
    skip_foreign: BOOLEAN           -- D-013 presentation filter
feature -- Commands (transport semantics, D-014)
    start_reading                    -- stopped → running
    pause_reading                    -- running → paused (context page; sitting alive)
    resume_at (a_index: INTEGER)     -- paused → running at recovery WPM (re-ramp)
    resume_at_sentence_start
    replay_sentence                  -- RUNNING micro-rewind: no posture change, speed kept
    skip_sentence_forward            -- RUNNING skip: words logged skipped
    advance (a_now_ms: NATURAL_32)   -- honors skip_foreign; auto-seals at text end
    stop_and_seal                    -- running|paused → stopped; record logged; position KEPT
feature -- Sealed outcome
    last_record: detachable SR_RUN_RECORD
invariant
    one_state: -- exactly one of stopped/running/paused
    sealed_is_stopped: is_sealed implies is_stopped
    position_in_text: position >= 0 and position <= text.token_count
end
```

### SR_QUIZ_QUESTION / SR_QUIZ

```eiffel
class SR_QUIZ_QUESTION
create make
feature -- Access
    prompt, expected_answer, supporting_quote: STRING_32
    is_verified: BOOLEAN            -- quote found verbatim (normalized) in the text
    user_answer: detachable STRING_32
    is_judged, is_correct: BOOLEAN
feature -- Commands
    record_answer (a_answer: READABLE_STRING_32; a_correct: BOOLEAN)
invariant
    has_prompt: not prompt.is_empty
    has_quote: not supporting_quote.is_empty
    judged_only_answered: is_judged implies user_answer /= Void
end

class SR_QUIZ
create make_from_validated
feature
    text_hash: STRING_8
    questions: ARRAYED_LIST [SR_QUIZ_QUESTION]
    dropped_count: INTEGER          -- honesty: how many the validator rejected
    is_administered: BOOLEAN
    score_percent: INTEGER
invariant
    all_verified: across questions as q all q.is_verified end
end
```

### SR_AI_GATEWAY (separate) — the only blocking region

```eiffel
class SR_AI_GATEWAY
create make
feature
    submit (a_job: SR_AI_JOB)           -- non-blocking enqueue (called cross-region)
    is_available: BOOLEAN               -- OLLAMA_CLIENT.is_available probe (bounded, cached)
    work_once                            -- take job → execute_chat (BLOCKING curl) → parse → mailbox.put
end
-- SR_MAILBOX (separate): put (SR_AI_RESULT) / take: detachable SR_AI_RESULT — handoff only.
-- SR_AI_JOB (deferred): prompt: STRING_32; parse (a_raw: STRING_32): SR_AI_RESULT; describe: STRING_32
--   effected by SR_CLEAN_JOB · SR_QUIZ_JOB (chunk_index, of_chunks) · SR_DRILL_JOB (level)
```

### SIMPLE_SPEED_READER (facade — full signature set in 06-INTERFACE-DESIGN.md)

```eiffel
note
    description: "RSVP speed reader engine: intake, pacing, recovery, quiz, log. Headless; GUI is a view."
class
    SIMPLE_SPEED_READER
create
    make
feature -- Configuration (fluent)
    with_font, with_speeds, with_ollama, with_quiz_opt_in, with_clean_opt_in,
    with_foreign_skip: like Current
feature -- Intake
    load_text, load_file, request_clean, accept_clean, reject_clean
feature -- Reading loop (transport semantics, D-014)
    start_reading, pause_reading, resume_at, resume_at_sentence_start,
    replay_sentence, skip_sentence_forward, tick, stop_and_seal,
    hold, release_hold, back_off, set_comfy_max
feature -- Quiz
    request_quiz, quiz_ready, quiz, answer_question, quiz_score
feature -- Status
    has_text, is_running, is_paused, is_done, current_token, position, token_count,
    current_wpm, target_wpm, effective_wpm, context_window, flow_blocks,
    ai_available, ai_status_line, run_records
invariant
    running_has_text: is_running implies has_text
end
```

### App target classes (GUI; thin, agent-wired)

- `SR_APP` — SW_WINDOW (make_dark theme) + three-posture switch (D-012): RUNNING → stage + flow
  map + WPM + dim pause affordance (stage itself is a pause hit-target); PAUSED → context view +
  scrubber + edge tabs summoning SW_DRAWER panels (Speed / Quiz preview / Settings) via
  window.show_drawer; STOPPED → full cockpit. Arms `set_fast_timer (12)`; on_tick →
  `reader.tick (tick_ms)` + repaint.
- `SR_STAGE_VIEW` — SW_CANVAS painter: measure prefix (`select_font` + extents.x_advance), draw
  prefix white / pivot red at pin X / suffix white; ticks above/below pin; dim `SPEED: N WPM`.
  Foreign-script tokens: centered whole-word, no pivot (D-011).
- `SR_CONTEXT_VIEW` — SW_CANVAS painter: flowed paragraphs from `context_window`, stopped word
  marked; per-word hit rectangles → `on_word_click (index)` → `resume_at`.
- `SR_FLOW_MAP_VIEW` — SW_CANVAS painter over `flow_blocks (pixel_budget)`; cursor band; read
  half brighter; paused clicks → scrub.
- `SR_COCKPIT` — SW_COLUMN/tabs of stock widgets: intake (SW_TEXT_BOX, SW_FILE_DIALOG button,
  clean-diff review), speed (SW_SLIDER + SW_NUMBER_BOX + back-off SW_BUTTONs), quiz
  (preview list, administration form), history (SW_LIST + SW_SPARKLINE), settings (SW_SELECT
  font, SW_NUMBER_BOX sizes/speeds, Ollama URL SW_TEXT_BOX).
- `SR_KEYS` — key map per 06-INTERFACE-DESIGN.md.

## Dependencies

| Library | Purpose | Notes |
|---------|---------|-------|
| simple_widgets | window/theme/canvas/painter/widgets | brings simple_shell + simple_cairo |
| simple_ai_client | OLLAMA_CLIENT (AI_MESSAGE/AI_RESPONSE) | sync — gateway region only |
| simple_sql | SR_LOG store | ecosystem standard |
| simple_config | SR_SETTINGS | |
| simple_file / simple_encoding | intake + UTF-8→32 | |
| simple_hash | text content hash (FR-033) | |
| simple_diff | clean-review diff (UC-003) | |
| simple_mml | model queries in contracts | dev assertions |
| simple_testing + ISE testing | test target | oracle Testing Standard |
| ISE base | kernel | allowed |

## File Structure

```
simple_speed_reader/
├── simple_speed_reader.ecf
├── src/
│   ├── simple_speed_reader.e            (facade)
│   ├── model/    sr_text.e sr_token.e sr_tokenizer.e
│   ├── pacing/   sr_governor.e sr_timing_model.e sr_pacer.e
│   ├── session/  sr_session.e sr_run_record.e
│   ├── ai/       sr_ai_gateway.e sr_mailbox.e sr_ai_job.e sr_ai_result.e
│   │             sr_clean_job.e sr_quiz_job.e sr_drill_job.e
│   ├── quiz/     sr_quiz.e sr_quiz_question.e sr_quiz_validator.e
│   └── store/    sr_log.e sr_settings.e
├── app/          sr_app.e sr_stage_view.e sr_context_view.e
│                 sr_flow_map_view.e sr_cockpit.e sr_keys.e
├── testing/      test_app.e speed_reader_test_set.e
└── docs/  README.md  CHANGELOG.md
```

## ECF Targets (precedent: simple_ocr_capture)

| Target | Extends | Root | Purpose |
|--------|---------|------|---------|
| simple_speed_reader | — | (library) | engine, no GUI dep |
| speed_reader | simple_speed_reader | SR_APP.make | the GUI exe (adds simple_widgets) |
| simple_speed_reader_tests | simple_speed_reader | TEST_APP.make | oracle-standard tests |

concurrency=scoop · void_safety=all · assertions=all (dev) · F_code via ec.sh · cairo.dll beside exe.
