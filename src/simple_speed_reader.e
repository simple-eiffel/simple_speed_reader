note
	description: "[
		The engine facade: intake, pacing, recovery, governance, records.
		Headless - a GUI (or a test with a scripted clock) drives tick,
		keys and clicks; every reading behavior lives behind this door.
	]"
	author: "Larry Rix"

class
	SIMPLE_SPEED_READER

create
	make

feature {NONE} -- Initialization

	make
		do
			create tokenizer
			create timing
			pref_start_wpm := 250
			pref_recovery_wpm := 250
			pref_comfy_max_wpm := 900
			create last_intake_error.make_empty
		ensure
			no_text: not has_text
		end

feature -- Configuration (persisted prefs applied at next load)

	with_speeds (a_start, a_recovery, a_comfy_max: INTEGER): like Current
		require
			floor_start: a_start >= {SR_GOVERNOR}.Min_wpm
			floor_recovery: a_recovery >= {SR_GOVERNOR}.Min_wpm
			order: a_start <= a_comfy_max and a_recovery <= a_comfy_max
			ceiling: a_comfy_max <= {SR_GOVERNOR}.Max_wpm
		do
			pref_start_wpm := a_start
			pref_recovery_wpm := a_recovery
			pref_comfy_max_wpm := a_comfy_max
			Result := Current
		ensure
			chained: Result = Current
			kept: pref_start_wpm = a_start and pref_recovery_wpm = a_recovery
				and pref_comfy_max_wpm = a_comfy_max
		end

	with_foreign_skip (a_on: BOOLEAN): like Current
		do
			pref_skip_foreign := a_on
			if attached session as al_s then
				al_s.set_skip_foreign (a_on)
			end
			Result := Current
		ensure
			chained: Result = Current
		end

