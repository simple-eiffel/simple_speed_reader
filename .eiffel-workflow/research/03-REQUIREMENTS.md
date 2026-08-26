# REQUIREMENTS: simple_speed_reader

**Date:** 2026-08-26

## Functional Requirements

### The stage (video parity)
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-001 | RSVP stage: one word at a time, large type on near-black; ORP pivot letter in accent red, pinned to a fixed screen X; red tick marks above/below pivot | MUST | Frame-compare against read-speed-drill.mp4 |
| FR-002 | Dim `SPEED: NNN WPM` readout, bottom center, live | MUST | Updates as ramp moves |
| FR-003 | Dark-only theme (SW_THEME.make_dark; no light mode) | MUST | No light path exists |
| FR-004 | User-settable font family and size for the stage | MUST | Change font → stage re-renders, ORP still pinned |
| FR-005 | User-settable text: paste into a text box OR open .txt/.md via file dialog | MUST | Both intakes produce identical word stream |

### Two-state GUI (Larry, 2026-08-26: "ONLY the word-stream when active")
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-006 | RUNNING state shows ONLY the stream: stage + left flow map + WPM readout. Zero interactive chrome | MUST | Screenshot during run shows nothing else |
| FR-007 | All controls (text intake, settings, speed buttons, quiz, history) live in PAUSED/STOPPED state | MUST | Every widget reachable when paused |
| FR-008 | While running, control is keyboard-first (pause, hold, back-off, speed nudge, stop) | MUST | Full session drivable without mouse |

### The flow map (left side)
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-009 | Miniature representation of the WHOLE text along the left edge: word-proportional blocks, deliberately unreadable | MUST | Whole text visible as texture |
| FR-010 | Word-cursor marks the current word as the stream flows; read words render brighter than unread | MUST | Cursor moves in sync at any WPM |
| FR-011 | When paused: flow map is a scrubber — click a block to move the position | SHOULD | Click → context page centers there |

### The recovery loop (the core innovation)
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-012 | One-key STOP at any moment (Space). Stream halts instantly | MUST | Latency imperceptible |
| FR-013 | On stop, stage swaps to a readable CONTEXT PAGE: surrounding paragraphs with the stopped word highlighted | MUST | User can re-read normally |
| FR-014 | User clicks the word where comprehension was last solid → that becomes the restart point | MUST | Any visible word clickable |
| FR-015 | Resume restarts at recovery speed (default 250 WPM, settable 200–300) and re-ramps toward session max | MUST | Ramp curve observable in WPM readout |
| FR-016 | Quick-resume without clicking: resume defaults to start of the sentence containing the stopped word | SHOULD | Space-Space ≈ "back up a little and go" |

### Speed governance
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-017 | Ramp engine: session starts at start-WPM (200–300) and climbs to max-WPM; default max 900, user-settable comfy-max | MUST | Configurable; persists |
| FR-018 | HOLD-at-current control: freezes the ramp at the current WPM (keyboard while running; button while paused) | MUST | WPM stops climbing until released |
| FR-019 | Back-off controls: reduce current target by 100 / 50 / 25 WPM | MUST | Three distinct actions; take effect immediately |
| FR-020 | Timing model: per-word duration = 60000/WPM ms, modulated by word length (linger on long words), punctuation beats (comma/sentence), paragraph breathers | MUST | Blank breathers at sentence ends match video behavior |

### AI pipeline (local only, opt-in, never blocking)
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-021 | Preprocessor: local Ollama cleans unfriendly sources — strip headers/footers/page numbers/footnote markers, rejoin hyphenated line breaks, normalize quotes/dashes/whitespace | MUST | OCR-grade .md in → clean stream out; diff viewable |
| FR-022 | Quiz generation: from ANY user text, BEFORE reading begins — questions + text-anchored answers | MUST | Generated pre-read; stored with the text |
| FR-023 | Quiz participation is strictly opt-in | MUST | Off by default; zero quiz UI when off |
| FR-024 | Pre-read REVIEW of the quiz (SQ3R survey/question): user may read the questions (not answers) beforehand to form a mental model | MUST | Preview pane in stopped state |
| FR-025 | Post-read quiz administration + scoring; score joins the log | MUST | Score computed and persisted |
| FR-026 | Everything except AI features works with no Ollama reachable | MUST | Kill Ollama → reader fully functional, AI affordances disabled with honest status |

### Log & history
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-027 | Per-run log: date, text identity, words read, WPM profile (avg/max/held), stop/rewind count, quiz score if taken | MUST | Rows survive restart (SQLite) |
| FR-028 | History view: speed and comprehension trends over time (sparkline/line chart) | SHOULD | Visible in stopped state |

### Drill mode (secondary)
| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-029 | Drill mode: series of graded practice texts generated by local AI (cached), same engine + quiz loop | SHOULD | Selectable set; difficulty progresses |

## Non-Functional Requirements

| ID | Requirement | Category | Measure | Target |
|----|-------------|----------|---------|--------|
| NFR-001 | Cadence honesty at top speed | PERFORMANCE | scheduling jitter vs word deadline at 900 WPM (66 ms/word) | ≤ 15 ms (one fast-tick) |
| NFR-002 | Stop latency | PERFORMANCE | keypress → stream frozen | next tick (≤ 15 ms) |
| NFR-003 | AI never blocks the reading loop | ARCHITECTURE | UI thread never awaits HTTP | SCOOP separate worker |
| NFR-004 | Book-scale texts | CAPACITY | 200k-word text loads, maps, streams | no visible degradation |
| NFR-005 | Local-only, no telemetry | PRIVACY | outbound connections | localhost Ollama only |
| NFR-006 | Contracts everywhere; void-safe; SCOOP-compatible | QUALITY | ec.sh test target green | 100% |

## Constraints

| ID | Constraint | Type | Immutable? |
|----|------------|------|------------|
| C-001 | SCOOP-compatible (concurrency=scoop) | TECHNICAL | YES |
| C-002 | simple_* first: simple_widgets / simple_ai_client / simple_sql / simple_config / simple_file | ECOSYSTEM | YES |
| C-003 | F_code releases via ec.sh; cairo.dll ships beside exe | BUILD | YES |
| C-004 | Dark-only | PRODUCT | YES (Larry) |
| C-005 | Ollama base URL configurable (Larry's native GPU instance: 11435, not default 11434) | ENVIRONMENT | YES |
