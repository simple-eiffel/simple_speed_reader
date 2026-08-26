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
