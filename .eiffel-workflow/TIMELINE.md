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
| Hand-test round 1: drive switching | 2026-08-26 17:53 | 1:53 | Larry's first feedback → SW_FILE_DIALOG drives row + go_to_drive (widgets 194/194); app rebuilt + hot-swapped |
| Hand-test round 2: typed paths + logging | 2026-08-26 18:00 | 2:00 | typed C:\ repro → dialog honors typed absolute/directory paths (198/198); simple_logger wired, first log line live |
| Hand-test round 3: freeze forensics | 2026-08-26 18:10 | 2:10 | 0%-CPU block → drive probes convicted → SHELL_DESKTOP.logical_drives_mask (GetLogicalDrives), dialog never probes; stale-EIFGENs trap caught + recorded |
| Hand-test round 4: paused screenshot | 2026-08-26 18:14 | 2:14 | paused row flex fix (full height), UTF-8 decode at facade (SIMPLE_FILE.content mojibake found + logged), paused control row added; engine 26/26, GUI smoke-verified |
| **INTERMISSION** — Larry to church | 2026-08-26 18:14 | 2:14 | build green across 3 repos, staged for his return; ribbon/drawers/braking/AI/log/installer queued |
| Back on the clock — the night build begins | 2026-08-26 ~18:55 | 2:55 | "let's get this thing done tonight" |
| Persistence slice green | 2026-08-26 ~19:05 | 3:05 | SR_SETTINGS + SR_LOG (SQLite) + Continue-at-word-N; 29/29 |
| Ribbon + Speed drawer | 2026-08-26 ~19:12 | 3:12 | fisheye above the context page; drawer with dial/hold/back-offs |
| BRAKING live | 2026-08-26 ~19:20 | 3:20 | handle_release added to widgets (198/198); glide/scrub/ease + hold-restore; 32/32 |
| AI quiz pipeline LIVE-verified | 2026-08-26 ~19:33 | 3:33 | worker exe → Ollama 11435 Qwen3-8B → 5 real quote-anchored questions from the sample; quote gate + SQ3R preview + self-judged admin; 35/35 |
| **Installer built** | 2026-08-26 19:38 | 3:38 | SimpleSpeedReader-0.9.0-Setup.exe, 7 MB — ISCC compile 7.8 s (rebuild 5.8 s with final guide) |
| v0.9.0 feature-complete, docs refreshed | 2026-08-26 19:40 | 3:40 | README/CHANGELOG/USER_GUIDE tell tonight's truth; awaiting the row below |
| Late round: drops + PDFs + the deck + factoring | 2026-08-26 20:02 | 4:02 | Explorer drag-drop everywhere; pdftotext intake (live on ECMA-367!); drawn VCR deck w/ brake pedal; SW_CANVAS + SW_PAINTER grew five donated features (198/198); installer rebuilt 5.9 s |
| Poppler family fix + full-time deck | 2026-08-26 20:15 | 4:15 | DLL-isolated pdf\ (24 DLLs, bisected); deck rides every posture, state-aware PAUSE/REPLAY, live pedal |
| Keys volley: tiers, Alt-font, B, tooltips | 2026-08-26 20:29 | 4:29 | shell keymap donation (13/13); +/- 25/50/100; Alt±4pt persisted; 21px honest readout; B brake toggle; hover combos everywhere (SW_CANVAS.on_hover donation); engine 36/36 |
| Structure navigation: START/PARA/SECT | 2026-08-26 20:43 | 4:43 | 10-zone VCR deck; section detection (md # + standalone headings), SECT ghosts without structure; fresh-ramp start-over; engine 38/38 |
| Progress bar + Cross_stretch layout fix | 2026-08-26 20:58 | 4:58 | SW_PROGRESS under the stage, all postures; the floating-band bug (row cross-axis centered) cured |
| Fade mode (WPM-scaled crossfade) | 2026-08-26 21:49 | 5:49 | fade_alpha curve in the timing model (39/39); fade-in 30%, melt into breathers only, self-attenuates at speed |
| Fade toggle everywhere + window icon | 2026-08-26 ~22:00 | 6:00 | F key + drawer toggle + synced checkbox; shell_set_window_icon donation (13/13) - the r-e-ad mark in the title bar |
| Colorized fisheye + scoped word cloud | 2026-08-26 22:15 | 6:15 | SR_WORDCLOUD (stopworded incl. KJV register) tiers the ribbon's colors; 40px center, 92px band; W opens the Document/Section/Paragraph cloud drawer; engine 40/40 |
| Greek crash fixed + edge tabs wired | 2026-08-26 22:27 | 6:27 | third to_string_8 bite (named regression test; oracle gotcha); Speed/Cloud as right-edge peek-and-pin tabs; deck CLOUD button; focus self-heal after drawers; 41/41 |
| **LARRY APPROVES deliverable** | — | — | THE finish line for this clock |

Still ahead of a 1.0 tag: hardening pass (Phase 6 adversarial tests), GitHub repo + Release
(ship phase) — after the approval row fills.

## Rules for future sessions

1. Append a row the moment a milestone lands; use the actual clock (`date "+%Y-%m-%d %H:%M"`).
2. "Elapsed" is wall-clock from 2026-08-26 16:00 — calendar-honest, not effort-hours. If sessions
   span days, that is the truth this file exists to record.
3. Also log each milestone to the oracle: `oracle-cli.exe log info simple_speed_reader "..."`.
4. The clock stops ONLY at Larry's explicit approval of the delivered app (installer included).
