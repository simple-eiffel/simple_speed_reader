note
	description: "Contract-assault tests for the simple_speed_reader engine."
	author: "Larry Rix"
	testing: "covers"

class
	SPEED_READER_TEST_SET

inherit
	TEST_SET_BASE

feature -- Test: ORP law

	test_pivot_law
			-- Video-verified: 1->1, 2-5->2, 6-9->3, 10-13->4, 14+->5.
		local
			t: SR_TOKEN
		do
			create t.make ({STRING_32} "a", 1, 1, 1, True, True, False)
			assert_integers_equal ("len 1", 1, t.pivot_index)
			create t.make ({STRING_32} "But", 1, 1, 1, False, False, False)
			assert_integers_equal ("len 3", 2, t.pivot_index)
			create t.make ({STRING_32} "words", 1, 1, 1, False, False, False)
			assert_integers_equal ("len 5", 2, t.pivot_index)
			create t.make ({STRING_32} "reading", 1, 1, 1, False, False, False)
			assert_integers_equal ("len 7", 3, t.pivot_index)
			create t.make ({STRING_32} "narrowing.", 1, 1, 1, True, False, False)
			assert_integers_equal ("len 10", 4, t.pivot_index)
			create t.make ({STRING_32} "extraordinarily", 1, 1, 1, False, False, False)
			assert_integers_equal ("len 15", 5, t.pivot_index)
		end

	test_pivot_avoids_combining_marks
			-- A niqqud must never be the red letter.
		local
			t: SR_TOKEN
			l_w: STRING_32
		do
				-- bet + dagesh + shva + resh (0x05D1 0x05BC 0x05B0 0x05E8):
				-- pivot_for_length (4) = 2 lands on the dagesh; settled pivot steps left.
			create l_w.make (4)
			l_w.append_code (0x05D1)
			l_w.append_code (0x05BC)
			l_w.append_code (0x05B0)
			l_w.append_code (0x05E8)
			create t.make (l_w, 1, 1, 1, False, False, False)
			assert_integers_equal ("stepped to base letter", 1, t.pivot_index)
		end

feature -- Test: classification

	test_classification_hebrew
		local
			t: SR_TOKEN
			l_w: STRING_32
		do
			create l_w.make (4)
			l_w.append_code (0x05D1) -- bet
			l_w.append_code (0x05E8) -- resh
			create t.make (l_w, 1, 1, 1, False, False, False)
			assert_integers_equal ("hebrew", t.Script_hebrew, t.script)
			assert_true ("foreign", t.is_foreign_script)
			assert_false ("filtered out", t.streams_under_filter (True))
			assert_true ("streams when off", t.streams_under_filter (False))
		end

	test_classification_greek
		local
			t: SR_TOKEN
			l_w: STRING_32
		do
			create l_w.make (5)
			l_w.append_code (0x1F00) -- alpha with psili
			l_w.append_code (0x03B3) -- gamma
			l_w.append_code (0x03AC) -- alpha tonos
			create t.make (l_w, 1, 1, 1, False, False, False)
			assert_integers_equal ("greek", t.Script_greek, t.script)
		end

	test_classification_transliteration
		local
			t: SR_TOKEN
			l_w: STRING_32
		do
				-- agape with macron e: a g a p e-macron (0x0101? no - plain + 0x0113)
			create l_w.make (5)
			l_w.append_string_general ("agap")
			l_w.append_code (0x0113) -- e with macron
			create t.make (l_w, 1, 1, 1, False, False, False)
			assert_true ("latin", t.is_latin)
			assert_true ("diacritics", t.has_diacritics)
			assert_true ("still streams under filter", t.streams_under_filter (True))
		end

	test_classification_numeric_and_acronym
		local
			t: SR_TOKEN
		do
			create t.make ({STRING_32} "H7225", 1, 1, 1, False, False, False)
			assert_true ("strongs numeric", t.is_numeric)
			create t.make ({STRING_32} "LXX", 1, 1, 1, False, False, False)
			assert_true ("acronym", t.is_acronym)
			assert_false ("not numeric", t.is_numeric)
			create t.make ({STRING_32} "God", 1, 1, 1, False, False, False)
			assert_false ("capitalized word is no acronym", t.is_acronym)
		end

