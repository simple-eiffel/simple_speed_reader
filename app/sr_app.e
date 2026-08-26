note
	description: "[
		The application: one dark window, three postures. RUNNING is only
		the stream (flow map + stage + WPM); PAUSED is the context page
		with the flow map as scrubber; STOPPED is the cockpit. The shell
		fast tick (12 ms) drives the engine's deadline clock.
	]"
	author: "Larry Rix"

class
	SR_APP

create
	make

feature {NONE} -- Initialization

	make
		local
			l_row: SW_ROW
			l_col: SW_COLUMN
		do
				-- Phase 1: every attached attribute set - no agent may
				-- capture Current until this block is complete (VEVI).
			create logger.make_to_file ("speed_reader.log")
			create settings.make ("speed_reader.cfg")
			create ledger.make ("speed_reader.db")
			create reader.make
			reader := reader.with_speeds (settings.start_wpm, settings.recovery_wpm,
				settings.comfy_max_wpm).with_foreign_skip (settings.skip_foreign)
			create theme.make_dark
			create window.make ("Simple Speed Reader", 90, 50, 1180, 820, theme)
			create last_source.make_empty
			create last_title.make_empty
			create current_file_path.make_empty
			create stage.make (reader)
			stage.set_font_size (settings.font_size)
			create context_view.make (reader)
			create flow_map.make (reader)
			create ribbon.make (reader)
			create cockpit.make (settings.start_wpm, settings.comfy_max_wpm, settings.skip_foreign)
			create speed_drawer.make_titled ("Speed")
			create speed_label.make_mono ("")
			speed_drawer.put (speed_label)
			create hold_button.make ("Hold at current", Void)
			speed_drawer.put (hold_button)
			create backoff_100_button.make ("Back off 100  (1)", Void)
			speed_drawer.put (backoff_100_button)
			create backoff_50_button.make ("Back off 50  (2)", Void)
			speed_drawer.put (backoff_50_button)
			create backoff_25_button.make ("Back off 25  (3)", Void)
			speed_drawer.put (backoff_25_button)
			create nudge_up_button.make ("Target +25  (Up)", Void)
			speed_drawer.put (nudge_up_button)
			create nudge_down_button.make ("Target -25  (Down)", Void)
			speed_drawer.put (nudge_down_button)
			create speed_chip_button.make ("Speed >", Void)
			create l_row.make
			l_row.put (flow_map.surface)
			l_row.put (stage.surface)
			running_root := l_row
			create paused_resume_button.make_primary ("Resume at sentence head  (Space)", Void)
			create paused_here_button.make ("Resume exactly here  (Enter)", Void)
			create paused_stop_button.make ("Stop and log the run  (Esc)", Void)
			create l_col.make
			l_col.put (ribbon.surface)
			create l_row.make
			l_row.put (flow_map.surface)
			l_row.put (context_view.surface)
			l_row.set_grow (1.0)
			l_col.put (l_row)
			create l_row.make
			l_row := l_row.with_gap (10.0)
			l_row.put (paused_resume_button)
			l_row.put (paused_here_button)
			l_row.put (paused_stop_button)
			l_row.put (speed_chip_button)
			l_col.put (l_row)
			paused_root := l_col
			cockpit_root := cockpit.root
			posture := Posture_cockpit

				-- Phase 2: wiring - Current may now escape into agents.
			stage.surface.set_on_char (agent on_reading_char)
			stage.surface.set_on_vk (agent on_reading_vk)
			stage.surface.set_on_press (agent on_stage_press)
			context_view.surface.set_on_char (agent on_paused_char)
			context_view.set_on_word_click (agent on_word_marked)
			flow_map.set_on_seek (agent on_map_seek)
			cockpit.wire (
				agent on_load_file_asked, agent on_start_asked, agent on_continue_asked,
				agent on_start_wpm_changed, agent on_comfy_changed,
				agent on_skip_toggled)
			paused_resume_button.set_on_click (agent on_paused_resume_clicked)
			paused_here_button.set_on_click (agent on_paused_here_clicked)
			paused_stop_button.set_on_click (agent do_stop)
			ribbon.set_on_word_click (agent on_word_marked)
			speed_chip_button.set_on_click (agent open_speed_drawer)
			speed_drawer.set_on_close (agent close_speed_drawer)
			hold_button.set_on_click (agent on_hold_clicked)
			backoff_100_button.set_on_click (agent on_backoff_clicked (100))
			backoff_50_button.set_on_click (agent on_backoff_clicked (50))
			backoff_25_button.set_on_click (agent on_backoff_clicked (25))
			nudge_up_button.set_on_click (agent on_drawer_nudge (True))
			nudge_down_button.set_on_click (agent on_drawer_nudge (False))
			cockpit.show_history (ledger.recent_lines (6))

			window.set_root (cockpit_root)
			window.set_on_shell_event (agent on_shell_event)
			window.set_on_tick (agent on_heartbeat)
			logger.info ("app up - window created, cockpit posture")
			window.run
			logger.info ("app down - pump exited")
		end

