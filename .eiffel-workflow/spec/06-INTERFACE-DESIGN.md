# INTERFACE DESIGN: simple_speed_reader

**Date:** 2026-08-26

## Public API Summary (facade SIMPLE_SPEED_READER)

### Creation
| Feature | Purpose | Typical Use |
|---------|---------|-------------|
| make | Load settings + log, spawn AI gateway, no text | `create reader.make` |

### Configuration (persisted via SR_SETTINGS; fluent per ecosystem builder pattern)
| Feature | Returns | Purpose |
|---------|---------|---------|
| with_font (a_family, a_size) | like Current | Stage typeface |
| with_speeds (a_start, a_recovery, a_comfy_max) | like Current | The three speed anchors |
| with_ollama (a_url, a_model) | like Current | Local AI endpoint (Larry: http://localhost:11435) |
| with_quiz_opt_in (a_on) / with_clean_opt_in (a_on) | like Current | AI participation switches |

### Intake
| Feature | Returns | Purpose |
|---------|---------|---------|
| load_text (a_title, a_source) | — | Paste path: tokenize, hash, autoresume check, quiz reuse/launch |
| load_file (a_path) | — | .txt/.md path (simple_file + simple_encoding) |
| request_clean / accept_clean / reject_clean | — | Preprocess round-trip with diff review |
| clean_diff | STRING_32 | simple_diff rendering for the review panel |

### The reading loop (GUI feeds clock + keys; engine decides)
| Feature | Returns | Purpose |
|---------|---------|---------|
| start_reading / stop_reading | — | READY→RUNNING / RUNNING→PAUSED |
| resume_at (a_index) / resume_at_sentence_start | — | Recovery (marked / zero-click) |
| tick (a_now_ms) | — | Deadline check; may advance; polls mailbox |
| finish_session | — | Seal + log the run record |
| hold / release_hold / back_off (a_amount) / set_comfy_max (a_wpm) | — | Governance |

### Status queries (GUI paints from these; all pure)
| Feature | Returns | Purpose |
|---------|---------|---------|
| has_text / is_running / is_paused / is_done | BOOLEAN | State |
| current_token | SR_TOKEN | The word on stage (require has_text) |
| position / token_count | INTEGER | Flow-map cursor + progress |
| current_wpm / target_wpm / effective_wpm | INTEGER | Readout + honesty |
| context_window (a_radius): LIST [SR_TOKEN] | — | Context-page content around position |
| flow_blocks (a_pixel_budget): ARRAY [REAL_64] | — | Pre-sampled minimap block widths (RISK-008) |
| ai_available / ai_status_line | BOOLEAN / STRING_32 | Honest AI affordance state (FR-026) |
| quiz_ready / quiz | BOOLEAN / detachable SR_QUIZ | Quiz surface |
| run_records | LIST [SR_RUN_RECORD] | History panel |

## Fluent Setup Example

```eiffel
create reader.make
reader := reader
    .with_font ("Cascadia Mono", 64)
    .with_speeds (250, 250, 900)
    .with_ollama ("http://localhost:11435", "qwen3:14b")
    .with_quiz_opt_in (True)
reader.load_file ("D:\books\chapter1.md")
```

## The GUI Drive Cycle (SR_APP — three postures per D-012)

```eiffel
-- on_tick (armed via shell set_fast_timer (12)):
reader.tick (now_ms)                    -- engine may advance / seal at text end
inspect posture
when Running then stage + flow_map + wpm + dim_pause_affordance
when Paused  then context_view + flow_map (scrubber) + edge tabs → window.show_drawer
when Stopped then cockpit (full)
end
```

## Transport Keymap (SR_KEYS — media-player conventions, D-014)

| Key | Convention source | RUNNING | PAUSED |
|-----|-------------------|---------|--------|
| Space (or K) | universal / YouTube | → Pause (context page, drawers) | → Resume at sentence start, recovery WPM |
| Enter | player confirm | — | Resume at marked/click point (or sentence start) |
| Esc (or S) | VLC stop | → STOP: seal sitting, cockpit | → STOP: seal, cockpit |
| Left (J-like) | YouTube J / podcast skip-back | **Micro-rewind:** replay from previous sentence start, stream keeps flowing, speed unchanged | Move resume point back one sentence |
| Right (L-like) | YouTube L / skip-forward | Skip to next sentence start (skipped words logged) | Move resume point forward one sentence |
| Ctrl+Left / Ctrl+Right | VLC long-seek | Same, by paragraph | Same, by paragraph |
| Up / Down | speed dial (our "volume") | Target +25 / −25 WPM | Same |
| , / . (< / >) | YouTube speed keys | Alias of Down / Up | Same |
| H | (ours — cruise control) | Hold at current / release | Toggle hold for resume |
| 1 / 2 / 3 | (ours) | Back-off 100 / 50 / 25 | Same |
| Home | player | — | Resume point → text start |
| Media keys (Play/Pause, Stop) | hardware | As Space / Esc | As Space / Esc | 

**State behaviors (transport semantics + our two deliberate deviations):**
- **Play/Resume** — stream flows, ramp climbs. *Deviation 1:* resume after a pause restarts at
  recovery WPM and re-ramps (media players resume at full speed; we deliberately don't — D-003).
  The **micro-rewind** (Left while running) is the light-touch middle: an in-flow regression that
  replays one sentence at the CURRENT speed with no posture change — for a momentary lapse, not a
  comprehension collapse.
- **Pause** — sitting stays alive; context page is the regression surface; controls drawered.
- **Stop** — seals the sitting: run record logged, position autosaved. *Deviation 2:* stop
  preserves the reading position (audiobook convention), it does NOT reset to start (VLC
  convention) — "Continue at word N" appears in the cockpit.
- **Rewind/Forward** — sentence-granular (words too fine, paragraphs the Ctrl tier). Forward
  skips are logged as skipped words: effective WPM stays honest.

-- SR_CONTEXT_VIEW click (paused):
click word i → reader.resume_at (i)

The paused Speed drawer and the cockpit may reuse SW_MEDIA_TRANSPORT for visual
play/pause/stop/seek buttons mirroring exactly these commands.

## Error Handling Pattern

AI results follow the ecosystem result-object pattern (AI_RESPONSE-like):

```eiffel
reader.poll_ai                               -- from tick; drains mailbox
if reader.quiz_ready then cockpit.arm_quiz_tab end
-- a failed job surfaces as ai_status_line, never as an exception into the pump
```

Engine misuse (resume beyond stop point, back_off 33, tick before load) is a CONTRACT violation —
caught in development, impossible paths in the GUI (buttons exist only in legal states).
File intake errors are result-style: `load_file` sets `last_intake_ok / last_intake_error`.

## Command-Query Separation (oracle: /eiffel.audit-cqs will verify)

| Feature | Type | Modifies State? | Returns Value? |
|---------|------|-----------------|----------------|
| with_* setters | Command (fluent) | YES | like Current (ecosystem-sanctioned chaining) |
| load_* / start/stop/resume/tick/hold/back_off | Command | YES | NO |
| poll_ai | Command | YES (drains mailbox) | NO |
| current_token, *_wpm, position, flow_blocks, context_window | Query | NO | YES |
| quiz_ready, ai_available, states | Query | NO | YES |
| answer_question | Command | YES | NO |
| quiz_score | Query | NO | YES |

No feature both mutates and returns (except fluent Current, per ecosystem builder doctrine).

## View Agent Signatures (gotcha-guarded)

Per oracle gotcha (PROCEDURE [TUPLE …] flattens): view callbacks use SCALAR open args only —
`on_word_click: PROCEDURE [INTEGER]` (token index), `on_scrub: PROCEDURE [INTEGER]`,
canvas paint agents keep simple_widgets' native `PROCEDURE [SW_PAINTER, REAL_64, REAL_64, REAL_64, REAL_64]`.