feature -- Test: tokenizer

	test_tokenizer_structure
		local
			tk: SR_TOKENIZER
			l_toks: ARRAYED_LIST [SR_TOKEN]
		do
			create tk
			l_toks := tk.tokenize ({STRING_32} "One two. Three!%N%NNew para, here.")
			assert_integers_equal ("token count", 6, l_toks.count)
			assert_false ("one flows", l_toks.i_th (1).ends_sentence)
			assert_true ("two. closes", l_toks.i_th (2).ends_sentence)
			assert_true ("three! closes", l_toks.i_th (3).ends_sentence)
			assert_true ("three! ends paragraph", l_toks.i_th (3).ends_paragraph)
			assert_integers_equal ("new starts sentence 3", 3, l_toks.i_th (4).sentence_index)
			assert_integers_equal ("new starts paragraph 2", 2, l_toks.i_th (4).paragraph_index)
			assert_true ("para, is clause", l_toks.i_th (5).has_clause_break)
			assert_true ("last closes", l_toks.last.ends_sentence)
			assert_true ("last ends paragraph", l_toks.last.ends_paragraph)
		end

	test_tokenizer_quoted_sentence_end
		local
			tk: SR_TOKENIZER
			l_toks: ARRAYED_LIST [SR_TOKEN]
		do
			create tk
			l_toks := tk.tokenize ({STRING_32} "He said %"stop.%" Then left.")
			assert_true ("quoted period closes", l_toks.i_th (3).ends_sentence)
		end

	test_tokenizer_blank_query
		local
			tk: SR_TOKENIZER
		do
			create tk
			assert_true ("whitespace only", tk.is_blank ({STRING_32} "  %T%N%N  "))
			assert_false ("substance", tk.is_blank ({STRING_32} " x "))
		end

feature -- Test: governor

	test_governor_ramp
		local
			g: SR_GOVERNOR
			i: INTEGER
		do
			create g.make (250, 250, 900)
			assert_integers_equal ("starts at start", 250, g.current_wpm)
			from i := 1 until i > 12 loop
				g.note_word_advanced
				i := i + 1
			end
			assert_integers_equal ("one interval climbs one step", 275, g.current_wpm)
			from i := 1 until i > 600 loop
				g.note_word_advanced
				i := i + 1
			end
			assert_integers_equal ("caps at comfy", 900, g.current_wpm)
			assert_integers_equal ("max seen", 900, g.max_seen_wpm)
		end

	test_governor_hold_and_release
		local
			g: SR_GOVERNOR
			i: INTEGER
		do
			create g.make (250, 250, 900)
			from i := 1 until i > 24 loop
				g.note_word_advanced
				i := i + 1
			end
			assert_integers_equal ("climbed twice", 300, g.current_wpm)
			g.hold
			assert_true ("held", g.is_held)
			assert_integers_equal ("pinned", 300, g.target_wpm)
			from i := 1 until i > 48 loop
				g.note_word_advanced
				i := i + 1
			end
			assert_integers_equal ("no climb while held", 300, g.current_wpm)
			g.release_hold
			assert_integers_equal ("ambition restored", 900, g.target_wpm)
		end

	test_governor_back_off_keeps_comfy
		local
			g: SR_GOVERNOR
		do
			create g.make (250, 250, 900)
			g.back_off (100)
			assert_integers_equal ("target lowered", 800, g.target_wpm)
			assert_integers_equal ("comfy untouched", 900, g.comfy_max_wpm)
			g.back_off (50)
			g.back_off (25)
			assert_integers_equal ("stacked", 725, g.target_wpm)
		end

	test_governor_back_off_after_hold_stays_low
		local
			g: SR_GOVERNOR
		do
			create g.make (250, 250, 900)
			g.hold
			g.back_off (100)
			assert_integers_equal ("pinned target lowered", 150, g.target_wpm)
			assert_integers_equal ("current follows pin", 150, g.current_wpm)
			g.release_hold
			assert_integers_equal ("release honors the back-off", 150, g.target_wpm)
		end

	test_governor_recovery
		local
			g: SR_GOVERNOR
			i: INTEGER
		do
			create g.make (250, 300, 900)
			from i := 1 until i > 240 loop
				g.note_word_advanced
				i := i + 1
			end
			assert_integers_equal ("climbed high", 750, g.current_wpm)
			g.reset_for_recovery
			assert_integers_equal ("back to recovery", 300, g.current_wpm)
			assert_integers_equal ("target stands", 900, g.target_wpm)
		end

