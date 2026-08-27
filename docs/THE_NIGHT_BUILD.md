# The Night Build

*How simple_speed_reader went from a 55-second video to a tested, installed Windows
application in six and a half hours of wall clock — and what Design by Contract, a
pure-Eiffel toolkit, and a rolling conversation had to do with it.*

*Simple Eiffel ecosystem, 2026-08-26.*

---

## The seed

At 16:00 the input was a phone recording of someone else's speed reader: one word at a
time on a black screen, a red letter pinned dead center with tick marks above and below,
a `SPEED: 595 WPM` readout ramping past 800. Fourteen extracted frames later the
mechanics were on the table. The red letter is Spritz's *Optimal Recognition Point* —
pin it at a fixed screen X and the eye never saccades; the word does the moving. The
frames even yielded the pivot law by observation: length 1 pivots letter 1; 2–5 pivot
letter 2; 6–9 letter 3; 10–13 letter 4; 14 and up letter 5. That table went into a
contract before the evening was out, and one frame — "words," pivoting its *o* —
later refuted the first draft of it. The video was the spec, and the spec was testable.

## The turn that made it worth building

The obvious product was a drill toy. The owner's correction, minutes in: *this is not
about drilling but about actually reading.* That reframing had scientific teeth.
Schotter, Tran and Rayner showed in 2014 that RSVP's core harm is eliminating
*regressions* — the quiet backward glances that repair comprehension. Every word-stream
app on GitHub ignores that finding. So the spine of this one became the thing the
science demanded: one key out of the stream onto a readable context page, click the
word where comprehension was last solid, resume *there* at a crawl, ramp back up.
Getting lost costs seconds, not chapters.

The second demand was older: Robinson's SQ3R (1941) — survey and question *before*
reading. The owner asked for comprehension quizzes generated from any text before it is
read, reviewable in advance like a table of contents. A local model writes them; every
question must carry a quote verified **verbatim** against the text, or it is discarded
and counted. Speed without retention is a party trick. This reader keeps a ledger.

## The morning method

The Simple Eiffel spec kit ran first: a seven-step research phase (nineteen minutes —
five comparable readers surveyed, none closing the comprehension loop) and an
eight-step specification (thirty-nine minutes — 27 classes, every requirement traced,
contracts drafted before any code existed). The speed governor's invariant *is* the
product rule: `Min_wpm <= current <= target <= comfy_max`. The recovery command's
postcondition *is* the science: resume re-ramps from recovery speed. When the
specification says READY, implementation is transcription with a compiler holding the
pen.

One hard fact reshaped the architecture during specification: the ecosystem's Ollama
client is synchronous curl. So every model call lives in a separate worker *process*
the GUI spawns and polls by mailbox file — the pump can never meet a blocking call,
by construction.

## The build hour

Code began around 17:00. At 17:24 the engine — tokenizer, ORP law, timing model with
scholarly linger classes, deadline pacer, speed governor, session state machine —
passed **26 of 26 contract-assault tests, finalized, on the first F_code build**. At
17:37 the three-posture GUI was smoke-launched: running is only the stream; paused is
the readable context page; stopped is the cockpit. The smoke test itself caught a
crash (a timer armed before the native window existed — the precondition said so), and
that is the point: in this shop the contracts stay armed in finalized test builds, and
they earn their keep in the field.

## The feedback engine

From 17:53 onward the owner hand-tested and the requests came as fast as they could be
typed — thirty-three of them by night's end, each one logged in a rolling design story
the moment it landed. Drive switching in the file dialog. Typed paths. A freeze that
forensics traced to `DIRECTORY.exists` probing dead network drive letters (the fix:
`GetLogicalDrives`, which touches no media). UTF-8 mojibake that turned out to be an
ecosystem library bug, found on screen and logged upstream. A drawn VCR deck with a
brake pedal wearing the automotive brake-warning glyph — press and hold, and speed
*glides* to a crawl while a fisheye ribbon of the surrounding words flows along; drag
left to scrub backward; release and it eases home, politely restoring any pinned
speed. Explorer drag-and-drop. PDFs through Poppler, DLL-isolated so its private
cairo can never shadow the toolkit's. Speed tiers on the +/− keys. A crossfade mode
whose fade windows scale with the word's own display slot, so it self-attenuates at
speed. A word cloud, colorizing the ribbon by significance and opening as a scoped
Document / Section / Paragraph drawer. Edge tabs that peek on hover and pin on click.
The app's own icon — the word *read* with its lawful red *e* — in the title bar.

