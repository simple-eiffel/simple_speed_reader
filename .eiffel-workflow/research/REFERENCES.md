# REFERENCES: simple_speed_reader

**Date:** 2026-08-26 — URLs from live WebSearch this date.

## Reading Science (Articles/Papers)
- https://journals.sagepub.com/doi/10.1177/0956797614531148 — Schotter, Tran & Rayner (2014),
  "Don't Believe What You Read (Only Once)": masking read words (functionally RSVP) removes
  regressions and harms comprehension; most regressions repair comprehension failures.
  PDF: http://faculty.cas.usf.edu/eschotter/papers/Schotter_Tran_Rayner_2014_PsychSci.pdf
- https://journals.sagepub.com/doi/full/10.1177/1529100615623267 — Rayner, Schotter, Masson,
  Potter & Treiman (2016), "So Much to Read, So Little Time": definitive review of speed reading;
  speed-comprehension trade-off is real.
- https://www.sciencedirect.com/science/article/abs/pii/S0747563214007663 — Benedetto et al.
  (2015), "Rapid serial visual presentation in reading: The case of Spritz" (empirical evaluation).
- https://dl.acm.org/doi/fullHtml/10.1145/3313831.3376766 — CHI 2020, EEG-based selection of RSVP
  speed parameters (mental-workload-aware pacing; future-work relevance for adaptive ramp).

## Technique / Method
- https://www.spritzreader.com/how-it-works — ORP mechanics: fixed pivot, red highlight,
  length-dependent position slightly left of word center.
- https://en.wikipedia.org/wiki/SQ3R — Robinson (1941) Survey-Question-Read-Recite-Review;
  question-before-read is the validated ancestor of the quiz-preview feature.
- https://www.adlit.org/in-the-classroom/strategies/sq3r-survey-question-read-recite-review —
  SQ3R classroom practice.
- https://theconversation.com/spritz-and-other-speed-reading-apps-prose-and-cons-24467 —
  accessible summary of the pros/cons debate.

## Repositories Examined (comparables)
- https://github.com/chislerr/rsvp-reader — desktop OSS reader: ORP, smart pausing, bookmarks,
  phrase grouping (closest feature comparable).
- https://github.com/sami-29/speeedy — local-first, offline, stats/benchmark (philosophy comparable).
- https://github.com/jamestomasino/stutter — browser RSVP, zero-tracking.
- https://github.com/Limitless-One/RSVP-Reader — lightweight local extension.
- https://github.com/topics/speed-reading — field survey: crowded with stream-only readers;
  none close the comprehension loop.

## Ecosystem Evidence (local, verified by Read/grep 2026-08-26)
- D:\prod\simple_widgets\src\sw_canvas.e — agent-drawn surface (on_paint receives SW_PAINTER)
- D:\prod\simple_widgets\src\sw_painter.e:63-80 — select_font (family/slant/weight),
  text_extents.x_advance (ORP alignment)
- D:\prod\simple_shell\src\shell_window.e:79,94 — tick_ms (GetTickCount); app-settable fast tick
  ("event 25 every a_ms")
- D:\prod\simple_ai_client\src\providers\ollama\ollama_client.e:263 — Default_base_url
  http://localhost:11434 (Larry's native GPU instance: 11435 — must stay configurable)
- Source video: C:\Users\user\Videos\read-speed-drill.mp4 (55 s, 1048×1312, 30 fps; frames
  sampled at 4 s intervals; observed WPM 300/442/456/595/697/717/803; blank sentence breathers)