feature -- Test: timing

	test_timing_base_and_length
		local
			tm: SR_TIMING_MODEL
			t: SR_TOKEN
		do
			create tm
			create t.make ({STRING_32} "word", 1, 1, 1, False, False, False)
			assert_integers_equal ("600 at 100", 600, tm.display_ms (t, 100))
			assert_integers_equal ("100 at 600", 100, tm.display_ms (t, 600))
			create t.make ({STRING_32} "extraordinarily", 1, 1, 1, False, False, False)
			assert_integers_equal ("12+ chars linger x1.5", 150, tm.display_ms (t, 600))
		end

	test_timing_foreign_floor
		local
			tm: SR_TIMING_MODEL
			t: SR_TOKEN
			l_w: STRING_32
		do
			create tm
			create l_w.make (2)
			l_w.append_code (0x05D1)
			l_w.append_code (0x05E8)
			create t.make (l_w, 1, 1, 1, False, False, False)
				-- At 900 WPM base is 66; foreign floor is base_ms (350) = 171.
			assert_greater_or_equal ("never faster than 350 effective",
				tm.display_ms (t, 900), tm.base_ms (350))
		end

	test_timing_breathers
		local
			tm: SR_TIMING_MODEL
			t: SR_TOKEN
		do
			create tm
			create t.make ({STRING_32} "flow", 1, 1, 1, False, False, False)
			assert_integers_equal ("plain flows", 0, tm.breather_ms (t, 300))
			create t.make ({STRING_32} "clause,", 1, 1, 1, False, False, True)
			assert_integers_equal ("clause one beat", 200, tm.breather_ms (t, 300))
			create t.make ({STRING_32} "end.", 1, 1, 1, True, False, False)
			assert_integers_equal ("sentence two beats", 400, tm.breather_ms (t, 300))
			create t.make ({STRING_32} "para.", 1, 1, 1, True, True, False)
			assert_integers_equal ("paragraph three beats", 600, tm.breather_ms (t, 300))
		end

feature -- Test: pacer

	test_pacer_anchoring_no_drift
		local
			p: SR_PACER
		do
			create p
			p.arm (1000, 100, 0)
			assert_false ("not yet", p.should_advance (1099))
			assert_true ("due", p.should_advance (1100))
				-- Tick arrives 7ms late; the NEXT deadline anchors to 1100, not 1107.
			p.reschedule (100, 0)
			assert_integers_equal ("anchored", 1200, p.next_deadline_ms)
			p.reschedule (100, 50)
			assert_integers_equal ("display end", 1300, p.display_end_ms)
			assert_integers_equal ("with breather", 1350, p.next_deadline_ms)
			assert_true ("breather window", p.in_breather (1320))
			assert_false ("past breather", p.in_breather (1350))
		end

	test_pacer_far_behind
		local
			p: SR_PACER
		do
			create p
			p.arm (1000, 100, 0)
			assert_false ("close is fine", p.is_far_behind (1500))
			assert_true ("a sleep is not a sprint", p.is_far_behind (2200))
		end