There was an intermission for church. The clock kept honest.

## What the contracts caught

Design by Contract is usually sold on theory. Here is one evening's docket. A
postcondition cursor shadowing a local: compile error, not a mystery. Void-safety's
VEVI rule forcing two-phase widget construction — every attached attribute set before
any agent may capture `Current`. A precondition on `set_fast_timer` that turned a
would-be silent failure into a named crash with the fix in its message. And three
separate bites from `STRING_32.to_string_8`, whose precondition rejects the first
non-ASCII character — the last one when a Greek word, δόξα, met the word cloud's
stopword gate. The fix was one guarded line; the crash text became a named regression
test asserting the *right* behavior (Greek terms rank in the cloud, as a theology
corpus deserves); and the lesson is now an oracle gotcha every future session reads
before writing code.

## What the ecosystem gained

The owner's standing doctrine — *factor abstractions back to the parent libraries as a
courtesy to the problem space* — turned one application's needs into thirteen
platform features, each landed with the parent library's own test suite green:

- **simple_widgets** — `give_focus` (programmatic keyboard focus); `handle_release`
  (the capture hears the pointer let go — the brake pedal's enabler); SW_CANVAS grown
  into a full-agent surface (keys, chars, release, shell drops, hover — the app's own
  surface class dissolved to nothing); `triangle_fill` and `arc_stroke` on the painter
  (glyph apps stay out of the cairo context); a drive-chip row and typed-path
  navigation in the file dialog.
- **simple_shell** — `logical_drives_mask` (drive letters without touching media);
  the stepping keys joined the pump's whitelist with `WM_SYSKEYDOWN` handled at last;
  `shell_set_window_icon` (a finalized Eiffel binary carries no resources — the icon
  loads from the multi-size .ico beside the exe).

Suites at close: widgets 198/198, shell 13/13, engine 41/41.

## Where it landed

A dark-only Windows reader, every pixel its own: the video-faithful stage with the red
pivot; ramp, hold, back-offs, and keyboard speed tiers; the recovery loop; micro-replay;
an analog brake; paragraph, section, and start-over navigation on a drawn deck; a
colorized fisheye ribbon; a scoped word cloud; scholarly timing that lingers on
Hebrew and Greek and never fakes a pivot on them; an optional foreign-script skip;
crossfade pacing; drag-and-drop and PDF intake; a local-AI comprehension quiz with a
verbatim-quote honesty gate; a SQLite ledger of every sitting — dialed speed, achieved
speed, rewinds, quiz score; crash-safe bookmarks and continue-where-you-left-off; a
7-second-compile Inno installer that ships two exes, the Poppler family, and an
uninstaller that asks before touching your reading history and never asks silently.

**The numbers:** one afternoon and evening; 6 hours 27 minutes of tracked wall clock
from video to the final feature; 41 commits across three repositories; roughly 6,900
lines of contracted Eiffel in the application alone; 252 tests green across the stack;
a 12 MB installer that compiles in under eight seconds.

## The row that waits

The timeline file that tracked all of this ends with one deliberately empty row:
**LARRY APPROVES**. The clock stops only there. After it: the hardening pass, the
GitHub repository under simple-eiffel with the installer attached to a Release, and a
1.0 tag.

The last screenshot of the night showed the ribbon reading a real essay — *Jesus*,
*temple*, *courts* burning by significance around the paused word — under a title bar
wearing the app's own mark. The owner's verdict on the evening: *perfect*.

---

*The unabridged engineering record — thirty-three asks and answers, every decision
dated — lives in `.eiffel-workflow/DESIGN_STORY.md` beside the research and
specification documents that started the day.*
