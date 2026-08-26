# Changelog

All notable changes to simple_speed_reader are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added
- 2026-08-26 — Pre-phase research complete (7/7): landscape (Spritz, chislerr/rsvp-reader,
  speeedy, Stutter), reading-science grounding (Schotter et al. 2014, Rayner et al. 2016, SQ3R),
  recommendation BUILD/HIGH. `.eiffel-workflow/research/`
- 2026-08-26 — Specification complete (8/8, verdict READY): 26 classes, 42 functional
  requirements traced, contracts drafted, SCOOP AI-gateway architecture. `.eiffel-workflow/spec/`
- 2026-08-26 — Design decisions D-011–D-014: adaptive word timing (length bands, Hebrew/Greek
  script linger + WPM floor, transliteration/numeric/acronym classes), three GUI postures
  (running / paused-drawered / stopped-cockpit), foreign-script skip filter, media-transport
  keymap with in-flow micro-rewind.
- 2026-08-26 — Repo scaffolded: README, docs/, USER_GUIDE, timeline tracking.
- 2026-08-26 — D-015 fisheye ribbon (paused focus+context strip, clickable resume points);
  D-016 analog BRAKING (hold: glide to 300 with live ribbon; drag left stop+scrub / right
  re-engage; release: ease back to cruise) completing the intervention ladder.
- 2026-08-26 — Program icon generated (scripts/make_icon.py): "r·e·ad"+ticks mark, 7-size
  speed_reader.ico + docs logo.svg + icon-256.png.
- 2026-08-26 — DESIGN_STORY.md: rolling interaction narrative beside the specifications.

No code yet — implementation begins after /eiffel.intent.
