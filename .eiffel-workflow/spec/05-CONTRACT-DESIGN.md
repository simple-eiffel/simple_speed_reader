# CONTRACT DESIGN: simple_speed_reader

**Date:** 2026-08-26

## MML Model Queries

| Owner.Attribute | Type | Model Query | MML Type |
|-----------------|------|-------------|----------|
| SR_TEXT.tokens | ARRAYED_LIST [SR_TOKEN] | tokens_model | MML_SEQUENCE [SR_TOKEN] |
| SR_QUIZ.questions | ARRAYED_LIST [SR_QUIZ_QUESTION] | questions_model | MML_SEQUENCE [SR_QUIZ_QUESTION] |
| SR_SESSION.stop_indices | ARRAYED_LIST [INTEGER] | stops_model | MML_SEQUENCE [INTEGER] |
| SR_LOG (runs table) | — (SQL) | modeled at facade: run_records count/monotone date | — |

Frame conditions use `|=|` on these models (e.g., a governor command leaves tokens_model of the
active text untouched — speed never edits text).

## Class Contracts

### SR_TOKEN (immutable value)

```eiffel
invariant
    word_present: not word.is_empty
    pivot_inside: pivot_index >= 1 and pivot_index <= word.count      -- DR-001
    pivot_not_combining: not is_combining_mark (word [pivot_index])   -- D-011 (niqqud never pivots)
    latin_only_pivots: not is_latin implies not shows_pivot           -- foreign: centered, no ORP
    paragraph_end_is_sentence_end: ends_paragraph implies ends_sentence
    ordered_source: source_start >= 1
```

Classification attributes (`script`, `has_diacritics`, `is_numeric`, `is_acronym`,
`is_foreign_term`) are set at creation/enrichment; `streams_under_filter (a_skip_foreign: BOOLEAN):
BOOLEAN` is the D-013 predicate (`Result = (is_latin or not a_skip_foreign)`).

Creation `make (a_word, a_sentence, a_paragraph, ...)`:
```eiffel
require
    word_not_empty: not a_word.is_empty
    positive_indices: a_sentence >= 1 and a_paragraph >= 1
ensure
    word_kept: word.same_string (a_word)
    pivot_by_length: pivot_index = pivot_for_length (word.count)      -- Single Choice: the ORP law
```

### SR_TOKENIZER

```eiffel
tokenize (a_clean: READABLE_STRING_32): ARRAYED_LIST [SR_TOKEN]
    require
        has_content: not a_clean.is_empty
    ensure
        some_tokens: not Result.is_empty
        sentences_monotone: across 2 |..| Result.count as i all
            Result [i].sentence_index >= Result [i - 1].sentence_index end
        paragraphs_monotone: across 2 |..| Result.count as i all
            Result [i].paragraph_index >= Result [i - 1].paragraph_index end
        last_closes: Result [Result.count].ends_sentence
```

### SR_GOVERNOR

**Invariant (DR-002 — the speed law):**
```eiffel
invariant
    floor: Min_wpm <= current_wpm
    order: current_wpm <= target_wpm
    ceiling: target_wpm <= comfy_max_wpm
    recovery_sane: Min_wpm <= recovery_wpm and recovery_wpm <= comfy_max_wpm
    held_pins: is_held implies current_wpm = target_wpm
```

