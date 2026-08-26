# LANDSCAPE: simple_speed_reader

**Date:** 2026-08-26 — all URLs below returned by live web search this date.

## Existing Solutions

### Spritz (the technique's commercial origin)
| Aspect | Assessment |
|--------|------------|
| Type | SDK / SERVICE |
| Platform | Web/mobile SDK |
| URL | https://www.spritzreader.com/how-it-works |
| Maturity | MATURE (2014-era hype, still alive) |
| License | Proprietary |

**Strengths:**
- Defined the modern pattern: ORP (Optimal Recognition Point) pinned at fixed screen X, pivot
  letter highlighted red — eye never moves; claims up to 1,000 WPM
- ORP is length-dependent: slightly left of center; the longer the word, the further left

**Weaknesses:**
- Proprietary; no recovery-from-distraction story; no comprehension verification
- Academic evaluation found comprehension costs (see Research below)

**Relevance:** 90% (visual/timing pattern), 0% (code)

### rsvp-reader (chislerr) — closest desktop comparable
| Aspect | Assessment |
|--------|------------|
| Type | APPLICATION (desktop) |
| Platform | Desktop, open source |
| URL | https://github.com/chislerr/rsvp-reader |
| Maturity | GROWING |
| License | Open source |

**Strengths:** 100–1500+ WPM, ORP highlighting, phrase grouping, library management, bookmarks,
chapter navigation, **smart pausing** (punctuation-aware timing — validates our timing model)

**Weaknesses:** No comprehension loop; no attention-loss recovery beyond bookmarks; no AI cleanup

**Relevance:** 70%

### speeedy (sami-29) — local-first kin
| Aspect | Assessment |
|--------|------------|
| Type | APPLICATION |
| Platform | Desktop, PDFs & EPUBs |
| URL | https://github.com/sami-29/speeedy |
| Maturity | GROWING |
| License | Open source |

**Strengths:** Local-first, fully offline, no accounts/tracking (matches our philosophy);
fixed focal point; OpenDyslexic/Irlen support; **built-in stats and benchmark** (validates logging)

**Weaknesses:** Stats measure speed only — comprehension never verified; no recovery loop

**Relevance:** 65%

### Stutter (jamestomasino) — browser RSVP
| Aspect | Assessment |
|--------|------------|
| Type | BROWSER EXTENSION |
| Platform | Firefox/Chrome |
| URL | https://github.com/jamestomasino/stutter · https://addons.mozilla.org/en-US/firefox/addon/stutter/ |
| Maturity | MATURE |
| License | Open source |

**Strengths:** Select-anywhere intake; zero data collection
**Weaknesses:** Ephemeral sessions — no state, no history, no recovery
**Relevance:** 40%