feature {NONE} -- The clock

	Tick_ms: INTEGER = 12

	is_fast_timer_armed: BOOLEAN

	on_heartbeat
			-- The ambient heartbeat: arms the 12 ms fast tick once the
			-- native window exists (set_fast_timer needs hwnd up), then
			-- stays out of the way.
		do
			if not is_fast_timer_armed then
				is_fast_timer_armed := True
				window.set_fast_timer (Tick_ms)
			end
		end

	on_shell_event (a_type, a_a, a_b: INTEGER)
		local
			l_now, l_sig: INTEGER
		do
			if a_type = 25 then
				l_now := window.tick_ms
				reader.tick (l_now)
				if posture = Posture_running then
					if reader.is_sealed then
							-- The text finished under us.
						record_seal
						to_cockpit
					else
						stage.set_breather (reader.in_breather (l_now))
						l_sig := reader.position * 16
							+ reader.current_wpm
							+ (if stage.is_in_breather then 8 else 0 end)
						if l_sig /= last_render_sig then
							last_render_sig := l_sig
							window.request_render
						end
					end
				end
			end
		end

	last_render_sig: INTEGER

feature {NONE} -- Postures (D-012)

	Posture_cockpit: INTEGER = 1
	Posture_running: INTEGER = 2
	Posture_paused: INTEGER = 3

	posture: INTEGER

	running_root, paused_root, cockpit_root: SW_WIDGET

	to_running
		do
			posture := Posture_running
			window.set_root (running_root)
			window.give_focus (stage.surface)
			last_render_sig := -1
			window.request_render
		end

	to_paused
		do
			posture := Posture_paused
			window.set_root (paused_root)
			window.give_focus (context_view.surface)
			window.request_render
		end

	to_cockpit
		do
			posture := Posture_cockpit
			cockpit.refresh (reader)
			cockpit.show_history (ledger.recent_lines (6))
			window.set_root (cockpit_root)
			window.request_render
		end

