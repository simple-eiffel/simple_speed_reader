# DESIGN VALIDATION: simple_speed_reader

**Date:** 2026-08-26

## OOSC2 Compliance

| Principle | Status | Evidence |
|-----------|--------|----------|
| Single Responsibility | ✓ | 26 classes, one sentence each (04 inventory); ORP law lives only in SR_TOKEN.pivot_for_length; timing only in SR_TIMING_MODEL; speed law only in SR_GOVERNOR |
| Open/Closed | ✓ | New AI work = new SR_AI_JOB descendant; new front end = new consumer of the facade; engine closed |
| Liskov Substitution | ✓ | Only hierarchy is SR_AI_JOB → 3 jobs, same prompt/parse contract (04 justification table) |
| Interface Segregation | ✓ | Facade groups (intake/loop/quiz/status); views see only status queries + commands they fire |
| Dependency Inversion | ✓ | GUI depends on facade abstraction; engine never imports widgets; gateway hides OLLAMA_CLIENT |

## Eiffel Excellence

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Command-Query Separation | ✓ | 06 CQS table; only fluent `like Current` chaining (ecosystem-sanctioned); /eiffel.audit-cqs later |
| Uniform Access | ✓ | current_wpm/effective_wpm are queries — attribute vs computed is hidden |
| Design by Contract | ✓ | 05: invariants on every stateful class; what/how/frame on every command |
| Genericity | ✓ (none) | Deliberate: no semantic range to parameterize (oracle genericity rule; 04) |
| Inheritance | ✓ | IS-A only (SR_AI_JOB); views compose the toolkit, never inherit it |
| Information Hiding | ✓ | Prompts, SQL, curl, pacing arithmetic all {NONE}/hidden classes behind facade |

## Practical Quality

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Void-safe | ✓ | detachable only where absence is domain-real: quiz, last_record, mailbox take, user_answer |
| SCOOP-compatible | ✓ | one separate gateway + one separate mailbox; blocking curl confined to gateway region (DR-009); hot path region-local |
| simple_* first | ✓ | 10 simple_* deps enumerated (07); ISE = base + testing only |
| MML postconditions | ✓ | tokens_model/questions_model/stops_model; `|=|` frames (05) |
| Testable | ✓ | Headless engine: scripted-clock tests drive tick/stop/resume/ramp without a window |
| Oracle gotchas | ✓ | across-element binding; no PROCEDURE[TUPLE] single-arg; preferred_width on containers; rrect radius > 0 — recorded in 03 |

## Requirements Traceability

| Requirement | Addressed By | Status |
|-------------|--------------|--------|
| FR-001 stage w/ ORP+ticks | SR_STAGE_VIEW + SR_TOKEN.pivot_index | ✓ |
| FR-002 WPM readout | SR_STAGE_VIEW ← current_wpm | ✓ |
| FR-003 dark-only | SR_APP make_dark; no toggle | ✓ |
| FR-004 settable font | with_font → SR_SETTINGS → SW_PAINTER.select_font | ✓ |
| FR-005 paste + file intake | load_text / load_file | ✓ |
| FR-006 running = stream only | SR_APP two-state switch (DR-007) | ✓ |
| FR-007 controls in pause/stop | SR_COCKPIT (only non-running) | ✓ |
| FR-008 keyboard-first running | SR_KEYS map (06) | ✓ |
| FR-009/010 flow map + cursor | SR_FLOW_MAP_VIEW ← flow_blocks/position | ✓ |
| FR-011 scrubber when paused | SR_FLOW_MAP_VIEW.on_scrub | ✓ |
| FR-012 instant stop | stop_reading ≤ one tick (NFR-002) | ✓ |
| FR-013 context page | SR_CONTEXT_VIEW ← context_window | ✓ |
| FR-014 click last-comprehended | on_word_click → resume_at (DR-003) | ✓ |
| FR-015 re-ramp from recovery | resume_at ensures current = recovery (DR-004) | ✓ |
| FR-016 zero-click default | resume_at_sentence_start | ✓ |
| FR-017 ramp to comfy-max | SR_GOVERNOR make/note_word_advanced | ✓ |
| FR-018 hold | SR_GOVERNOR.hold/release_hold | ✓ |
| FR-019 back-off 100/50/25 | back_off precondition sanctions exactly these | ✓ |
| FR-020 timing model | SR_TIMING_MODEL display/breather | ✓ |
| FR-021 preprocessor | SR_CLEAN_JOB + diff review (UC-003) | ✓ |
| FR-022 quiz before reading | SR_QUIZ_JOB launched at load; streams per chunk (03 rewording) | ✓ |
| FR-023 quiz opt-in | with_quiz_opt_in; zero surface when off | ✓ |
| FR-024 SQ3R preview | cockpit quiz tab shows arrived prompts pre-read | ✓ |
| FR-025 administer + score | answer_question/quiz_score → run record | ✓ |
| FR-026 graceful no-AI | ai_available probe + ai_status_line; engine independent | ✓ |
| FR-027 run log | SR_RUN_RECORD → SR_LOG.record_run | ✓ |
| FR-028 history trends | run_records → SW_SPARKLINE panel | ✓ |
| FR-029 drill mode | SR_DRILL_JOB + is_drill tag; engine reuse | ✓ |
| FR-030 font fallback | curated list + safe fallback (03) | ✓ |
| FR-031 resize-safe pivot | pin X recomputed from live width each paint | ✓ |
| FR-032 position autosave | SR_SETTINGS last text/position; resume offer at load | ✓ |
| FR-033 hash identity | SR_TEXT.hash (simple_hash); SR_LOG.quiz_for_hash | ✓ |
| FR-034 pause always reachable | SR_APP dim affordance + stage hit-target (D-012) | ✓ |
| FR-035 paused = drawers | SR_APP paused posture; SW_DRAWER via window.show_drawer | ✓ |
| FR-036 stopped = full cockpit + seal | SR_SESSION.stop_and_seal; SR_COCKPIT; Continue-at-N | ✓ |
| FR-037 adaptive linger classes | SR_TOKEN classification + SR_TIMING_MODEL bands/cap/floor | ✓ |
| FR-038 foreign display rule | SR_STAGE_VIEW centered no-pivot; pivot_not_combining invariant | ✓ |
| FR-039 AI transliteration enrichment | SR_AI_JOB enrichment pass → is_foreign_term | ✓ (SHOULD) |
| FR-040 foreign-skip filter | SR_TOKEN.streams_under_filter; SR_SESSION.advance; skipped_count | ✓ |
| FR-041 micro-rewind / skip-forward | SR_SESSION.replay_sentence / skip_sentence_forward | ✓ |
| FR-042 transport keymap | SR_KEYS table (spec/06, D-014); media keys SHOULD | ✓ |
| FR-043 fisheye ribbon | SR_RIBBON_VIEW (D-015); context_window reuse; click = resume | ✓ |
| FR-044 program icon | app/resources/speed_reader.ico (generated, 7 sizes) + logo.svg; exe-embed + installer wiring at ship | ✓ (asset built) |
| FR-045 braking glide + live ribbon | SR_GOVERNOR apply/glide/release_brake; SR_RIBBON_VIEW braking overlay; SR_APP tap-vs-hold routing | ✓ |
| FR-046 brake-drag scrub gesture | SR_APP drag routing → SR_SESSION.scrub_back; brake events logged | ✓ |
| NFR-001 cadence | SR_PACER deadline-anchored (04) | ✓ |
| NFR-002 stop latency | state flip on command; next tick paints cockpit | ✓ |
| NFR-003 AI non-blocking | gateway region + mailbox (DR-009) | ✓ |
| NFR-004 book scale | flow_blocks pixel-budget sampling; ARRAYED_LIST tokens | ✓ |
| NFR-005 local-only | Ollama localhost; no other endpoints exist | ✓ |
| NFR-006 quality gates | contracts (05) + oracle test standard target | ✓ |