feature -- Intake

	load_text (a_title: READABLE_STRING_GENERAL; a_source: READABLE_STRING_GENERAL)
			-- Tokenize `a_source' and stand up a fresh session on it.
		require
			title_present: not a_title.is_empty
		local
			l_gov: SR_GOVERNOR
			al_s: SR_SESSION
		do
			if tokenizer.is_blank (a_source) then
				last_intake_ok := False
				last_intake_error := {STRING_32} "The text is empty."
			else
				create source_text.make_from_string_general (a_source)
				quiz := Void
				create text.make (a_title, tokenizer.tokenize (a_source))
				create l_gov.make (pref_start_wpm, pref_recovery_wpm, pref_comfy_max_wpm)
				check attached text as al_t then
					create al_s.make_with_text (al_t, l_gov, timing)
				end
				al_s.set_skip_foreign (pref_skip_foreign)
				session := al_s
				last_intake_ok := True
				last_intake_error := {STRING_32} ""
			end
		ensure
			loaded_iff_substance: last_intake_ok = not tokenizer.is_blank (a_source)
			has_text_when_ok: last_intake_ok implies has_text
		end

	load_file (a_path: READABLE_STRING_GENERAL)
			-- Read a .txt/.md file as UTF-8 and load it, titled by its
			-- file name. Bytes are decoded here with SIMPLE_ENCODING
			-- (SIMPLE_FILE.content mojibakes UTF-8 - raw bytes widened
			-- char-per-byte; verified on-screen 2026-08-26).
		require
			path_present: not a_path.is_empty
		local
			l_f: SIMPLE_FILE
			l_title, l_decoded: STRING_32
			l_bytes: ARRAY [NATURAL_8]
			l_raw: STRING_8
			l_enc: SIMPLE_ENCODING
			i: INTEGER
		do
			create l_f.make (a_path)
			if l_f.exists and then l_f.is_readable then
				create l_title.make_from_string_general (a_path)
				i := l_title.last_index_of ({CHARACTER_32} '\', l_title.count).max (
					l_title.last_index_of ({CHARACTER_32} '/', l_title.count))
				if i > 0 then
					l_title.remove_head (i)
				end
				if l_title.is_empty then
					l_title := {STRING_32} "untitled"
				end
				l_bytes := l_f.binary_content
				create l_raw.make (l_bytes.count)
				from
					i := l_bytes.lower
				until
					i > l_bytes.upper
				loop
					l_raw.append_character (l_bytes.item (i).to_character_8)
					i := i + 1
				end
				create l_enc.make
				l_decoded := l_enc.utf_8_to_utf_32 (l_raw)
				if not l_decoded.is_empty and then l_decoded.item (1).natural_32_code = 0xFEFF then
					l_decoded.remove_head (1) -- byte-order mark
				end
				loaded_source := l_decoded
				load_text (l_title, l_decoded)
			else
				last_intake_ok := False
				last_intake_error := {STRING_32} "Cannot read file: " + a_path.to_string_32
			end
		end

	loaded_source: STRING_32
			-- The decoded text of the last successful file load
			-- (for hosts that restart a sealed sitting).
		attribute
			create Result.make_empty
		end

	last_intake_ok: BOOLEAN

	last_intake_error: STRING_32

feature -- Status

	has_text: BOOLEAN
		do
			Result := session /= Void
		end

	is_running: BOOLEAN
		do
			Result := attached session as al_s and then al_s.is_running
		end

	is_paused: BOOLEAN
		do
			Result := attached session as al_s and then al_s.is_paused
		end

	is_sealed: BOOLEAN
		do
			Result := attached session as al_s and then al_s.is_sealed
		end

	position: INTEGER
		do
			if attached session as al_s then
				Result := al_s.position
			end
		end

	token_count: INTEGER
		do
			if attached text as al_t then
				Result := al_t.token_count
			end
		end

	token (a_index: INTEGER): SR_TOKEN
		require
			has_text: has_text
			in_text: a_index >= 1 and a_index <= token_count
		do
			check attached text as al_t then
				Result := al_t.token (a_index)
			end
		end

	current_token: SR_TOKEN
		require
			placed: has_text and position >= 1
		do
			Result := token (position)
		end

	title: STRING_32
		do
			if attached text as al_t then
				Result := al_t.title
			else
				create Result.make_empty
			end
		end

	current_wpm: INTEGER
		do
			if attached session as al_s then
				Result := al_s.governor.current_wpm
			end
		end

	target_wpm: INTEGER
		do
			if attached session as al_s then
				Result := al_s.governor.target_wpm
			end
		end

	is_held: BOOLEAN
		do
			Result := attached session as al_s and then al_s.governor.is_held
		end

	effective_wpm: INTEGER
		do
			if attached session as al_s then
				Result := al_s.effective_wpm
			end
		end

	in_breather (a_now_ms: INTEGER): BOOLEAN
		do
			Result := attached session as al_s and then al_s.in_breather (a_now_ms)
		end

	skipped_count: INTEGER
		do
			if attached session as al_s then
				Result := al_s.skipped_count
			end
		end

	streamed_count: INTEGER
		do
			if attached session as al_s then
				Result := al_s.streamed_count
			end
		end

	last_record: detachable SR_RUN_RECORD
		do
			if attached session as al_s then
				Result := al_s.last_record
			end
		end

	sentence_start_of_position: INTEGER
		require
			placed: has_text and position >= 1
		do
			check attached session as al_s then
				Result := al_s.sentence_start (al_s.position)
			end
		end

	can_start: BOOLEAN
		do
			Result := attached session as al_s and then
				(al_s.is_stopped and not al_s.is_sealed and al_s.has_streamable)
		end

feature -- The reading loop

	preset_position (a_index: INTEGER)
			-- Continue-at-word-N: place a fresh session before starting.
		require
			startable: can_start
			in_text: a_index >= 1 and a_index <= token_count
		do
			check attached session as al_s then
				al_s.preset_position (a_index)
			end
		ensure
			placed: position = a_index
		end

	tick (a_now_ms: INTEGER)
		do
			if attached session as al_s then
				al_s.tick (a_now_ms)
			end
		end

	start_reading (a_now_ms: INTEGER)
		require
			startable: can_start
		do
			check attached session as al_s then
				al_s.start_reading (a_now_ms)
			end
		ensure
			running: is_running
		end

	pause_reading
		require
			running: is_running
		do
			check attached session as al_s then
				al_s.pause_reading
			end
		ensure
			paused: is_paused
		end

	resume_at (a_index, a_now_ms: INTEGER)
		require
			paused: is_paused
			in_text: a_index >= 1 and a_index <= token_count
			never_forward: a_index <= position
		do
			check attached session as al_s then
				al_s.resume_at (a_index, a_now_ms)
			end
		ensure
			running: is_running
		end

	resume_at_sentence_start (a_now_ms: INTEGER)
		require
			paused: is_paused
		do
			check attached session as al_s then
				al_s.resume_at_sentence_start (a_now_ms)
			end
		ensure
			running: is_running
		end

	replay_sentence (a_now_ms: INTEGER)
		require
			running: is_running
		do
			check attached session as al_s then
				al_s.replay_sentence (a_now_ms)
			end
		end

	skip_sentence_forward (a_now_ms: INTEGER)
		require
			running: is_running
		do
			check attached session as al_s then
				al_s.skip_sentence_forward (a_now_ms)
			end
		end

	stop_and_seal
		require
			live: is_running or is_paused
		do
			check attached session as al_s then
				al_s.stop_and_seal
			end
		ensure
			sealed: is_sealed
		end

feature -- Quiz (D-007)

	quiz: detachable SR_QUIZ

	quiz_ready: BOOLEAN
		do
			Result := attached quiz as al_q and then al_q.is_usable
		end

	source_text: STRING_32
			-- The loaded text itself - what quiz quotes verify against.
		attribute
			create Result.make_empty
		end

	attach_quiz_json (a_json: READABLE_STRING_32)
			-- The worker's payload: parse, quote-verify, arm the quiz.
		require
			has_text: has_text
			json_present: not a_json.is_empty
			source_known: not source_text.is_empty
		do
			create quiz.make_from_json (a_json.to_string_32, source_text)
		ensure
			attached_quiz: quiz /= Void
		end

feature -- Braking (D-016)

	is_braking: BOOLEAN
		do
			Result := attached session as al_s and then al_s.governor.is_braking
		end

	is_brake_active: BOOLEAN
		do
			Result := attached session as al_s and then al_s.governor.is_brake_active
		end

	apply_brake
		require
			running: is_running
			idle: not is_brake_active
		do
			check attached session as al_s then
				al_s.governor.apply_brake
			end
		ensure
			braking: is_braking
		end

	release_brake
		require
			braking: is_braking
		do
			check attached session as al_s then
				al_s.governor.release_brake
			end
		ensure
			released: not is_braking
		end

	brake_tick
			-- One clock tick of glide; call every tick while brake-active.
		do
			if attached session as al_s then
				al_s.governor.brake_glide_tick
			end
		end

	scrub_back_word (a_now_ms: INTEGER)
		require
			running: is_running
		do
			check attached session as al_s then
				al_s.scrub_back_word (a_now_ms)
			end
		end

feature -- Governance

	hold
		require
			running: is_running
			not_held: not is_held
		do
			check attached session as al_s then
				al_s.governor.hold
			end
		ensure
			held: is_held
		end

	release_hold
		require
			held: is_held
		do
			check attached session as al_s then
				al_s.governor.release_hold
			end
		ensure
			released: not is_held
		end

	back_off (a_amount: INTEGER)
		require
			has_text: has_text
			sanctioned: a_amount = 25 or a_amount = 50 or a_amount = 100
		do
			check attached session as al_s then
				al_s.governor.back_off (a_amount)
			end
		end

	nudge_up
		require
			has_text: has_text
			not_held: not is_held
		do
			check attached session as al_s then
				al_s.governor.nudge_up
			end
		end

	nudge_down
		require
			has_text: has_text
		do
			check attached session as al_s then
				al_s.governor.nudge_down
			end
		end

feature {NONE} -- Implementation

	tokenizer: SR_TOKENIZER

	timing: SR_TIMING_MODEL

	text: detachable SR_TEXT

	session: detachable SR_SESSION

	pref_start_wpm, pref_recovery_wpm, pref_comfy_max_wpm: INTEGER

	pref_skip_foreign: BOOLEAN

invariant
	session_has_text: session /= Void implies text /= Void
	prefs_lawful: pref_start_wpm >= {SR_GOVERNOR}.Min_wpm
		and pref_comfy_max_wpm <= {SR_GOVERNOR}.Max_wpm

end