**Commands:**
```eiffel
note_word_advanced
        -- One word consumed: climb the ramp if due.
    ensure
        never_faster_than_target: current_wpm <= target_wpm
        monotone_up: current_wpm >= old current_wpm or is_held
        target_frame: target_wpm = old target_wpm
        comfy_frame: comfy_max_wpm = old comfy_max_wpm

hold
    require not_held: not is_held
    ensure held: is_held
           pinned: target_wpm = current_wpm
           current_frame: current_wpm = old current_wpm

release_hold
    require held: is_held
    ensure released: not is_held
           target_restored: target_wpm = old session_target.min (comfy_max_wpm)

back_off (a_amount: INTEGER)
    require sanctioned_step: a_amount = 25 or a_amount = 50 or a_amount = 100
    ensure lowered: target_wpm = (old target_wpm - a_amount).max (Min_wpm)
           current_clamped: current_wpm = (old current_wpm).min (target_wpm)
           comfy_frame: comfy_max_wpm = old comfy_max_wpm            -- one bad day ≠ new profile

reset_for_recovery
    ensure at_recovery: current_wpm = recovery_wpm
           target_frame: target_wpm = old target_wpm

apply_brake
        -- D-016: begin the eased glide toward Brake_floor (300).
    require not_braking: not is_braking
    ensure braking: is_braking
           cruise_remembered: pre_brake_wpm = old current_wpm
           hold_remembered: was_held_before_brake = old is_held

brake_glide_tick
        -- Called per tick while braking (and while easing back after release).
    ensure gliding_down: is_braking implies current_wpm <= old current_wpm
           floored: current_wpm >= Brake_floor.min (pre_brake_wpm).max (Min_wpm)

release_brake
    require braking: is_braking
    ensure released: not is_braking
           easing_home: brake_recovery_target = pre_brake_wpm
           hold_restored: is_held = was_held_before_brake

set_comfy_max (a_wpm: INTEGER)
    require sane: a_wpm >= Min_wpm and a_wpm <= Max_wpm              -- Max_wpm = 1500
    ensure set: comfy_max_wpm = a_wpm
           clamped_down: target_wpm <= comfy_max_wpm
```

### SR_TIMING_MODEL (pure; DR-010)

```eiffel
display_ms (a_token: SR_TOKEN; a_wpm: INTEGER): INTEGER
        -- base × graduated length band (1.0/1.1/1.3/1.5) × linger classes
        -- (foreign script 2.5 + WPM-floor 350, diacritics 1.6, numeric 1.8,
        --  acronym 1.4), stack capped ×3.0 (D-011 / FR-037).
    require positive_speed: a_wpm >= {SR_GOVERNOR}.Min_wpm
    ensure positive: Result > 0
           never_shorter_than_base: Result >= base_ms (a_wpm)
           capped: Result <= 3 * base_ms (a_wpm).max (foreign_floor_ms (a_token))
           foreign_floor: a_token.is_foreign_script implies
               Result >= base_ms (Foreign_ceiling_wpm)                 -- 350

breather_ms (a_token: SR_TOKEN; a_wpm: INTEGER): INTEGER
    ensure non_negative: Result >= 0
           paragraph_longest: a_token.ends_paragraph implies Result >= sentence_breather (a_wpm)
           sentence_beats: (a_token.ends_sentence and not a_token.ends_paragraph) implies
               Result >= clause_breather (a_wpm)
           plain_words_flow: (not a_token.ends_sentence and not a_token.has_clause_break)
               implies Result = 0
```

### SR_PACER

```eiffel
on_tick (a_now_ms: NATURAL_32)
        -- Report whether the stream advances this tick.
    ensure
        no_drift: next_deadline_anchored          -- deadline advanced from old deadline, not from now
        at_most_one: advances_reported <= old advances_reported + 1   -- display discipline

invariant
    deadline_sane: is_armed implies next_deadline_ms > 0
```

### SR_SESSION (state machine; DR-003/004/006/008; three states per D-012)

States: `is_stopped` (sealed or not yet started) / `is_running` / `is_paused` — exactly one.

