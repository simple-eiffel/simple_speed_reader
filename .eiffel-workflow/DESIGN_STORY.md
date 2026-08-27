# The Design Story — simple_speed_reader

> A rolling narration of how this application is being designed: each feature request as it
> arrived, and what the design did with it. Kept for the Eiffel community as a worked example of
> specification-first, contract-first development with an AI pair. Requests are paraphrased for
> concision; the verbatim engineering record is `.eiffel-workflow/research/04-DECISIONS.md`
> (D-001…) and the phase documents beside it.
>
> **Rolling rule:** every session that accepts a new feature request appends an entry here,
> same format: *The ask → What the design did with it.* This file lives beside the phase
> documents (research/, spec/); publishing a polished version into docs/ is a ship-phase
> deliverable.

---

## Day one — 2026-08-26 (idea to specified system in an afternoon)

### 1. The seed: "build what's in this video" (16:00)
**The ask.** A 55-second screen capture of an RSVP reader — one word at a time on a black
screen, a red pivot letter with tick marks, a WPM readout ramping past 800. Build this with
simple_widgets: settable text, speed, and font; dark-mode only; a local-AI preprocessor for
unfriendly source text; and along the left edge, an unreadable miniature of the whole text with
a cursor tracking the flowing word.
**What the design did.** Decoded the video frame-by-frame (the pivot is Spritz's Optimal
Recognition Point, pinned at fixed X; speeds sampled 300→803 WPM; blank breathers at sentence
ends). Verified every needed capability already existed in the ecosystem — SW_CANVAS delegate
drawing, cairo text extents for pivot alignment, a millisecond fast-timer in simple_shell,
OLLAMA_CLIENT in simple_ai_client. Name chosen from candidates: **simple_speed_reader**.

### 2. The identity correction: "this is not about drilling — it's about actually reading"
**The ask.** The tool is for consuming real texts. When attention lapses, the reader must be
able to stop, back up to the last point they truly comprehended, and restart slow (200–300 WPM),
ramping back toward a personal ceiling (~900). Wanted besides: a hold-at-current-speed control;
back-off buttons (−100/−50/−25); a persistent log of speed AND comprehension; comprehension
tests generated from any chosen text BEFORE reading it, opt-in; and the option to review those
questions beforehand — the way one reads a table of contents to form a mental model first.
A drill mode with practice texts stays, but as a secondary feature.
**What the design did.** This reframing became the product's spine, and it turned out to have
scientific footing: Schotter, Tran & Rayner (2014) showed RSVP's core harm is eliminating
regressions — exactly what the requested recovery loop restores. The quiz-preview instinct is
the classic SQ3R method (Robinson, 1941) operationalized by a local model. Formal research phase
run (7 steps, five comparable readers surveyed — none has either loop). Recommendation:
BUILD, confidence HIGH.

