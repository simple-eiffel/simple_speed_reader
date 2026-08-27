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
			create transport.make (reader)
			create cockpit.make (settings.start_wpm, settings.comfy_max_wpm,
				settings.skip_foreign, settings.quiz_opt_in)
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
			create l_row.make
			l_row.put (flow_map.surface)
			l_row.put (stage.surface)
			running_root := l_row
			create l_col.make
			l_col.put (ribbon.surface)
			create l_row.make
			l_row.put (flow_map.surface)
			l_row.put (stage.surface)
			l_row.set_grow (1.0)
			l_col.put (l_row)
			braking_root := l_col
			create l_col.make
			l_col.put (ribbon.surface)
			create l_row.make
			l_row.put (flow_map.surface)
			l_row.put (context_view.surface)
			l_row.set_grow (1.0)
			l_col.put (l_row)
			l_col.put (transport.surface)
			paused_root := l_col
			cockpit_root := cockpit.root
			posture := Posture_cockpit

				-- Phase 2: wiring - Current may now escape into agents.
			stage.surface.set_on_char (agent on_reading_char)
			stage.surface.set_on_key (agent on_reading_vk)
			stage.surface.set_on_press (agent on_stage_press)
			stage.surface.set_on_sweep (agent on_stage_sweep)
			stage.surface.set_on_release (agent on_stage_release)
			context_view.surface.set_on_char (agent on_paused_char)
			context_view.set_on_word_click (agent on_word_marked)
			flow_map.set_on_seek (agent on_map_seek)
			cockpit.wire (
				agent on_load_file_asked, agent on_start_asked, agent on_continue_asked,
				agent on_start_wpm_changed, agent on_comfy_changed,
				agent on_skip_toggled, agent on_quiz_toggled, agent on_quiz_preview,
				agent on_quiz_reveal, agent on_quiz_judged (True), agent on_quiz_judged (False))
			transport.wire (agent on_paused_resume_clicked, agent on_paused_here_clicked,
				agent do_stop, agent open_speed_drawer,
				agent on_deck_brake_press, agent do_brake_release)
			ribbon.set_on_word_click (agent on_word_marked)
			stage.surface.set_on_files (agent on_files_dropped)
			context_view.surface.set_on_files (agent on_files_dropped)
			ribbon.surface.set_on_files (agent on_files_dropped)
			flow_map.surface.set_on_files (agent on_files_dropped)
			cockpit.drop_zone.set_on_drop (agent on_files_dropped)
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
			-- polls the quiz worker's mailbox file.
		do
			if not is_fast_timer_armed then
				is_fast_timer_armed := True
				window.set_fast_timer (Tick_ms)
			end
			poll_quiz_worker
		end

	on_shell_event (a_type, a_a, a_b: INTEGER)
		local
			l_now, l_sig: INTEGER
		do
			if a_type = 25 then
				l_now := window.tick_ms
					-- The brake pedal (D-016): engage after a held press,
					-- glide every tick, scrub while dragged left.
				if is_press_live and then not brake_engaged and then reader.is_running
					and then l_now - press_ms > Hold_engage_ms
				then
					brake_engaged := True
					scrub_mode := False
					scrub_accumulator := 0.0
					reader.apply_brake
					logger.info ("brake engaged at word " + reader.position.out)
					window.set_root (braking_root)
				end
				if reader.is_brake_active then
					reader.brake_tick
				end
				if brake_engaged and scrub_mode and reader.is_running then
					scrub_accumulator := scrub_accumulator
						+ ((scrub_dx.abs - Brake_drag_px) / 15.0).max (0.0).min (14.0) * 0.012
					from
					until
						scrub_accumulator < 1.0 or not reader.is_running
					loop
						reader.scrub_back_word (l_now)
						scrub_accumulator := scrub_accumulator - 1.0
					end
				elseif not (brake_engaged and scrub_mode) then
					reader.tick (l_now)
				end
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

	running_root, paused_root, cockpit_root, braking_root: SW_WIDGET

	is_press_live, brake_engaged, scrub_mode: BOOLEAN

	quiz_generating, quiz_admin_active: BOOLEAN

	pending_record: detachable SR_RUN_RECORD

	press_ms, scrub_dx: INTEGER

	press_x: REAL_64

	scrub_accumulator: REAL_64

	Hold_engage_ms: INTEGER = 220

	Brake_drag_px: INTEGER = 40

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
			reset_brake_gesture
			window.set_root (paused_root)
			window.give_focus (context_view.surface)
			window.request_render
		end

	reset_brake_gesture
			-- Leaving the running stream mid-gesture: tidy the pedal.
		do
			is_press_live := False
			brake_engaged := False
			scrub_mode := False
			if reader.is_braking then
				reader.release_brake
			end
		end

	to_cockpit
		do
			posture := Posture_cockpit
			reset_brake_gesture
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
			-- The stage is the pedal (D-016): a quick tap pauses, a
			-- held press brakes (engaged from the tick handler).
		do
			if reader.is_running then
				is_press_live := True
				press_ms := window.tick_ms
				press_x := a_px
				scrub_dx := 0
			end
		end

	on_stage_sweep (a_px, a_py: REAL_64)
			-- Drag while the pedal is down: left of the press point
			-- scrubs backward, right re-engages forward flow.
		do
			if brake_engaged then
				scrub_dx := (a_px - press_x).truncated_to_integer
				scrub_mode := scrub_dx < -Brake_drag_px
			end
		end

	on_stage_release (a_x, a_y: INTEGER)
			-- Pedal up: a tap becomes the pause; a brake eases home.
		do
			if is_press_live then
				is_press_live := False
				if brake_engaged then
					do_brake_release
				else
					do_pause
				end
			end
		end

	do_brake_release
			-- Shared by the stage pedal and the deck's BRAKE button.
		do
			brake_engaged := False
			scrub_mode := False
			if reader.is_braking then
				reader.release_brake
				logger.info ("brake released at word " + reader.position.out
					+ " (" + reader.current_wpm.out + " wpm, easing home)")
			end
			if posture = Posture_running then
				window.set_root (running_root)
				window.give_focus (stage.surface)
				window.request_render
			end
		end

	on_deck_brake_press
			-- The deck's pedal, pressed while PAUSED: resume braked -
			-- back into the stream at the crawl, ribbon flowing; let go
			-- and it eases up to cruise.
		do
			if reader.is_paused then
				reader.resume_at_sentence_start (window.tick_ms)
				posture := Posture_running
				brake_engaged := True
				scrub_mode := False
				scrub_accumulator := 0.0
				if not reader.is_brake_active then
					reader.apply_brake
				end
				logger.info ("deck pedal: resumed braked at word " + reader.position.out)
				window.set_root (braking_root)
				window.give_focus (stage.surface)
				window.request_render
			end
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
			-- The ledger row and the crash-safe bookmark, at every
			-- seal. With an armed quiz, the row WAITS: administration
			-- happens in the cockpit and the score joins the record.
		do
			if attached reader.last_record as al_rec then
				if settings.quiz_opt_in and then reader.quiz_ready
					and then al_rec.streamed_count > 0
				then
					pending_record := al_rec
					quiz_admin_active := True
					show_current_quiz_question
					logger.info ("seal held for quiz administration")
				else
					ledger.record_run (al_rec, -1)
					logger.info ({STRING_32} "sealed - " + al_rec.summary_line)
				end
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

