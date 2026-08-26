# CLASS DESIGN: simple_speed_reader

**Date:** 2026-08-26

## Layering (library target is headless; GUI is a view)

```
app target (speed_reader.exe)          SR_APP · SR_STAGE_VIEW · SR_CONTEXT_VIEW
   GUI = simple_widgets                SR_FLOW_MAP_VIEW · SR_COCKPIT · SR_KEYS
────────────────────────────────────────────────────────────────────────────
library target (simple_speed_reader)   SIMPLE_SPEED_READER (facade)
   engine = pure logic, no GUI dep     SR_TEXT · SR_TOKEN · SR_TOKENIZER
                                       SR_GOVERNOR · SR_TIMING_MODEL · SR_PACER
                                       SR_SESSION · SR_RUN_RECORD
                                       SR_AI_GATEWAY · SR_MAILBOX · SR_AI_JOB(+3)
                                       SR_QUIZ · SR_QUIZ_QUESTION · SR_QUIZ_VALIDATOR
                                       SR_LOG · SR_SETTINGS
```

The engine never imports simple_widgets — every reading behavior (ramp, recovery, timing, quiz,
log) is testable headless by driving SIMPLE_SPEED_READER with a scripted clock. The GUI feeds it
real ticks, keys, and clicks. (This is what makes the Testing Standard bite: contract-assault
tests run the whole reading loop without a window.)

## Class Inventory

| Class | Role | Single Responsibility |
|-------|------|-----------------------|
| SIMPLE_SPEED_READER | Facade | One door: load text, run sessions, ask AI, log runs |
| SR_TEXT | Data | One work: sources, tokens, structure, hash identity |
| SR_TOKEN | Data (immutable) | One streamable word + ORP + timing flags |
| SR_TOKENIZER | Engine | Clean text → tokens + sentence/paragraph structure (ORP computed here — Single Choice) |
| SR_GOVERNOR | State | The speed law: current/target/comfy-max, hold, back-off, re-ramp |
| SR_TIMING_MODEL | Engine (pure) | Token → display ms + breather ms at a WPM |
| SR_PACER | Engine | Wall-clock deadlines: tick_ms in, advance decisions out, zero drift |
| SR_SESSION | State machine | One sitting: position, states, stop/resume, timestamps |
| SR_RUN_RECORD | Data | The honest account of one run |
| SR_AI_GATEWAY | separate worker | Owns OLLAMA_CLIENT; executes queued jobs; posts to mailbox |
| SR_MAILBOX | separate data | Completed-result handoff box (poll target) |
| SR_AI_JOB | Deferred | One unit of model work: prompt in, parsed result out |
| SR_CLEAN_JOB | Engine | Preprocess prompt + response parse |
| SR_QUIZ_JOB | Engine | Chunked quiz-generation prompt + parse |
| SR_DRILL_JOB | Engine | Graded drill-text prompt + parse |
| SR_QUIZ | Data | Verified questions + scoring |
| SR_QUIZ_QUESTION | Data | prompt/answer/quote/verification/user answer |
| SR_QUIZ_VALIDATOR | Engine (pure) | Quote-occurs-verbatim gate |
| SR_LOG | Persistence | SQLite: texts, quizzes, runs, resume points |
| SR_SETTINGS | Persistence | simple_config profile |
| SR_APP | GUI root | Two-state layout switch; tick fan-out; wiring |
| SR_STAGE_VIEW | GUI painter | RSVP frame on SW_CANVAS (word, pivot, ticks, WPM) |
| SR_CONTEXT_VIEW | GUI painter | Readable page + word hit-testing (recovery clicks) |
| SR_RIBBON_VIEW | GUI painter | Paused fisheye strip: distance-tapered word sizes, click = resume point (D-015) |
| SR_FLOW_MAP_VIEW | GUI painter | Whole-text miniature + cursor; scrub clicks |
| SR_COCKPIT | GUI composite | Paused/stopped panels: intake, speed, quiz, history, settings |
| SR_KEYS | GUI service | Running-state key map → facade commands |

27 classes (20 library + 7 app). Tests per oracle standard: `testing/test_app.e` +
`speed_reader_test_set.e` (TEST_SET_BASE).

## Facade Design: SIMPLE_SPEED_READER

**Purpose:** the library API — everything a front end (GUI, test, future TUI) needs.
**Hides:** tokenizer, pacer internals, gateway/mailbox mechanics, SQL, prompt texts.

```eiffel
class SIMPLE_SPEED_READER

create
    make                                      -- settings + log loaded; AI gateway spawned; no text

feature -- Intake
    load_text (a_title: READABLE_STRING_GENERAL; a_source: READABLE_STRING_32)
    load_file (a_path: READABLE_STRING_GENERAL)
    request_clean                             -- submit SR_CLEAN_JOB (opt-in path)
    accept_clean / reject_clean               -- after diff review

feature -- Session
    start_reading                             -- READY → RUNNING (arms governor ramp)
    stop_reading                              -- RUNNING → PAUSED (context point = position)
    resume_at (a_index: INTEGER)              -- PAUSED → RUNNING at recovery speed
    resume_at_sentence_start                  -- the zero-click default
    tick (a_now_ms: NATURAL_32)               -- clock in; advances happen here
    finish_session                            -- → DONE; run record sealed + logged

feature -- Speed
    hold / release_hold
    back_off (a_amount: INTEGER)              -- 25 | 50 | 100
    set_comfy_max (a_wpm: INTEGER)

feature -- Quiz
    request_quiz                              -- submit SR_QUIZ_JOB (reuses by hash first)
    quiz_ready: BOOLEAN
    quiz: detachable SR_QUIZ
    answer_question (a_index: INTEGER; a_answer: READABLE_STRING_32)
    quiz_score: INTEGER                       -- percent, after administration

feature -- Status (all queries; GUI paints from these)
    has_text, is_running, is_paused, is_done: BOOLEAN
    current_token: SR_TOKEN
    position, token_count: INTEGER
    current_wpm, target_wpm: INTEGER
    effective_wpm: INTEGER
    ai_available: BOOLEAN
    poll_ai                                   -- drain mailbox into quiz/clean state (called from tick)

feature -- History
    run_records: LIST [SR_RUN_RECORD]
```