### 3. "The GUI is ONLY the word-stream while running"
**The ask.** When the stream is flowing, nothing else is on screen. Everything else belongs to
pause or stop.
**What the design did.** Became a layout doctrine (later refined by #6): the running posture is
the stage, the flow map, the WPM readout — and keyboard-first control.

### 4. The formal phases: research → specification
**What the design did.** The Spec Kit pre-phases produced 8 research documents and 8
specification documents: 27 classes, each with one responsibility; contracts drafted before any
code (the speed governor's invariant *is* the product rule: `current ≤ target ≤ comfy_max`);
a headless engine facade so the whole reading loop is testable without a window. One hard fact
reshaped the architecture: the Ollama client is synchronous curl, so all AI lives in a
`separate` SCOOP gateway posting results to a mailbox the UI polls — the pump cannot freeze on a
model call, by construction.

### 5. "Should presentation time vary by word size — and by language? Hebrew, Greek, transliterations?"
**The ask.** Wondered about throttling per word: character or syllable count; English vs foreign.
**What the design did.** Characters yes (graduated bands), syllables no (they add almost nothing
beyond length and fail exactly on foreign words). The deeper win was language: Hebrew/Greek
script is detected deterministically from Unicode blocks — those words linger (never faster than
an effective 350 WPM) and render centered *without* the red pivot, because ORP research is
Latin-specific and a naive pivot index could land on a niqqud mark. Diacritic transliterations,
numerals, and acronyms (LXX, MT, YHWH) each got their own linger class. Bare-ASCII
transliterations ("bereshit") are undetectable by rule — the AI preprocessor tags them. (D-011)

### 6. "Pause is always available; paused controls are drawered; stopped un-drawers everything"
**The ask.** A pause affordance always present; while paused, controls live in slide-out
drawers; a full stop deploys the complete control surface.
**What the design did.** Three postures (D-012): RUNNING (stream + one dim pause mark), PAUSED
(readable context page, controls in SW_DRAWER panels, sitting still alive), STOPPED (full
cockpit; the sitting is sealed — record logged, position kept). The pause/stop distinction gave
the session state machine its final shape.

### 7. "Turn off non-English — except transliterations"
**The ask.** An option to stream past Hebrew/Greek entirely.
**What the design did.** A one-predicate filter — `script /= latin` — so transliterations
survive automatically. Presentation-only: the context page and flow map always show the true
text, and skipped words are counted in the log so the achieved-WPM figure stays honest. (D-013)

### 8. "What are the standard transport keys, and what do those states do?"
**The ask.** Ground Play/Pause/Stop/Rewind/Forward in convention.
**What the design did.** Adopted media-player muscle memory (Space/K, Esc/S, Left/Right seeks)
with the *sentence* as the seek unit, plus two deliberate deviations, both comprehension-driven:
resume after a pause re-ramps from recovery speed rather than resuming at pace, and stop keeps
your place (audiobook convention, never VLC's reset). Fell out of the analysis: the in-flow
**micro-rewind** — tap Left mid-stream and the previous sentence replays without breaking
stride. (D-014)

### 9. "Track how long this takes — from start to a deliverable I approve, installer included"
**What the design did.** TIMELINE.md with wall-clock milestones (start 16:00; research 16:19;
spec 16:39) and a standing rule that every future session stamps its milestones until the row
that matters: approval.

### 10. "Prep it for GitHub — standard simple_* README, docs, a user guide"
**What the design did.** Repo scaffolded and committed locally: ecosystem-standard README with
an honest "In Design — no code yet" status (the stale-README incident is remembered), CHANGELOG,
docs landing page, and a USER_GUIDE that is already the binding design of postures and keys.

### 11. The fisheye ribbon (sketched with a "Smaller"-letters image)
**The ask.** When paused, show where we are as one line of words — tiny at the left, growing to
the biggest current word at center, shrinking again to the right. "A word-cloud thing, except in
a straight line."
**What the design did.** Recognized it as a focus+context (fisheye) view — Furnas, 1986 — and
added SR_RIBBON_VIEW: real surrounding words, size falling off geometrically with distance from
center, streamed side normal / upcoming side dimmer, every word clickable as a resume point.
(D-015)

### 12. "Make an interesting icon — installer and window"
**What the design did.** The app's own stage in miniature: the word **read** with its ORP letter
— by the app's own pivot law, the *e* — in red, tick marks above and below, on the near-black
stage. Generated per-size (full word at ≥48 px, a white *r* between red ticks at 32/24/16),
assembled into a 7-resolution .ico plus an SVG logo, by a checked-in script.

### 13. "Apply braking" — the analog control
**The ask.** Hold a brake: speed eases down from cruise to ~300 while the fisheye ribbon flows
along live; drag left to full-stop and scrub back a little; drag right to re-engage; release to
glide back up to the speed you were at.
**What the design did.** The missing middle rung. The design now has a graduated
**intervention ladder** — tap Left (lapse: replay a sentence at pace) → hold BRAKE (wobble:
slow down, see context, nudge back, never leave the stream) → Pause (loss: readable page,
marked recovery, re-ramp) → Stop (seal the sitting). Braking is a governor overlay with its own
contracts: glide monotone toward the floor, cruise speed remembered, hold-state restored on
release. Stage quick-tap pauses; stage press-and-hold brakes. (D-016)

### 14. "Keep a rolling log of this process"
**What the design did.** This document — and the rule at the top that keeps it rolling.

### 15. "Do we have testing like the other simple_* libs? Then give me an F_code binary and a sample text."
**The ask.** Testing to the ecosystem standard (simple_ocr_capture and simple_json named as the
models), then a runnable build to try.
**What the design did.** Became the build day. Nine engine classes written contracts-first from
the specification — and the contracts immediately earned their keep: the compiler caught an
assertion cursor shadowing a local (VEEN), void-safety forced the two-phase creation idiom
(every attached attribute set before any agent may capture Current — VEVI), and the smoke launch
caught set_fast_timer's needs-a-window precondition, fixed with the arm-on-first-heartbeat
pattern from ocr_capture. One genuine spec correction fell out of implementation: frame f10
("words" pivoting its 2nd letter) refuted the drafted ORP table; the law is 1 / 2–5 / 6–9 /
10–13 / 14+ → pivot 1/2/3/4/5, now frame-verified in test_pivot_law. Result, same afternoon as
the idea: **26/26 engine tests green in F_code on the first finalize**, the three-posture GUI
finalized and smoke-launched, simple_widgets extended with one additive feature (give_focus,
its own 193/193 suite re-run), and a demo text written to exercise every linger class — Hebrew,
Greek, transliterations, Strong's numbers, the LXX. Deferred honestly: AI pipeline, persistent
log, ribbon, braking, installer.

### 16. "Allow me to change drives when opening a file" (first hand-test feedback)
**The ask.** Minutes into using the build: the drawn file dialog could not leave drive D:.
**What the design did.** Fixed it where it belonged — in simple_widgets itself, since every
Windows app needs it. SW_FILE_DIALOG gained `available_drives` (probes A: through Z: with plain
base DIRECTORY, keeping the toolkit's dependency-free doctrine; the row simply never appears on
driveless platforms), a public `go_to_drive` with contracts (require the root exists, ensure the
listing landed), and a chip row of live drives between the path and the listing. One new assault
test (`drive_roots_and_hop`); suite 194/194; the reader rebuilt against it and hot-swapped on
the desktop within minutes of the request. First feedback loop of the hand-test: closed.

### 17. "Add simple_logging... and typing C:\ then Open didn't switch drives"
**The ask.** Two-in-one hand-test report: wire in logging, and the natural gesture — typing a
path into the name box and pressing Open — did nothing useful.
**What the design did.** The typed path was being glued onto the current directory
("D:\...\C:\"). SW_FILE_DIALOG now honors what the person typed: absolute text (drive-rooted or
UNC) wins over the join, a bare "C:" normalizes to "C:\", and when the target is a *directory*
the dialog navigates there instead of accepting it — so typed drive hops, typed child-folder
descents, and typed absolute file paths all behave. The verbatim repro became a named assault
test (plus three siblings); suite 198/198. And simple_logger now writes speed_reader.log beside
the exe — app lifecycle, intake outcomes, starts, pauses, recovery marks, and each sealed run's
honest summary — so the next report arrives with its own evidence attached.

### 18. "The software froze" — then, minutes later, "finally came up"
**The ask.** A freeze report, live: clicking near the text box locked the window. Larry left the
frozen instance up for diagnosis — and then it unfroze on its own.
**What the design did.** Live forensics first: sampling the hung process showed 0% CPU — a
*blocked call*, not a loop — and "finally came up" turned the deadlock into a minutes-long block
that returns. That signature convicted the newest code: the drives row was probing `A:\`–`Z:\`
with `DIRECTORY.exists`, and a dead network letter or empty card slot waits out an SMB timeout
per probe, right on dialog open. The cure went into the platform layer: simple_shell gained
`logical_drives_mask` (Win32 `GetLogicalDrives` — answers without touching media), the dialog
now builds its chips from the mask and never probes, and even `go_to_drive`'s precondition was
softened to a shape check because a contract that probes is a contract that hangs. Along the way
the build tripped, diagnosed, and recorded a second trap — editing a library class can leave a
consumer's EIFGENs cache stale, while the old test exe happily prints ALL TESTS PASSED — and the
cockpit's paste box had its spell-checker turned off before a pasted book could grind the pump.
Suites: widgets 198/198 on a verified-fresh build.

### 19. The paused-posture screenshot: "no control, no drawers, no fisheye — you tell me?"
**The ask.** A screenshot mid-hand-test: the paused view worked (marked word, readable page,
scrubber) but sat in a short band atop an empty window, the file's Greek rendered as mojibake,
and none of the promised paused furniture was visible.
**What the design did.** Three verdicts. The band was a one-line flex bug — the paused row never
asked to grow inside its column (`set_grow (1.0)`; the running posture was unaffected because
its row IS the root). The mojibake was an ecosystem find: `SIMPLE_FILE.content` claims UTF-8 but
widens raw bytes char-per-byte; the facade now decodes properly itself (`binary_content` →
`SIMPLE_ENCODING.utf_8_to_utf_32`, BOM stripped) and the bug is logged against simple_file. And
the missing furniture was told straight: drawers and the fisheye ribbon are specified but not
yet built — though the paused posture gained a visible control row (Resume at sentence head ·
Resume exactly here · Stop) so the keyboard is no longer the only door. Engine 26/26 again.

---

## Intermission — 2026-08-26, evening

Larry logs out for church, mid-hand-test, with the reader working "kinda okay" and three
feedback rounds already closed the same day the idea arrived. The build stands green and
committed across three repos (speed_reader, simple_widgets, simple_shell); the fixed build is
staged and smoke-verified, waiting to be launched when he returns. Still queued from his list:
the fisheye ribbon, the drawered pause furniture, braking, the AI quiz pipeline, the persistent
log, the installer. The clock in TIMELINE.md keeps running — wall-clock honest — until the row
that matters: LARRY APPROVES.

## The night build — 2026-08-26, evening

### 20. "Okay ... I am back and we're back on the clock. Let's get this thing done ... tonight!"
**The ask.** Everything. Tonight.
**What the design did.** Five slices, each compiled, tested, and committed before the next.
*Persistence*: the profile (simple_config, UTF-8-safe even for Hebrew filenames) and the SQLite
ledger — every sealed sitting a row; position bookmarked crash-safe on every pause; Continue-
where-I-left-off through a new contracted `preset_position`. *The fisheye ribbon*, landed above
the paused context page exactly as sketched. *The Speed drawer* — the paused furniture D-012
promised. *Braking* — which first required teaching simple_widgets that a pointer can let go
(`handle_release`, the toolkit's third new feature this project demanded): hold the stage and
speed glides to 300 at ~500 wpm/s while the ribbon flows with the live word; drag left and the
stream halts and scrubs backward proportionally; release and it eases home, politely restoring
any HOLD pin it had to lift. And *the AI quiz pipeline*: a second headless exe the GUI spawns
(the pump never meets curl), Qwen3 think-blocks stripped, the JSON slab extracted, written
atomically, polled by heartbeat — and every question's supporting quote verified VERBATIM
against the text, hallucinations dropped and counted. First live run against the machine's own
Ollama: five real questions about the demo essay, quotes anchored, on the first try. Then the
installer — Inno, both exes, the icon, the guide, a per-user install whose uninstaller asks
before touching the reading ledger and never asks silently (the ocr lesson, honored). Compile
time for the installer itself: under eight seconds. Engine 35/35; widgets 198/198; idea to
feature-complete-with-installer: **3 hours 40 minutes of wall clock, one afternoon and one
evening.** The clock now waits on one row.

### 21. "THIS is really good! ... drag-n-drop ... and PDFs?"
**The ask.** Drop .md/.txt files from Explorer onto the reader; and can PDFs be pulled apart to
raw text — cairo bits, maybe?
**What the design did.** Drag-and-drop was already sleeping in the toolkit (WM_DROPFILES through
the widget spine): every reading surface now accepts drops, the cockpit grew a visible drop
tray, and a drop mid-read seals the sitting honestly before loading. For PDFs, cairo was the
wrong tree — it *writes* PDF surfaces — but the family had the answer: simple_pdf bundles
Poppler's pdftotext, and the first live extraction the reader ever did was on the ECMA-367
Eiffel standard itself. Scans without a text layer are refused with a straight sentence, and the
hip-pocket fallback is recorded: Windows.Data.Pdf rasterization + the machine's own olmOCR model
if Poppler ever disappoints.

### 22. "Tape-player controls ... and I don't see a brake button (make a pedal symbol if you don't have one)"
**The ask.** VCR-styled transport instead of text buttons, with a visible brake.
**What the design did.** The deck: a drawn transport bar — PLAY, HERE, STOP, the BRAKE pedal,
and a SPEED dial — every glyph painted, labeled like a deck, and the brake wearing the
automotive brake-warning mark (circle, exclamation, flanking arcs: any driver knows it). The
pedal is not decoration: press and HOLD it while paused and the stream resumes braked at the
crawl with the ribbon flowing; release and it eases up to cruise. It reddens while braking.

### 23. "Factor abstractions back to the parent libraries - a courtesy to the ecosystem"
**The ask.** Reusable code discovered downstream belongs upstream.
**What the design did.** Two donations the same hour they were identified. SW_CANVAS absorbed
the whole idea of SR_SURFACE - key, char, release, and shell-drop agents with
focus-follows-interest semantics - and the app's own surface class dissolved to nothing.
SW_PAINTER gained triangle_fill and arc_stroke, so glyph-drawing apps stay out of the cairo
context entirely. Widgets suite: 198/198 both times. The toolkit is five features richer than
the morning found it, every one demanded by a real application.

### 24. The PDF drop that died — "poppler.dll was not found"
**The ask.** A screenshot of Windows' own error dialog.
**What the design did.** The copied exe had left its family behind: pdftotext needs poppler.dll
and twenty-three companions, resolved from the exe's OWN directory. The set was found by
isolation-directory bisection (never by guessing imports), and it ships DLL-isolated in a
`pdf\` subfolder — non-negotiable, because poppler carries its own cairo.dll, and the one time
it nearly shadowed the app's, only the running instance's file lock stopped it. Gotcha recorded;
proven from the app's own working directory; installer 12 MB with the family aboard.

### 25. "I need these visible to click and use while the reader is reading"
**The ask.** The deck, full-time.
**What the design did.** The product owner amended his own zero-chrome doctrine, and the deck
learned state: PAUSE bars while the stream flows, PLAY when it doesn't; REPLAY mid-read (this
sentence again, at pace), HERE when paused; the pedal engages the brake live exactly as the
stage hold does; the speed drawer opens over the moving stream for live tuning. And thanks to
focus-follows-interest — donated to SW_CANVAS an hour earlier — deck clicks never steal the
keyboard from the stage.