feature {NONE} -- The quiz pipeline (D-007, worker-process pattern)

	Quiz_in_name: STRING = "quiz_in.txt"

	Quiz_out_name: STRING = "quiz_out.json"

	start_quiz_generation
			-- Spawn the worker on the loaded text; the heartbeat polls.
		local
			l_p: SIMPLE_PROCESS
			l_cmd: STRING_32
			l_n: INTEGER
		do
			if settings.quiz_opt_in and then reader.has_text
				and then not worker_exe_path.is_empty
			then
				delete_quiet (Quiz_out_name)
				write_utf8_file (Quiz_in_name, reader.source_text)
				l_n := (reader.token_count * 3 // 800).max (3).min (10)
				create l_cmd.make (256)
				l_cmd.append_code (34)
				l_cmd.append (worker_exe_path)
				l_cmd.append_code (34)
				l_cmd.append_string_general (" --quiz " + Quiz_in_name + " " + Quiz_out_name + " ")
				l_cmd.append (settings.ollama_url)
				l_cmd.append_string_general (" %"")
				l_cmd.append (settings.ollama_model)
				l_cmd.append_string_general ("%" ")
				l_cmd.append_string_general (l_n.out)
				create l_p.make
				l_p.launch (l_cmd)
				quiz_generating := True
				cockpit.set_quiz_status ("quiz: generating on your GPU...")
				logger.info ({STRING_32} "quiz worker spawned: " + l_cmd)
			elseif settings.quiz_opt_in and then worker_exe_path.is_empty then
				cockpit.set_quiz_status ("quiz: worker exe not found")
				logger.warn ("quiz worker exe not found")
			end
		end

	poll_quiz_worker
			-- The 250 ms mailbox check (FR-022's streaming spirit).
		local
			l_json: STRING_32
		do
			if quiz_generating and then file_exists (Quiz_out_name) then
				quiz_generating := False
				l_json := read_utf8_file (Quiz_out_name)
				if not l_json.is_empty and then reader.has_text then
					reader.attach_quiz_json (l_json)
					if attached reader.quiz as al_q then
						if al_q.is_usable then
							cockpit.set_quiz_status ("quiz ready: " + al_q.questions.count.out
								+ " questions (" + al_q.dropped_count.out + " dropped by the quote gate)")
							logger.info ("quiz ready: " + al_q.questions.count.out
								+ " verified, " + al_q.dropped_count.out + " dropped")
						else
							cockpit.set_quiz_status ({STRING_32} "quiz unavailable: " + al_q.error_line)
							logger.warn ({STRING_32} "quiz unavailable: " + al_q.error_line)
						end
					end
				end
				window.request_render
			end
		end

	worker_exe_path: STRING_32
			-- Installed sibling first; the dev-tree target second.
		do
			if file_exists ("speed_reader_worker.exe") then
				Result := {STRING_32} "speed_reader_worker.exe"
			elseif file_exists ("..\..\speed_reader_worker\F_code\simple_speed_reader.exe") then
				Result := {STRING_32} "..\..\speed_reader_worker\F_code\simple_speed_reader.exe"
			else
				create Result.make_empty
			end
		end

	on_quiz_toggled
		do
			settings.set_quiz_opt_in (cockpit.quiz_on)
			if cockpit.quiz_on and then reader.has_text and then not reader.quiz_ready then
				start_quiz_generation
			end
		end

	on_quiz_preview
			-- SQ3R: the questions, before the reading - in a drawer.
		local
			l_drawer: SW_DRAWER
		do
			if attached reader.quiz as al_q and then al_q.is_usable then
				create l_drawer.make_titled ("Quiz preview (SQ3R)")
				across
					al_q.questions as q
				loop
					l_drawer.put (create {SW_LABEL}.make_body (q.prompt))
				end
				l_drawer.set_on_close (agent close_speed_drawer)
				window.show_drawer (l_drawer, 460.0, False)
				window.request_render
			else
				cockpit.set_quiz_status ("quiz: nothing to preview yet")
				window.request_render
			end
		end

	show_current_quiz_question
		do
			if attached reader.quiz as al_q and then al_q.is_usable
				and then not al_q.is_administration_done
			then
				cockpit.set_admin_texts ({STRING_32} "Q" + al_q.administration_index.out
					+ {STRING_32} "/" + al_q.questions.count.out + {STRING_32} ":  "
					+ al_q.current_question.prompt, "")
			end
		end

	on_quiz_reveal
		do
			if quiz_admin_active and then attached reader.quiz as al_q
				and then al_q.is_usable and then not al_q.is_administration_done
			then
				cockpit.set_admin_texts ({STRING_32} "Q" + al_q.administration_index.out
					+ {STRING_32} "/" + al_q.questions.count.out + {STRING_32} ":  "
					+ al_q.current_question.prompt,
					{STRING_32} "A: " + al_q.current_question.expected_answer
					+ {STRING_32} "   -   proof: %"" + al_q.current_question.supporting_quote + {STRING_32} "%"")
				window.request_render
			end
		end

	on_quiz_judged (a_got_it: BOOLEAN)
		do
			if quiz_admin_active and then attached reader.quiz as al_q
				and then al_q.is_usable and then not al_q.is_administration_done
			then
				al_q.judge_current (a_got_it)
				if al_q.is_administration_done then
					finish_quiz_administration (al_q.score_percent)
				else
					show_current_quiz_question
				end
				window.request_render
			end
		end

	finish_quiz_administration (a_score: INTEGER)
		do
			quiz_admin_active := False
			cockpit.set_admin_texts ("", "")
			if attached pending_record as al_rec then
				ledger.record_run (al_rec, a_score)
				logger.info ({STRING_32} "sealed with quiz " + a_score.out
					+ {STRING_32} "%% - " + al_rec.summary_line)
				pending_record := Void
			end
			cockpit.set_quiz_status ("quiz score: " + a_score.out + "%%")
			cockpit.show_history (ledger.recent_lines (6))
		end

	flush_pending_record
			-- A new sitting begins while a quiz waited: record honestly
			-- with whatever was judged, or untested.
		do
			if attached pending_record as al_rec then
				if attached reader.quiz as al_q and then al_q.judged_count > 0 then
					ledger.record_run (al_rec, al_q.score_percent)
				else
					ledger.record_run (al_rec, -1)
				end
				pending_record := Void
			end
			quiz_admin_active := False
			cockpit.set_admin_texts ("", "")
		end

feature {NONE} -- Small file plumbing (worker mailbox)

	file_exists (a_path: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := (create {RAW_FILE}.make_with_name (a_path)).exists
		end

	delete_quiet (a_path: READABLE_STRING_GENERAL)
		local
			l_f: RAW_FILE
		do
			create l_f.make_with_name (a_path)
			if l_f.exists then
				l_f.delete
			end
		end

	write_utf8_file (a_path: READABLE_STRING_GENERAL; a_content: STRING_32)
		local
			l_f: RAW_FILE
			l_enc: SIMPLE_ENCODING
		do
			create l_enc.make
			create l_f.make_create_read_write (a_path)
			l_f.put_string (l_enc.utf_32_to_utf_8 (a_content))
			l_f.close
		end

	read_utf8_file (a_path: READABLE_STRING_GENERAL): STRING_32
		local
			l_f: RAW_FILE
			l_raw: STRING_8
			l_enc: SIMPLE_ENCODING
		do
			create Result.make_empty
			create l_f.make_with_name (a_path)
			if l_f.exists and then l_f.is_readable and then l_f.count > 0 then
				l_f.open_read
				l_f.read_stream (l_f.count)
				l_raw := l_f.last_string.twin
				l_f.close
				create l_enc.make
				Result := l_enc.utf_8_to_utf_32 (l_raw)
			end
		end

feature {NONE} -- Cockpit actions

	on_start_asked
		local
			l_pasted: STRING_32
		do
			flush_pending_record
			apply_speed_prefs
			l_pasted := cockpit.pasted_text
			if not l_pasted.is_empty and then not l_pasted.same_string (last_source) then
				last_source := l_pasted.twin
				last_title := {STRING_32} "pasted text"
				current_file_path := {STRING_32} "" -- pasted: no file to continue from
				reader.load_text (last_title, last_source)
				start_quiz_generation
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
			fd.set_extension_filter (".txt;.md;.pdf")
			fd.set_on_accept (agent on_file_picked)
			window.show_sheet (fd, 680.0)
			logger.info ("open-file dialog shown - " + fd.available_drives.count.out + " drives")
		end

	on_file_picked (a_path: STRING_32)
		do
			window.close_sheet
			load_any (a_path)
		end

	load_any (a_path: STRING_32)
			-- One intake door: .pdf goes through the extractor,
			-- everything else through the UTF-8 file path.
		do
			flush_pending_record
			apply_speed_prefs
			if a_path.as_lower.ends_with ({STRING_32} ".pdf") then
				load_pdf (a_path)
			else
				reader.load_file (a_path)
			end
			if reader.last_intake_ok then
				last_source := reader.loaded_source.twin -- already UTF-8-decoded
				last_title := reader.title.twin
				current_file_path := a_path.twin
				logger.info ({STRING_32} "loaded " + a_path
					+ {STRING_32} " - " + reader.token_count.out + {STRING_32} " words")
				start_quiz_generation
			else
				logger.error ({STRING_32} "intake failed: " + reader.last_intake_error)
			end
			cockpit.refresh (reader)
			window.request_render
		end

	load_pdf (a_path: STRING_32)
			-- Text layer out of a PDF via simple_pdf's pdftotext
			-- (Poppler), UTF-8 decoded; honest refusals for missing
			-- extractor, non-ASCII paths (pdftotext's 8-bit door),
			-- and text-free scans.
		local
			l_ex: SIMPLE_PDF_READER
			l_raw: STRING
			l_enc: SIMPLE_ENCODING
			l_decoded, l_title: STRING_32
			i: INTEGER
		do
			if file_exists ("pdftotext.exe") then
				create l_ex.make_with_path ("pdftotext.exe")
			elseif file_exists ("D:\prod\simple_pdf\bin\pdftotext.exe") then
				create l_ex.make_with_path ("D:\prod\simple_pdf\bin\pdftotext.exe")
			else
				create l_ex.make
			end
			if not l_ex.is_available then
				force_refusal ({STRING_32} "PDF extractor (pdftotext.exe) not found")
			elseif not a_path.is_valid_as_string_8 then
				force_refusal ({STRING_32} "PDF path has non-ASCII characters - move or rename it")
			else
				l_raw := l_ex.extract_text (a_path.to_string_8)
				create l_enc.make
				l_decoded := l_enc.utf_8_to_utf_32 (l_raw)
				if l_decoded.count < 20 then
					force_refusal ({STRING_32} "PDF has no text layer (a scan?) - nothing to stream")
				else
					create l_title.make_from_string_general (a_path)
					i := l_title.last_index_of ({CHARACTER_32} '\', l_title.count).max (
						l_title.last_index_of ({CHARACTER_32} '/', l_title.count))
					if i > 0 then
						l_title.remove_head (i)
					end
					reader.load_text (l_title, l_decoded)
				end
			end
		end

	force_refusal (a_why: STRING_32)
			-- Land the facade in an honest refused-intake state and
			-- surface the reason (a blank load is the refusal door).
		do
			reader.load_text ({STRING_32} "refused", {STRING_32} "  ")
			logger.error ({STRING_32} "pdf intake: " + a_why)
			cockpit.set_quiz_status (a_why)
		end

	on_files_dropped (a_paths: ARRAYED_LIST [STRING_32])
			-- Explorer drag-and-drop, any posture: the first path wins;
			-- a live sitting is sealed honestly first.
		do
			if not a_paths.is_empty then
				logger.info ({STRING_32} "dropped: " + a_paths.first)
				if reader.is_running or reader.is_paused then
					reader.stop_and_seal
					record_seal
				end
				load_any (a_paths.first)
				to_cockpit
			end
		end

	on_continue_asked
			-- FR-032: back into the last text at the saved word.
		local
			l_at: INTEGER
		do
			flush_pending_record
			apply_speed_prefs
			if not settings.last_file_path.is_empty and then settings.last_position > 0 then
				load_any (settings.last_file_path)
				if reader.last_intake_ok and then reader.can_start then
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

	hold_button, backoff_100_button, backoff_50_button,
	backoff_25_button, nudge_up_button, nudge_down_button: SW_BUTTON

	transport: SR_TRANSPORT_VIEW

	logger: SIMPLE_LOGGER

	settings: SR_SETTINGS

	ledger: SR_LOG

	last_source, last_title, current_file_path: STRING_32

end