### Others sighted
- Limitless-One/RSVP-Reader (https://github.com/Limitless-One/RSVP-Reader) — lightweight, local extension
- GitHub topic index: https://github.com/topics/speed-reading — the field is crowded with
  *stream-only* implementations; none found close the comprehension loop

## The Reading-Science Check (what the field ignores)

- **Schotter, Tran & Rayner 2014, "Don't Believe What You Read (Only Once)"**
  (https://journals.sagepub.com/doi/10.1177/0956797614531148, PDF:
  http://faculty.cas.usf.edu/eschotter/papers/Schotter_Tran_Rayner_2014_PsychSci.pdf) —
  masking words once the eye passes (functionally RSVP) **eliminates regressions and measurably
  harms comprehension**; most regressions repair comprehension failures, not eye error.
- **Rayner, Schotter, Masson, Potter & Treiman 2016, "So Much to Read, So Little Time"**
  (https://journals.sagepub.com/doi/full/10.1177/1529100615623267) — definitive review; skepticism
  of speed claims without comprehension cost.
- **Benedetto et al. 2015, "RSVP in reading: The case of Spritz"**
  (https://www.sciencedirect.com/science/article/abs/pii/S0747563214007663) — empirical Spritz evaluation.
- **SQ3R (Robinson 1941)** (https://en.wikipedia.org/wiki/SQ3R,
  https://www.adlit.org/in-the-classroom/strategies/sq3r-survey-question-read-recite-review) —
  Survey and **Question-before-Read** are established comprehension technique; Larry's
  "review the quiz beforehand, like reading a ToC first" is the S+Q steps operationalized.

**Design consequence:** the two documented weaknesses of RSVP — no regression, unverified
comprehension — are precisely the two features Larry specified (recovery loop, quiz loop).
This product is RSVP **with the science objections engineered out**.

## Eiffel Ecosystem Check

### simple_* Libraries (verified present in D:\prod, 2026-08-26)
- **simple_widgets** — drawn Win32 toolkit; verified: `SW_CANVAS` (agent-drawn, painter-monopoly),
  `SW_PAINTER.select_font` + cairo `text_extents.x_advance` (ORP alignment, user fonts),
  `SW_THEME.make_dark`, `SW_WINDOW.on_tick`, sliders/selects/text box/file dialog/sparkline
- **simple_shell** — `shell_window.e:79` `tick_ms` (GetTickCount) and `:94` app-settable fast tick
  ("event 25 every a_ms") — the cadence clock
- **simple_ai_client** — `OLLAMA_CLIENT` (`src/providers/ollama/ollama_client.e`,
  default `http://localhost:11434`, base URL settable — Larry's native GPU instance is 11435)
- **simple_sql** — SQLite persistence (reading log)
- **simple_config** — settings (fonts, speeds, Ollama URL)
- **simple_file / simple_encoding** — .txt/.md intake, UTF-8 → UTF-32

### ISE Libraries
- base only (allowed). No Vision2 — simple_widgets replaces it.

### Gobo
- Not relevant to this domain.

### Gap Analysis
No RSVP/speed-reading anything exists in Eiffel (checked 138 simple_* dirs + ecosystem knowledge).
Greenfield application over existing simple_* stack.

## Comparison Matrix

| Feature | Spritz | chislerr | speeedy | Stutter | Our Need |
|---------|--------|----------|---------|---------|----------|
| ORP fixed pivot | ✓ | ✓ | ✓ | ✓ | MUST |
| Ramping speed session | ✓ (drill demos) | ✗ | ✗ | ✗ | MUST |
| Punctuation-aware timing | ✓ | ✓ | ? | ✓ | SHOULD |
| Recovery to last-comprehended + re-ramp | ✗ | ✗ | ✗ | ✗ | **MUST (novel)** |
| Pre-generated comprehension quiz | ✗ | ✗ | ✗ | ✗ | **MUST (novel)** |
| Quiz reviewable BEFORE reading (SQ3R) | ✗ | ✗ | ✗ | ✗ | **MUST (novel)** |
| Speed + comprehension log | partial | ✗ | speed only | ✗ | MUST |
| AI text preprocessor (local) | ✗ | ✗ | ✗ | ✗ | **MUST (novel)** |
| Zero-chrome running state | ✓ (mostly) | ✗ | ✗ | ✓ | MUST |
| Fully offline/local | ✗ | ✓ | ✓ | ✓ | MUST |

## Patterns Identified

| Pattern | Seen In | Adopt? |
|---------|---------|--------|
| ORP pivot red + fixed X + tick marks | Spritz, video | YES |
| Length-dependent ORP index (~1/3, left of center) | Spritz literature | YES |
| Smart pausing (punctuation/word length) | chislerr, Spritz | YES |
| Local-first, no telemetry | speeedy, Stutter | YES |
| Library/bookmark management | chislerr | LATER (simple intake first) |
| Phrase grouping | chislerr | DEFER |

## Build vs Buy vs Adapt

| Option | Effort | Risk | Fit |
|--------|--------|------|-----|
| Build (Eiffel, simple_* stack) | MED | LOW | 100% |
| Adopt (existing OSS app) | LOW | HIGH | 25% — none close the comprehension loop; none Eiffel |
| Adapt (port an OSS reader) | HIGH | MED | 30% — engine is the easy part; the novel loop is the work anyway |

**Initial Recommendation:** **BUILD.** The RSVP engine itself is small (a timing loop + text layout);
every comparable lacks the features that define this product; the ecosystem already supplies the
window, canvas, AI, and persistence layers.
