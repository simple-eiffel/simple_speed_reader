# simple_speed_reader — User Guide

> **Design preview.** This guide describes the designed product (spec of 2026-08-26).
> The app is not yet built; keys and behaviors here are the binding design and will be
> kept current through implementation.

## What it is

An RSVP reader: one word at a time at a fixed point on a dark screen, the pivot letter in red so
your eye never moves. Speed ramps from a comfortable start toward your ceiling ("comfy-max",
default 900 WPM). When your mind wanders — and it will — recovery is one key, not a lost chapter.

## The three postures

| Posture | What you see | How you got here |
|---------|--------------|------------------|
| **Running** | Only the stream: the word stage, the flow map on the left, the dim `SPEED: N WPM` readout, and one dim pause mark. Nothing else. | Space/Enter from paused, or Start from the cockpit |
| **Paused** | The **fisheye ribbon** on top — one line of the surrounding words, tiny at the edges swelling to your current word at center: where you are, at a glance. Below it, the **context page**: the surrounding paragraphs as normal readable text, your stopped word marked. Controls are tucked into edge drawers (Speed · Quiz · Settings) — pull one out if you need it. The flow map becomes a click-to-seek scrubber. Clicking a word — in the ribbon or the page — sets where reading resumes. | Space, clicking the stage, or the pause mark |
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
| **1 / 2 / 3** | Back off by 100 / 50 / 25 WPM | Same |
| **Home** | — | Resume point to the start of the text |
| Hardware media keys | Play/Pause = Space · Stop = Esc | Same |

**Two deliberate differences from a video player:**
1. Resuming after a pause does NOT continue at full speed — it restarts at your recovery speed
   (default 250 WPM) and ramps back up. Re-reading a little at low speed is how comprehension
   recovers. For a mere blink-length lapse, use **Left** (micro-rewind) instead: one sentence
   replays without breaking stride.
2. **Stop keeps your place** (like an audiobook app), it never resets to the beginning.

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

When you load a text, the local model starts writing a short quiz from it — before you read.
- **Preview** the questions first if you like (the SQ3R study move: it primes what to look for).
- After reading, take the quiz in the cockpit. Every question carries a supporting quote that
  verifiably occurs in your text — a question that can't prove itself is discarded.
- Scores land in your history next to your speeds. Speed without retention is a party trick;
  this is the honesty meter.

Requires a local [Ollama](https://ollama.com) server (configurable URL/model in Settings).
Without one, everything except the AI features works normally.

## Your log

Every sealed sitting records: date, text, words streamed/skipped, dialed and achieved WPM,
pauses and rewinds, quiz score. The history panel charts your trend. It's stored locally
(SQLite) and never leaves your machine.