feature {NONE} -- Transport (D-014)

	on_reading_char (a_code: INTEGER)
		do
			inspect a_code
			when 32, 107, 75 then -- Space, k, K
				do_pause
			when 27, 115, 83 then -- Esc, s, S
				do_stop
			when 104, 72 then -- h, H
				do_toggle_hold
			when 49 then -- 1
				if reader.has_text then
					reader.back_off (100)
				end
			when 50 then -- 2
				if reader.has_text then
					reader.back_off (50)
				end
			when 51 then -- 3
				if reader.has_text then
					reader.back_off (25)
				end
			when 46 then -- .
				do_nudge_up
			when 44 then -- ,
				do_nudge_down
			else
			end
			window.request_render
		end

	on_reading_vk (a_vk: INTEGER; a_shift: BOOLEAN)
		do
			inspect a_vk
			when 37 then -- Left: micro-rewind, speed untouched
				if reader.is_running then
					reader.replay_sentence (window.tick_ms)
				end
			when 39 then -- Right: skip a sentence (logged as skipped)
				if reader.is_running then
					reader.skip_sentence_forward (window.tick_ms)
					if reader.is_sealed then
						to_cockpit
					end
				end
			when 38 then -- Up
				do_nudge_up
			when 40 then -- Down
				do_nudge_down
			else
			end
			window.request_render
		end

	on_paused_char (a_code: INTEGER)
		do
			inspect a_code
			when 32, 107, 75 then -- Space: zero-click resume
				if reader.is_paused then
					reader.resume_at_sentence_start (window.tick_ms)
					to_running
				end
			when 13 then -- Enter: resume exactly here
				if reader.is_paused and then reader.position >= 1 then
					reader.resume_at (reader.position, window.tick_ms)
					to_running
				end
			when 27, 115, 83 then -- Esc
				do_stop
			else
			end
		end

	on_stage_press (a_px, a_py: REAL_64)
			-- The whole stage is a pause target (FR-034).
		do
			do_pause
		end

	open_speed_drawer
		do
			refresh_speed_labels
			window.show_drawer (speed_drawer, 320.0, True)
			window.request_render
		end

	close_speed_drawer
		do
			window.close_sheet
			window.request_render
		end

	on_hold_clicked
		do
			do_toggle_hold
			refresh_speed_labels
			window.request_render
		end

	on_backoff_clicked (a_amount: INTEGER)
		do
			if reader.has_text then
				reader.back_off (a_amount)
				refresh_speed_labels
				window.request_render
			end
		end

	on_drawer_nudge (a_up: BOOLEAN)
		do
			if a_up then
				do_nudge_up
			else
				do_nudge_down
			end
			refresh_speed_labels
			window.request_render
		end

	refresh_speed_labels
		local
			l_s: STRING_32
		do
			create l_s.make (48)
			l_s.append_string_general ("current ")
			l_s.append_string_general (reader.current_wpm.out)
			l_s.append_string_general (" -> target ")
			l_s.append_string_general (reader.target_wpm.out)
			l_s.append_string_general (" wpm")
			if reader.is_held then
				l_s.append_string_general ("  [HELD]")
				hold_button.set_label ("Release hold")
			else
				hold_button.set_label ("Hold at current")
			end
			speed_label.set_text (l_s)
		end

	on_paused_resume_clicked
		do
			if reader.is_paused then
				reader.resume_at_sentence_start (window.tick_ms)
				to_running
			end
		end

	on_paused_here_clicked
		do
			if reader.is_paused and then reader.position >= 1 then
				reader.resume_at (reader.position, window.tick_ms)
				to_running
			end
		end

	on_word_marked (a_index: INTEGER)
			-- Context-page click: the reader-marked comprehension point.
		do
			if reader.is_paused and then a_index >= 1 and then a_index <= reader.position then
				logger.info ("recovery - marked word " + a_index.out
					+ " (was at " + reader.position.out + ")")
				reader.resume_at (a_index, window.tick_ms)
				to_running
			end
		end

	on_map_seek (a_index: INTEGER)
			-- Flow-map click while paused: backward seeks only (DR-003).
		do
			if reader.is_paused and then a_index >= 1 and then a_index <= reader.position then
				reader.resume_at (a_index, window.tick_ms)
				to_running
			end
		end

	do_pause
		do
			if reader.is_running then
				reader.pause_reading
				logger.info ("paused at word " + reader.position.out
					+ " of " + reader.token_count.out + " (" + reader.current_wpm.out + " wpm)")
				settings.set_resume_point (current_file_path, reader.title, reader.position)
				to_paused
			end
		end

	do_stop
		do
			if reader.is_running or reader.is_paused then
				reader.stop_and_seal
				record_seal
			end
			to_cockpit
		end

	record_seal
			-- The ledger row and the crash-safe bookmark, at every seal.
		do
			if attached reader.last_record as al_rec then
				ledger.record_run (al_rec, -1)
				logger.info ({STRING_32} "sealed - " + al_rec.summary_line)
			end
			settings.set_resume_point (current_file_path, reader.title, reader.position)
		end

	do_toggle_hold
		do
			if reader.is_running then
				if reader.is_held then
					reader.release_hold
				else
					reader.hold
				end
			end
		end

	do_nudge_up
		do
			if reader.has_text and then not reader.is_held then
				reader.nudge_up
			end
		end

	do_nudge_down
		do
			if reader.has_text then
				reader.nudge_down
			end
		end