feature -- Test: session

	test_session_full_read
		local
			r: SIMPLE_SPEED_READER
			l_now: INTEGER
		do
			create r.make
			r := r.with_speeds (300, 300, 300)
			r.load_text ({STRING_32} "tiny", {STRING_32} "Alpha beta gamma. Delta done.")
			assert_true ("loaded", r.last_intake_ok)
			assert_integers_equal ("five tokens", 5, r.token_count)
			r.start_reading (0)
			assert_true ("running", r.is_running)
			assert_integers_equal ("on first", 1, r.position)
				-- 300 WPM: 200ms words; sentence breather 400ms extra.
			from l_now := 0 until r.is_sealed or l_now > 20000 loop
				l_now := l_now + 10
				r.tick (l_now)
			end
			assert_true ("sealed at end", r.is_sealed)
			assert_attached ("record", r.last_record)
			if attached r.last_record as al_rec then
				assert_integers_equal ("all streamed", 5, al_rec.streamed_count)
				assert_integers_equal ("none skipped", 0, al_rec.skipped_count)
				assert_greater_than ("effective computed", al_rec.effective_wpm, 0)
			end
		end

	test_session_pause_resume_recovery
		local
			r: SIMPLE_SPEED_READER
			l_now: INTEGER
		do
			create r.make
			r := r.with_speeds (600, 150, 900)
			r.load_text ({STRING_32} "t", {STRING_32} "One two three four five. Six seven eight nine ten.")
			r.start_reading (0)
			from l_now := 0 until r.position >= 4 or l_now > 10000 loop
				l_now := l_now + 10
				r.tick (l_now)
			end
			assert_integers_equal ("mid first sentence", 4, r.position)
			r.pause_reading
			assert_true ("paused", r.is_paused)
			r.resume_at (2, l_now)
			assert_true ("running again", r.is_running)
			assert_integers_equal ("moved back", 2, r.position)
			assert_integers_equal ("recovery speed", 150, r.current_wpm)
		end

	test_session_zero_click_resume
		local
			r: SIMPLE_SPEED_READER
			l_now: INTEGER
		do
			create r.make
			r := r.with_speeds (600, 200, 900)
			r.load_text ({STRING_32} "t", {STRING_32} "First one here. Second sentence words go on.")
			r.start_reading (0)
			from l_now := 0 until r.position >= 6 or l_now > 10000 loop
				l_now := l_now + 10
				r.tick (l_now)
			end
			r.pause_reading
			r.resume_at_sentence_start (l_now)
			assert_integers_equal ("head of second sentence", 4, r.position)
		end

	test_session_foreign_skip
		local
			r: SIMPLE_SPEED_READER
			l_src: STRING_32
			l_now: INTEGER
		do
			create r.make
			r := (create {SIMPLE_SPEED_READER}.make).with_speeds (300, 300, 300).with_foreign_skip (True)
			create l_src.make (40)
			l_src.append_string_general ("In the beginning ")
			l_src.append_code (0x05D1)
			l_src.append_code (0x05E8)
			l_src.append_string_general (" bara means created.")
			r.load_text ({STRING_32} "t", l_src)
			r.start_reading (0)
			from l_now := 0 until r.is_sealed or l_now > 20000 loop
				l_now := l_now + 10
				r.tick (l_now)
			end
			assert_true ("sealed", r.is_sealed)
			if attached r.last_record as al_rec then
				assert_integers_equal ("hebrew skipped", 1, al_rec.skipped_count)
				assert_integers_equal ("latin streamed", 6, al_rec.streamed_count)
			end
		end

	test_session_replay_and_skip
		local
			r: SIMPLE_SPEED_READER
			l_now: INTEGER
		do
			create r.make
			r := r.with_speeds (600, 300, 900)
			r.load_text ({STRING_32} "t", {STRING_32} "Aaa bbb ccc. Ddd eee fff. Ggg hhh.")
			r.start_reading (0)
			from l_now := 0 until r.position >= 5 or l_now > 10000 loop
				l_now := l_now + 10
				r.tick (l_now)
			end
			assert_integers_equal ("in second sentence", 5, r.position)
			r.replay_sentence (l_now)
			assert_integers_equal ("replays from its head", 4, r.position)
			assert_integers_equal ("speed untouched", 600, r.current_wpm)
			r.skip_sentence_forward (l_now)
			assert_integers_equal ("third sentence head", 7, r.position)
		end

	test_session_stop_keeps_position
		local
			r: SIMPLE_SPEED_READER
			l_now: INTEGER
		do
			create r.make
			r.load_text ({STRING_32} "t", {STRING_32} "One two three four five six.")
			r.start_reading (0)
			from l_now := 0 until r.position >= 3 or l_now > 10000 loop
				l_now := l_now + 10
				r.tick (l_now)
			end
			r.stop_and_seal
			assert_true ("sealed", r.is_sealed)
			assert_integers_equal ("position kept", 3, r.position)
			assert_attached ("record built", r.last_record)
		end

	test_facade_blank_intake
		local
			r: SIMPLE_SPEED_READER
		do
			create r.make
			r.load_text ({STRING_32} "t", {STRING_32} "   %N%N  ")
			assert_false ("refused", r.last_intake_ok)
			assert_false ("no text", r.has_text)
		end

end
