# TIMELINE: simple_speed_reader

**Larry's directive (2026-08-26):** Track when this task started and how long it takes to reach a
deliverable Larry approves of, INCLUDING installer build time. Every session working this project
MUST append milestone rows here (timestamp from `date`, not memory) until the Approval row is
filled.

## Clock

**Task started:** 2026-08-26 16:00 (video frame extraction of read-speed-drill.mp4 — first work
on the idea; timestamps below from file system / oracle log, local time UTC-4)

| Milestone | Timestamp | Elapsed from start | Notes |
|-----------|-----------|--------------------|-------|
| Task start (video analysis) | 2026-08-26 16:00 | 0:00 | 14 frames extracted; RSVP/ORP pattern decoded |
| Name chosen | 2026-08-26 ~16:05 | 0:05 | simple_speed_reader (Larry, from 4 candidates) |
| Research complete (7/7, BUILD/HIGH) | 2026-08-26 16:19 | 0:19 | 4 web searches, 5 comparables, Schotter/SQ3R grounding |
| Spec complete (8/8, READY) | 2026-08-26 16:39 | 0:39 | 26 classes, 39 requirements traced |
| Design refinements D-011…D-014 folded | 2026-08-26 16:55 | 0:55 | adaptive timing, 3 postures + drawers, foreign skip, transport keymap (42 FRs) |
| Repo scaffolded (README/docs/user-guide/git) | 2026-08-26 16:55 | 0:55 | honest in-design status |
| D-015/D-016 + icon + design story | 2026-08-26 17:02 | 1:02 | fisheye ribbon, analog braking (intervention ladder), 7-size .ico + logo.svg, rolling DESIGN_STORY.md (46 FRs) |
| /eiffel.intent complete | (skipped — Larry called for code; open questions resolved in-build) | — | |
| Engine implemented + contracts compile | 2026-08-26 ~17:20 | 1:20 | 9 classes; one VEEN fix (assertion cursor shadowing local) |
| **Engine tests green** | 2026-08-26 17:24 | 1:24 | **26/26 PASS, F_code, first finalize** (exe mtime) |
| GUI implemented + finalized | 2026-08-26 17:35 | 1:35 | 6 app classes; VEVI two-phase creation lesson; SW_WINDOW.give_focus added (widgets 193/193 re-verified) (exe mtime) |
| GUI smoke-launch verified | 2026-08-26 17:37 | 1:37 | fast-timer-needs-hwnd crash caught + fixed (arm on first heartbeat); window up and pumping |
| Hardened (Phase 6) | — | — | |
| Shipped (Phase 7): repo + docs + Release | — | — | |
| **Installer built** (Inno Setup) | — | — | include build duration itself |
| **LARRY APPROVES deliverable** | — | — | THE finish line for this clock |

## Rules for future sessions

1. Append a row the moment a milestone lands; use the actual clock (`date "+%Y-%m-%d %H:%M"`).
2. "Elapsed" is wall-clock from 2026-08-26 16:00 — calendar-honest, not effort-hours. If sessions
   span days, that is the truth this file exists to record.
3. Also log each milestone to the oracle: `oracle-cli.exe log info simple_speed_reader "..."`.
4. The clock stops ONLY at Larry's explicit approval of the delivered app (installer included).