```eiffel
start_reading
    require stopped: is_stopped
            unsealed: not is_sealed
    ensure running: is_running
           at_start_or_resume_point: position = old position

pause_reading
    require running: is_running
    ensure paused: is_paused
           pause_recorded: pause_count = old pause_count + 1
           position_frame: position = old position

stop_and_seal
    require live: is_running or is_paused
    ensure stopped: is_stopped
           sealed: is_sealed and last_record /= Void
           position_kept: position = old position          -- audiobook stop, not VLC stop

replay_sentence
        -- Micro-rewind (Left while running): in-flow regression, no posture change.
    require running: is_running
    ensure still_running: is_running
           moved_back: position <= old position
           at_sentence_start: position_is_sentence_start
           speed_untouched: current_wpm = old current_wpm  -- lapse, not collapse: no re-ramp

skip_sentence_forward
    require running: is_running
            more: position < token_count
    ensure still_running: is_running
           moved_forward: position >= old position
           skips_logged: skipped_count >= old skipped_count

scrub_back (a_words: INTEGER)
        -- D-016 brake-drag: rewind while STILL RUNNING (braked to stop); no posture change.
    require running: is_running
            braking: governor.is_braking
            positive: a_words >= 1
    ensure still_running: is_running
           moved_back: position = (old position - a_words).max (1)
           brake_event_logged: brake_events.count >= old brake_events.count

resume_at (a_index: INTEGER)
    require paused: is_paused
            in_text: a_index >= 1 and a_index <= token_count
            never_forward: a_index <= position                         -- DR-003
    ensure running: is_running
           moved_back: position = a_index
           re_ramped: current_wpm = recovery_wpm                       -- DR-004
           rewind_recorded: rewind_spans.count = old rewind_spans.count + 1

advance
    require running: is_running
            more: position < token_count
    ensure stepped_past_filter: position > old position                -- foreign-skip may jump several
           displayed_is_streamable: current_token_streams              -- never lands on a filtered token
           stamped: timestamps.count = old timestamps.count + 1        -- DR-008 (streamed only)
           skips_accounted: skipped_count - old skipped_count = position - old position - 1
           tokens_frame: text.tokens_model |=| old text.tokens_model

-- Reaching the last streamable token auto-seals: ensure of the final advance includes
--   sealed_at_end: position = token_count implies (is_stopped and is_sealed)
-- Record honesty: is_sealed implies last_record.effective_wpm computed from wall time,
--   last_record.streamed_count + last_record.skipped_count = words passed

invariant
    position_in_text: has_text implies (position >= 0 and position <= token_count)
    one_state: bool_count (is_stopped, is_running, is_paused) = 1
    sealed_is_stopped: is_sealed implies is_stopped
    stamps_bounded: timestamps.count <= token_count * 2                -- rewinds re-stamp
    skip_honest: skipped_count <= token_count
```

### SR_QUIZ / SR_QUIZ_QUESTION (DR-005)

```eiffel
class SR_QUIZ_QUESTION
invariant
    has_prompt: not prompt.is_empty
    has_quote: not supporting_quote.is_empty
    verified_means_found: is_verified implies quote_was_located
    judged_only_answered: is_judged implies user_answer /= Void

class SR_QUIZ
invariant
    all_verified: across questions as q all q.is_verified end          -- validator ran; DR-005
    score_range: is_administered implies (score_percent >= 0 and score_percent <= 100)
```

```eiffel
{SR_QUIZ_VALIDATOR}.is_quote_in_text (a_quote, a_text: READABLE_STRING_32): BOOLEAN
    require both_present: not a_quote.is_empty and not a_text.is_empty
    -- whitespace-normalized verbatim containment; pure query, no state
```

### SR_AI_GATEWAY / SR_MAILBOX (DR-009)

```eiffel
-- gateway (separate)
submit (a_job: SR_AI_JOB)
    ensure queued: pending_count = old pending_count + 1

-- mailbox (separate)
put (a_result: SR_AI_RESULT)
    ensure grown: count = old count + 1
take: detachable SR_AI_RESULT
    ensure taken_or_empty: (old count > 0) implies (Result /= Void and count = old count - 1)
```

### SR_LOG

```eiffel
record_run (a_record: SR_RUN_RECORD)
    ensure persisted: run_count = old run_count + 1

quiz_for_hash (a_hash: READABLE_STRING_8): detachable SR_QUIZ
    -- Reuse before regenerate (FR-033)
```

### SIMPLE_SPEED_READER (facade)

```eiffel
invariant
    settings_alive: settings /= Void
    running_has_text: is_running implies has_text
    speed_visible: is_running implies current_wpm >= {SR_GOVERNOR}.Min_wpm
```

Facade commands delegate; their contracts restate the session/governor guarantees at the API
surface (e.g., `back_off` ensures `target_wpm = (old target_wpm - a_amount).max (Min_wpm)`).

## Contract Completeness Checklist

For every command above:
- [x] **What changed** — named in ensure (position, target_wpm, stop_count, …)
- [x] **How it changed** — related to `old` (monotone ramps, +1 counters, max/min clamps)
- [x] **What did NOT change** — frame clauses (comfy_frame, target_frame, tokens_model `|=|`,
      position_frame) on every mutating feature that could plausibly touch them