## Risk Mitigations Implemented

| Risk | Mitigation in Design |
|------|---------------------|
| RISK-001 jitter | Deadline anchoring in SR_PACER; ±1 tick bounded, zero cumulative drift; Phase-1 gate test defined (03/A-1) |
| RISK-002 quiz latency | Chunk-streamed SR_QUIZ_JOB; administration-time completeness only |
| RISK-003 Ollama drift | with_ollama config; is_available probe; ai_status_line honesty |
| RISK-004 hallucination | SR_QUIZ invariant all_verified + dropped_count honesty |
| RISK-007 fonts | FR-030 curated list; measured-advance pinning |
| RISK-008 map cost | flow_blocks (pixel_budget) pre-sampling; cursor-band repaint |

## Open Issues (carried to /eiffel.intent)

- OQ-1 flow map visible while running (design assumes YES — SR_APP running layout = stage + map)
- OQ-2 recovery_wpm fixed 250 vs proportional (design carries it as a settings value; default 250)
- OQ-3 quiz density (proposal: 3 questions per ~800 words, cap 10 — constant in SR_QUIZ_JOB)
- OQ-4 preview scope: questions only vs + AI outline (design accommodates either in cockpit quiz tab)
- OQ-5 default local model (bake-off task, Phase 2; with_ollama takes any)
- A-1 tick-rate validation is the first Phase-1 gate test

## Ship Deliverables (Larry, 2026-08-26 — tracked from design onward)

- Repo scaffolded 2026-08-26 (git init, standard README/CHANGELOG/.gitignore, docs/, USER_GUIDE)
- Ship phase must deliver: simple_* README (standard centered format), docs/index.html site,
  docs/USER_GUIDE.md kept current, GitHub repo under simple-eiffel org, Release binaries,
  **Windows installer** (Inno Setup, per simple_ocr_capture precedent — watch the
  /SUPPRESSMSGBOXES silent-uninstall gotcha), CHANGELOG discipline
- Timeline tracking: .eiffel-workflow/TIMELINE.md — stamp every phase milestone through
  installer build and Larry's approval (Larry's directive 2026-08-26)
- Design story: .eiffel-workflow/DESIGN_STORY.md is the ROLLING interaction narrative (Larry's
  directive 2026-08-26) — every accepted feature request gets an entry; ship phase publishes a
  polished version into docs/ for the Eiffel community

## Ready for Implementation

- [x] All requirements traced (46 FR + 6 NFR)
- [x] All risks mitigated in design
- [x] All principles satisfied
- [x] Design is complete (27 classes, contracts drafted, interfaces fixed)
- [x] D-011…D-016 refinements folded in (adaptive timing, three postures, foreign skip,
      transport, fisheye ribbon, analog braking + intervention ladder)
- [x] Icon asset generated (speed_reader.ico 7 sizes + logo.svg + icon-256.png)

**VERDICT:** READY