## Engine Details

### SR_PACER (kills RISK-001 by construction)
Deadline scheduling, not interval counting: `on_tick (now)` compares `now` to `next_deadline`;
when passed, it reports an advance and sets `next_deadline := next_deadline + duration(next)` —
anchored to the *previous deadline*, not to `now`, so tick jitter never accumulates
(the carry is implicit in the anchor). Late ticks can yield two advances; contract caps catch-up
(never skip displaying a word — cap at one advance per tick, stretching the schedule instead:
reading is a display discipline, not an audio stream).

### SR_GOVERNOR state
`current_wpm` climbs `ramp_step` per `ramp_interval` words toward `target_wpm`.
`hold` → `is_held; target_wpm := current_wpm` until `release_hold` (restores session target
= min(pre-hold target, comfy_max)). `back_off (n)` → `target_wpm := max(Min_wpm, target_wpm − n)`,
`current_wpm := min(current_wpm, target_wpm)`. `reset_for_recovery` → `current_wpm := recovery_wpm`,
target unchanged. Profile `comfy_max` mutated ONLY by `set_comfy_max`.

### SR_SESSION states
```
IDLE ──load──> READY ──start──> RUNNING ──stop──> PAUSED
                 ^                 │  ^─resume_at──┘
                 └──new text───────┴──last advance──> DONE
```
Every `advance` timestamps (DR-008) and asks the governor to ramp; every `stop` records a stop
event; every `resume_at` records the rewind span (stop_index − resume_index).

## AI Architecture (SCOOP)

```
creator region                          gateway region
┌───────────────────────────┐          ┌──────────────────────────┐
│ SR_APP / facade           │ submit   │ SR_AI_GATEWAY (separate) │
│  - submit (job) ──────────┼─────────>│  loop: take job,         │
│  - tick → poll_ai ─┐      │          │  OLLAMA_CLIENT.execute_  │
│                    │      │          │  chat (BLOCKING, curl),  │
│                    ▼      │          │  parse via job,          │
│            ┌───────────────┐  post   │  post result ────────────┼──┐
│            │ SR_MAILBOX    │<────────┴──────────────────────────┘  │
│            │ (separate)    │<──────────────────────────────────────┘
│            └───────────────┘   tiny lock: put/take only
└───────────────────────────┘
```
The blocking curl call lives entirely in the gateway region. The UI's `poll_ai` locks the mailbox
only for a take — microseconds. Jobs carry chunk indices so quiz questions stream in per chunk
(A-4 resolution).

## Inheritance Hierarchy

```
        SR_AI_JOB (deferred: prompt, parse, describe)
        ┌────────────┼─────────────┐
   SR_CLEAN_JOB  SR_QUIZ_JOB  SR_DRILL_JOB
```

**Inheritance Justification:**
| Child | Parent | IS-A Valid? | Liskov OK? |
|-------|--------|-------------|------------|
| SR_CLEAN_JOB | SR_AI_JOB | a cleanup request IS-A model job | YES — same prompt/parse contract |
| SR_QUIZ_JOB | SR_AI_JOB | a quiz request IS-A model job | YES |
| SR_DRILL_JOB | SR_AI_JOB | a drill-text request IS-A model job | YES |

GUI views COMPOSE SW_CANVAS (a view HAS a canvas it feeds paint agents to) — no inheritance into
the toolkit; SR_COCKPIT composes stock widgets. SR_APP composes SW_WINDOW. (Toolkit classes are
extended by agents, per simple_widgets doctrine.)

## Generic Classes

None. Every collection is concretely typed (tokens, questions, records); genericity would add
semantic distance without range (oracle rule: unconstrained generics must stay maximally generic —
nothing here is generic in nature). SR_MAILBOX holds SR_AI_RESULT values only.

## Class Diagram (core flow)

```
┌──────────────────────────────────────────────────────────────┐
│                    SIMPLE_SPEED_READER (Facade)              │
│ load/start/stop/resume/tick/hold/back_off/quiz/poll_ai      │
└──┬──────────┬──────────┬──────────┬───────────┬─────────────┘
   │          │          │          │           │
   ▼          ▼          ▼          ▼           ▼
SR_TEXT   SR_SESSION SR_GOVERNOR SR_AI_GATEWAY SR_LOG
   │          │  │        ▲        (separate)    ▲
   ▼          │  └─►SR_PACER──►SR_TIMING_MODEL   │
SR_TOKEN◄─────┘                     │            │
(SR_TOKENIZER builds)         SR_MAILBOX──►SR_QUIZ──►SR_QUIZ_QUESTION
                                    (validated by SR_QUIZ_VALIDATOR)
                              SR_SESSION──►SR_RUN_RECORD──►SR_LOG
```
