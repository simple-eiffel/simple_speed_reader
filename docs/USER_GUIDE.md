# simple_speed_reader — User Guide

> v0.9.0 — everything below is built and shipping in the installer.

## What it is

An RSVP reader: one word at a time at a fixed point on a dark screen, the pivot letter in red so
your eye never moves. Speed ramps from a comfortable start toward your ceiling ("comfy-max",
default 900 WPM). When your mind wanders — and it will — recovery is one key, not a lost chapter.

## The three postures

| Posture | What you see | How you got here |
|---------|--------------|------------------|
| **Running** | Only the stream: the word stage, the flow map on the left, the dim `SPEED: N WPM` readout, and one dim pause mark. Nothing else. | Space/Enter from paused, or Start from the cockpit |
| **Paused** | The **fisheye ribbon** on top — one line of the surrounding words, tiny at the edges swelling to your current word at center: where you are, at a glance. Below it, the **context page**: the surrounding paragraphs as normal readable text, your stopped word marked. A control row (Resume at sentence head · Resume exactly here · Stop · **Speed >**) sits at the bottom; Speed opens a drawer with the live dial, hold, back-offs, and nudges. The flow map becomes a click-to-seek scrubber. Clicking a word — in the ribbon or the page — sets where reading resumes. | Space, a quick tap on the stage |
| **Braking** | Press and **hold** the stage (~¼ s) and the pedal engages: speed glides down to 300 while the fisheye ribbon appears above the stage and flows with the live word (`[BRAKE]` in the readout). **Drag left** past 40 px: the stream halts and scrubs backward, faster the further you drag. **Drag right**: forward flow re-engages. **Release**: speed eases back up to the cruise you were at — and a held pin comes back by itself. | Hold the stage mid-read |
| **Stopped** | The full cockpit: load text, settings, quiz, history, and **Continue at word N** if you were mid-book. Stopping *seals the sitting*: your run is logged and your place saved. | Esc (or S) from anywhere; or finishing the text |

## Keys (media-player muscle memory; the seek unit is the *sentence*)

