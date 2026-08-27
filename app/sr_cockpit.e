note
	description: "[
		The STOPPED posture: intake (paste or file), speed anchors, the
		foreign-skip switch, status and the last run's honest summary.
	]"
	author: "Larry Rix"

class
	SR_COCKPIT

create
	make

feature {NONE} -- Initialization

	make (a_start_wpm, a_comfy_wpm: INTEGER; a_skip, a_quiz_opt, a_fade: BOOLEAN)
			-- Build the surface seeded from the profile; `wire' hooks
			-- the host's agents after.
		require
			lawful: a_start_wpm >= {SR_GOVERNOR}.Min_wpm and a_comfy_wpm <= {SR_GOVERNOR}.Max_wpm
		local
			l_row: SW_ROW
			l_speeds: SW_ROW
			i: INTEGER
		do
			create root.make
			root := root.with_padding (20.0).with_gap (12.0)

			create title_label.make_body ("simple_speed_reader - paste a text (or load a file), set your speeds, Start.")
			root.put (title_label)

			create status_label.make_mono ("No text loaded.")
			root.put (status_label)

			create text_box.make ("")
				-- Book-sized pastes land here: spell-checking them
				-- would grind the pump for minutes. Off, like every
				-- non-prose box in the ecosystem.
			text_box.set_spellcheck (False)
			text_box.set_grow (1.0)
			root.put (text_box)

			create l_row.make
			l_row := l_row.with_gap (10.0)
			create load_button.make ("Load .txt / .md / .pdf", Void)
			l_row.put (load_button)
			create start_button.make_primary ("Start reading  (Space pauses - Esc stops)", Void)
			l_row.put (start_button)
			create continue_button.make ("Continue where I left off", Void)
			l_row.put (continue_button)
			root.put (l_row)

			create drop_zone.make ("Drop a .txt, .md or .pdf here from Explorer")
			root.put (drop_zone)

			create l_speeds.make
			l_speeds := l_speeds.with_gap (10.0)
			l_speeds.put (create {SW_LABEL}.make_mono ("start WPM"))
			create start_box.make (a_start_wpm, {SR_GOVERNOR}.Min_wpm, 600, Void)
			l_speeds.put (start_box)
			l_speeds.put (create {SW_LABEL}.make_mono ("comfy max WPM"))
			create comfy_box.make (a_comfy_wpm, 200, {SR_GOVERNOR}.Max_wpm, Void)
			l_speeds.put (comfy_box)
			create skip_check.make ("Skip Hebrew/Greek script words (transliterations stay)", a_skip, Void)
			l_speeds.put (skip_check)
			root.put (l_speeds)

			create l_row.make
			l_row := l_row.with_gap (10.0)
			create quiz_check.make ("Comprehension quiz (local AI, before reading - SQ3R)", a_quiz_opt, Void)
			l_row.put (quiz_check)
			create fade_check.make ("Fade words", a_fade, Void)
			l_row.put (fade_check)
			create preview_button.make ("Preview questions", Void)
			l_row.put (preview_button)
			create quiz_status_label.make_mono ("")
			l_row.put (quiz_status_label)
			root.put (l_row)

			create question_label.make_body ("")
			root.put (question_label)
			create answer_label.make_mono ("")
			root.put (answer_label)
			create l_row.make
			l_row := l_row.with_gap (10.0)
			create reveal_button.make ("Show the answer", Void)
			l_row.put (reveal_button)
			create got_button.make_primary ("I got it", Void)
			l_row.put (got_button)
			create missed_button.make ("I missed it", Void)
			l_row.put (missed_button)
			root.put (l_row)

			create summary_label.make_mono ("")
			root.put (summary_label)

				-- Key-combo discovery: every control tells its shortcut.
			text_box.set_tooltip ("Paste any text - Start streams it")
			load_button.set_tooltip ("Open a .txt, .md or .pdf - drive chips and typed paths both work")
			start_button.set_tooltip ("While reading: Space pauses - Esc stops - B brakes - +/- speed - Alt +/- font")
			continue_button.set_tooltip ("Reload the last file at your bookmarked word")
			start_box.set_tooltip ("Where the ramp starts each run")
			comfy_box.set_tooltip ("The ceiling the ramp climbs toward")
			skip_check.set_tooltip ("Stream past Hebrew/Greek glyphs - transliterations stay - text views show everything")
			quiz_check.set_tooltip ("A local model writes questions from your text BEFORE you read (SQ3R)")
			preview_button.set_tooltip ("Read the questions first - it primes comprehension")
			reveal_button.set_tooltip ("See the expected answer and its verbatim proof quote")
			got_button.set_tooltip ("Honest self-scoring - the score joins this run's ledger row")
			missed_button.set_tooltip ("No shame - the gap is information")
			drop_zone.set_tooltip ("Drag from Explorer - works on any part of the reader, any time")
			fade_check.set_tooltip ("Words fade in, and melt into sentence pauses - scales with your WPM, vanishing at speed")

			create history_labels.make (History_rows)
			from
				i := 1
			until
				i > History_rows
			loop
				history_labels.extend (create {SW_LABEL}.make_mono (""))
				root.put (history_labels.last)
				i := i + 1
			end
		end

feature -- Wiring

	wire (a_on_load_file, a_on_start, a_on_continue: PROCEDURE;
			a_on_start_wpm, a_on_comfy_wpm: PROCEDURE [INTEGER];
			a_on_skip, a_on_quiz_toggle, a_on_preview,
			a_on_reveal, a_on_got, a_on_missed, a_on_fade: PROCEDURE)
			-- Hook the host's actions (two-phase: after the host's own
			-- attributes are all set, so its agents may capture it).
		do
			load_button.set_on_click (a_on_load_file)
			start_button.set_on_click (a_on_start)
			continue_button.set_on_click (a_on_continue)
			start_box.set_on_change (a_on_start_wpm)
			comfy_box.set_on_change (a_on_comfy_wpm)
			skip_check.set_on_change (a_on_skip)
			quiz_check.set_on_change (a_on_quiz_toggle)
			preview_button.set_on_click (a_on_preview)
			reveal_button.set_on_click (a_on_reveal)
			got_button.set_on_click (a_on_got)
			missed_button.set_on_click (a_on_missed)
			fade_check.set_on_change (a_on_fade)
		end

	set_quiz_status (a_text: READABLE_STRING_GENERAL)
		do
			quiz_status_label.set_text (a_text)
		end

	set_admin_texts (a_question, a_answer: READABLE_STRING_GENERAL)
			-- The administration surface; both empty = quiz area idle.
		do
			question_label.set_text (a_question)
			answer_label.set_text (a_answer)
		end

	show_history (a_lines: LIST [STRING_32])
			-- The newest sealed runs, newest first.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > history_labels.count
			loop
				if i <= a_lines.count then
					history_labels.i_th (i).set_text (a_lines.i_th (i))
				else
					history_labels.i_th (i).set_text ("")
				end
				i := i + 1
			end
		end

feature -- Access

	root: SW_COLUMN

	text_box: SW_TEXT_BOX

	start_box, comfy_box: SW_NUMBER_BOX

	drop_zone: SW_DROPZONE
			-- Public: the host wires its on_drop.

	pasted_text: STRING_32
		do
			Result := text_box.text
		end

	skip_on: BOOLEAN
		do
			Result := skip_check.is_checked
		end

	quiz_on: BOOLEAN
		do
			Result := quiz_check.is_checked
		end

	fade_on: BOOLEAN
		do
			Result := fade_check.is_checked
		end

feature -- Operations

	refresh (a_reader: SIMPLE_SPEED_READER)
			-- Reflect the engine's state.
		local
			l_s: STRING_32
		do
			if a_reader.has_text then
				create l_s.make (96)
				l_s.append_string_general ("Loaded: ")
				l_s.append (a_reader.title)
				l_s.append_string_general (" - ")
				l_s.append_string_general (a_reader.token_count.out)
				l_s.append_string_general (" words")
				if a_reader.position > 0 then
					l_s.append_string_general (" - position ")
					l_s.append_string_general (a_reader.position.out)
				end
				if not a_reader.last_intake_ok then
					l_s.append_string_general ("  [")
					l_s.append (a_reader.last_intake_error)
					l_s.append_string_general ("]")
				end
				status_label.set_text (l_s)
			elseif not a_reader.last_intake_ok and then not a_reader.last_intake_error.is_empty then
				status_label.set_text ({STRING_32} "Intake refused: " + a_reader.last_intake_error)
			else
				status_label.set_text ("No text loaded.")
			end
			if attached a_reader.last_record as al_rec then
				summary_label.set_text ({STRING_32} "Last run - " + al_rec.summary_line)
			end
		end

feature {NONE} -- Implementation

	title_label, status_label, summary_label: SW_LABEL

	history_labels: ARRAYED_LIST [SW_LABEL]

	History_rows: INTEGER = 6

	load_button, start_button, continue_button,
	preview_button, reveal_button, got_button, missed_button: SW_BUTTON

	quiz_status_label: SW_LABEL

	question_label, answer_label: SW_LABEL

	skip_check, quiz_check, fade_check: SW_CHECK_BOX

end
