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

	make
			-- Build the surface; `wire' hooks the host's agents after.
		local
			l_row: SW_ROW
			l_speeds: SW_ROW
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
			create load_button.make ("Load .txt / .md file", Void)
			l_row.put (load_button)
			create start_button.make_primary ("Start reading  (Space pauses - Esc stops)", Void)
			l_row.put (start_button)
			root.put (l_row)

			create l_speeds.make
			l_speeds := l_speeds.with_gap (10.0)
			l_speeds.put (create {SW_LABEL}.make_mono ("start WPM"))
			create start_box.make (250, {SR_GOVERNOR}.Min_wpm, 600, Void)
			l_speeds.put (start_box)
			l_speeds.put (create {SW_LABEL}.make_mono ("comfy max WPM"))
			create comfy_box.make (900, 200, {SR_GOVERNOR}.Max_wpm, Void)
			l_speeds.put (comfy_box)
			create skip_check.make ("Skip Hebrew/Greek script words (transliterations stay)", False, Void)
			l_speeds.put (skip_check)
			root.put (l_speeds)

			create summary_label.make_mono ("")
			root.put (summary_label)
		end

feature -- Wiring

	wire (a_on_load_file, a_on_start: PROCEDURE;
			a_on_start_wpm, a_on_comfy_wpm: PROCEDURE [INTEGER];
			a_on_skip: PROCEDURE)
			-- Hook the host's actions (two-phase: after the host's own
			-- attributes are all set, so its agents may capture it).
		do
			load_button.set_on_click (a_on_load_file)
			start_button.set_on_click (a_on_start)
			start_box.set_on_change (a_on_start_wpm)
			comfy_box.set_on_change (a_on_comfy_wpm)
			skip_check.set_on_change (a_on_skip)
		end

feature -- Access

	root: SW_COLUMN

	text_box: SW_TEXT_BOX

	start_box, comfy_box: SW_NUMBER_BOX

	pasted_text: STRING_32
		do
			Result := text_box.text
		end

	skip_on: BOOLEAN
		do
			Result := skip_check.is_checked
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

	load_button, start_button: SW_BUTTON

	skip_check: SW_CHECK_BOX

end