feature {NONE} -- Cockpit actions

	on_start_asked
		local
			l_pasted: STRING_32
		do
			apply_speed_prefs
			l_pasted := cockpit.pasted_text
			if not l_pasted.is_empty and then not l_pasted.same_string (last_source) then
				last_source := l_pasted.twin
				last_title := {STRING_32} "pasted text"
				current_file_path := {STRING_32} "" -- pasted: no file to continue from
				reader.load_text (last_title, last_source)
			elseif not reader.can_start and then not last_source.is_empty then
					-- Sealed sitting: a fresh session on the same text.
				reader.load_text (last_title, last_source)
			end
			if reader.can_start then
				reader.start_reading (window.tick_ms)
				logger.info ({STRING_32} "reading started - " + reader.title
					+ {STRING_32} " (" + reader.token_count.out + {STRING_32} " words, target "
					+ reader.target_wpm.out + {STRING_32} " wpm)")
				to_running
			else
				logger.warn ({STRING_32} "start refused - " +
					(if reader.last_intake_ok then {STRING_32} "no startable session"
					 else reader.last_intake_error end))
				cockpit.refresh (reader)
				window.request_render
			end
		end

	on_load_file_asked
		local
			fd: SW_FILE_DIALOG
		do
			logger.info ("open-file dialog requested")
			create fd.make_open ({STRING_32} "D:\")
			fd.set_on_accept (agent on_file_picked)
			window.show_sheet (fd, 680.0)
			logger.info ("open-file dialog shown - " + fd.available_drives.count.out + " drives")
		end

	on_file_picked (a_path: STRING_32)
		do
			window.close_sheet
			apply_speed_prefs
			reader.load_file (a_path)
			if reader.last_intake_ok then
				last_source := reader.loaded_source.twin -- already UTF-8-decoded
				last_title := reader.title.twin
				current_file_path := a_path.twin
				logger.info ({STRING_32} "loaded file " + a_path
					+ {STRING_32} " - " + reader.token_count.out + {STRING_32} " words")
			else
				logger.error ({STRING_32} "file intake failed: " + reader.last_intake_error)
			end
			cockpit.refresh (reader)
			window.request_render
		end

	on_continue_asked
			-- FR-032: back into the last text at the saved word.
		local
			l_at: INTEGER
		do
			apply_speed_prefs
			if not settings.last_file_path.is_empty and then settings.last_position > 0 then
				reader.load_file (settings.last_file_path)
				if reader.last_intake_ok and then reader.can_start then
					current_file_path := settings.last_file_path.twin
					last_source := reader.loaded_source.twin
					last_title := reader.title.twin
					l_at := settings.last_position.min (reader.token_count).max (1)
					reader.preset_position (l_at)
					reader.start_reading (window.tick_ms)
					logger.info ({STRING_32} "continued " + reader.title
						+ {STRING_32} " at word " + l_at.out)
					to_running
				else
					logger.warn ({STRING_32} "continue failed: " + reader.last_intake_error)
					cockpit.refresh (reader)
					window.request_render
				end
			else
				logger.info ("continue asked - no saved position")
				window.request_render
			end
		end

	on_start_wpm_changed (a_wpm: INTEGER)
		do
			apply_speed_prefs
		end

	on_comfy_changed (a_wpm: INTEGER)
		do
			apply_speed_prefs
		end

	on_skip_toggled
		do
			reader := reader.with_foreign_skip (cockpit.skip_on)
			settings.set_skip_foreign (cockpit.skip_on)
		end

	apply_speed_prefs
		local
			l_start, l_comfy: INTEGER
		do
			l_start := cockpit.start_box.value
			l_comfy := cockpit.comfy_box.value.max (l_start)
			reader := reader.with_speeds (l_start, l_start.min (300), l_comfy)
			settings.set_speeds (l_start, l_start.min (300), l_comfy)
		end

feature {NONE} -- Implementation

	reader: SIMPLE_SPEED_READER

	window: SW_WINDOW

	theme: SW_THEME

	stage: SR_STAGE_VIEW

	context_view: SR_CONTEXT_VIEW

	flow_map: SR_FLOW_MAP_VIEW

	cockpit: SR_COCKPIT

	ribbon: SR_RIBBON_VIEW

	speed_drawer: SW_DRAWER

	speed_label: SW_LABEL

	paused_resume_button, paused_here_button, paused_stop_button,
	speed_chip_button, hold_button, backoff_100_button, backoff_50_button,
	backoff_25_button, nudge_up_button, nudge_down_button: SW_BUTTON

	logger: SIMPLE_LOGGER

	settings: SR_SETTINGS

	ledger: SR_LOG

	last_source, last_title, current_file_path: STRING_32

end