| Key | While running | While paused |
|-----|---------------|--------------|
| **Space** (or K) | Pause — context page appears | Resume at start of current sentence, at recovery speed |
| **Enter** | — | Resume at the word you clicked |
| **Esc** (or S) | Stop: seal the sitting, open cockpit | Same |
| **Left** | Micro-rewind: replay from the previous sentence start — the stream keeps flowing, speed unchanged | Move the resume point back a sentence |
| **Right** | Skip to the next sentence (skipped words are logged) | Move the resume point forward a sentence |
| **Ctrl+Left / Ctrl+Right** | Same, by paragraph | Same |
| **Up / Down** (or . / ,) | Speed target +25 / −25 WPM | Same |
| **H** | Hold speed at current (ramp freezes); press again to release | Same, for the resume |
| **B** | Brake **toggle**: press to glide down to 300 with the ribbon flowing, press again to ease back to cruise (the mouse pedal is hold-to-brake; a key can't hear its own release) | Resume *braked* into the stream; B again to ease up |
| **+ / -** (or =) | Speed target ±25 · **Shift** ±50 · **Ctrl+Shift** ±100 (numpad too) | Same |
| **Alt + / -** | Stage font size ±4 pt (persists to your profile) | Same |
| **1 / 2 / 3** | Back off by 100 / 50 / 25 WPM | Same |
| **Home** | — | Resume point to the start of the text |
| Hardware media keys | Play/Pause = Space · Stop = Esc | Same |

**Two deliberate differences from a video player:**
1. Resuming after a pause does NOT continue at full speed — it restarts at your recovery speed
   (default 250 WPM) and ramps back up. Re-reading a little at low speed is how comprehension
   recovers. For a mere blink-length lapse, use **Left** (micro-rewind) instead: one sentence
   replays without breaking stride.
2. **Stop keeps your place** (like an audiobook app), it never resets to the beginning.

**Discovery:** rest the mouse on anything — every control (each deck button included) carries a
tooltip naming its key-combo. All of it persists: font size, speeds, filters, and opt-ins reload
from `speed_reader.cfg` on every start.

## The recovery loop (why this reader exists)

1. Mind wanders. Hit **Space**.
2. Read the context page like a normal page — that's the point.
3. Click the word where you were last truly solid (or just hit Space again to take the
   start-of-sentence default).
4. The stream resumes *there*, slow, climbing back toward your target.

## Speed governance

- Session starts at your start speed (200–300) and ramps toward your comfy-max.
- **H** pins the ramp when the current pace feels right; **1/2/3** back it off when it doesn't.
- Back-offs change this session's target, never your saved comfy-max.
- The readout shows the dialed speed; your log records the *achieved* speed too (breathers,
  rewinds and skips included). The difference is information, not shame.

## Scholarly text (Hebrew, Greek, transliterations)

- Words in Hebrew or Greek script automatically linger (they display as if the dial read ≤350)
  and render centered without the red pivot — the pivot trick is for Latin script.
- Transliterations with diacritics (ḥesed, agapē), numbers and refs (Gen 1:3, H7225), and
  acronyms (LXX, MT, YHWH) each get their own linger.
- Optional: **foreign-script skip** streams past Hebrew/Greek glyphs entirely (transliterations
  stay). The context page and flow map always show the full true text.
- With the AI preprocessor on, bare transliterations like "bereshit" get tagged to linger too.

## The quiz (opt-in)

Tick **Comprehension quiz** in the cockpit. From then on, the moment a text loads, a background
worker asks your local model to write a short quiz from it — before you read a word. The stream
never waits: generation runs in its own process and the status line reports when it's ready.
- **Preview questions** (the SQ3R study move) opens a drawer with just the questions — read them
  first to prime what to look for.
- Every question carries a supporting quote verified **verbatim** against your text. A question
  that can't prove itself is dropped, and the status line tells you how many were.
- After you stop or finish, the cockpit administers the quiz: read the question, **Show the
  answer**, then judge yourself — *I got it* / *I missed it*. Honest self-scoring beats a machine
  guessing at your phrasing.
- The score lands in that run's ledger row. Speed without retention is a party trick; this is
  the honesty meter.

Requires a local [Ollama](https://ollama.com) server (URL and model live in `speed_reader.cfg`;
defaults to `http://localhost:11435`). Without one, everything else works normally and the
status line says exactly why the quiz didn't arrive.

## Getting text in

Three doors, all equal: **paste** into the cockpit box; **Load .txt / .md / .pdf** through the
file dialog (drive chips included); or **drag a file from Explorer** and drop it anywhere on the
window — the cockpit's drop tray, the stage, even mid-read (the current sitting is sealed
honestly first). PDFs go through a bundled extractor (Poppler's pdftotext): the text layer
streams like any text; a pure scan without one is refused with a straight answer.

## The deck

A drawn tape deck rides the bottom of **every posture** — clickable while the stream flows:
**PAUSE/PLAY** (state-aware: bars while running, triangle while paused), **REPLAY/HERE**
(running: this sentence again at pace; paused: resume exactly where you stopped), **STOP**,
the **BRAKE pedal** — press and *hold* it mid-read to glide down to the crawl with the ribbon
flowing (it turns red), release to ease back to cruise; from paused it re-enters the stream
braked — and the **SPEED** dial, which opens the speed drawer even over the running stream.

## Continue where you left off

Your position is bookmarked on every pause and stop (crash-safe). **Continue where I left off**
in the cockpit reloads the last file and resumes at the saved word, at recovery speed.

## Your ledger

Every sealed sitting records: date, text, words streamed/skipped, dialed peak and achieved WPM,
pauses and rewinds, quiz score. The cockpit lists your newest six runs; the full ledger is
`speed_reader.db` (SQLite) beside the exe — local only, never leaves your machine.
