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
			create reader.make
			create theme.make_dark
			create window.make ("Simple Speed Reader", 90, 50, 1180, 820, theme)
			create last_source.make_empty
			create last_title.make_empty
			create stage.make (reader)
			create context_view.make (reader)
			create flow_map.make (reader)
			create cockpit.make
			create l_row.make
			l_row.put (flow_map.surface)
			l_row.put (stage.surface)
			running_root := l_row
			create l_col.make
			create l_row.make
			l_row.put (flow_map.surface)
			l_row.put (context_view.surface)
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
				agent on_load_file_asked, agent on_start_asked,
				agent on_start_wpm_changed, agent on_comfy_changed,
				agent on_skip_toggled)

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
				to_paused
			end
		end

	do_stop
		do
			if reader.is_running or reader.is_paused then
				reader.stop_and_seal
				if attached reader.last_record as al_rec then
					logger.info ({STRING_32} "sealed - " + al_rec.summary_line)
				end
			end
			to_cockpit
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
			create fd.make_open ({STRING_32} "D:\")
			fd.set_on_accept (agent on_file_picked)
			window.show_sheet (fd, 680.0)
		end

	on_file_picked (a_path: STRING_32)
		local
			l_f: SIMPLE_FILE
		do
			window.close_sheet
			apply_speed_prefs
			reader.load_file (a_path)
			if reader.last_intake_ok then
				create l_f.make (a_path)
				last_source := l_f.content
				last_title := reader.title.twin
				logger.info ({STRING_32} "loaded file " + a_path
					+ {STRING_32} " - " + reader.token_count.out + {STRING_32} " words")
			else
				logger.error ({STRING_32} "file intake failed: " + reader.last_intake_error)
			end
			cockpit.refresh (reader)
			window.request_render
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
		end

	apply_speed_prefs
		local
			l_start, l_comfy: INTEGER
		do
			l_start := cockpit.start_box.value
			l_comfy := cockpit.comfy_box.value.max (l_start)
			reader := reader.with_speeds (l_start, l_start.min (300), l_comfy)
		end

feature {NONE} -- Implementation

	reader: SIMPLE_SPEED_READER

	window: SW_WINDOW

	theme: SW_THEME

	stage: SR_STAGE_VIEW

	context_view: SR_CONTEXT_VIEW

	flow_map: SR_FLOW_MAP_VIEW

	cockpit: SR_COCKPIT

	logger: SIMPLE_LOGGER

	last_source, last_title: STRING_32

end
