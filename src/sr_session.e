note
	description: "[
		One sitting with one text: the state machine (stopped - running -
		paused), the position, the honest record. PAUSE keeps the sitting
		alive; STOP seals it. Transport semantics per D-014; the
		foreign-skip presentation filter per D-013.
	]"
	author: "Larry Rix"

class
	SR_SESSION

create
	make_with_text

feature {NONE} -- Initialization

	make_with_text (a_text: SR_TEXT; a_governor: SR_GOVERNOR; a_timing: SR_TIMING_MODEL)
		do
			text := a_text
			governor := a_governor
			timing := a_timing
			state := State_stopped
			create pacer
			create timestamps.make (a_text.token_count)
			create rewind_spans.make (4)
		ensure
			text_kept: text = a_text
			starts_stopped: is_stopped
			unsealed: not is_sealed
		end

feature -- States (exactly one; D-012)

	is_stopped: BOOLEAN
		do
			Result := state = State_stopped
		end

	is_running: BOOLEAN
		do
			Result := state = State_running
		end

	is_paused: BOOLEAN
		do
			Result := state = State_paused
		end

	is_sealed: BOOLEAN
			-- Sitting ended: record built, position kept.

feature -- Access

	text: SR_TEXT

	governor: SR_GOVERNOR

	position: INTEGER
			-- Token index on stage; 0 before the first word.

	pause_count, streamed_count, skipped_count: INTEGER

	rewind_spans: ARRAYED_LIST [INTEGER]

	skip_foreign: BOOLEAN
			-- D-013 presentation filter.

	last_record: detachable SR_RUN_RECORD

	effective_wpm: INTEGER
			-- Streamed words over wall time so far; 0 until two stamps.
		local
			l_elapsed: INTEGER
		do
			if timestamps.count >= 2 then
				l_elapsed := timestamps.last - timestamps.first
				if l_elapsed > 0 then
					Result := (timestamps.count - 1) * 60000 // l_elapsed
				end
			end
		ensure
			non_negative: Result >= 0
		end

	in_breather (a_now_ms: INTEGER): BOOLEAN
		do
			Result := is_running and then pacer.in_breather (a_now_ms)
		end

	has_streamable: BOOLEAN
			-- Any token at all passes the filter?
		do
			Result := next_streamable (1) > 0
		end

	sentence_start (a_index: INTEGER): INTEGER
			-- First token of the sentence containing `a_index'.
		require
			in_text: a_index >= 1 and a_index <= text.token_count
		do
			from
				Result := a_index
			until
				Result = 1 or else
					text.token (Result - 1).sentence_index /= text.token (a_index).sentence_index
			loop
				Result := Result - 1
			end
		ensure
			in_text: Result >= 1 and Result <= a_index
			same_sentence: text.token (Result).sentence_index = text.token (a_index).sentence_index
		end

feature -- Element change

	set_skip_foreign (a_on: BOOLEAN)
		do
			skip_foreign := a_on
		ensure
			set: skip_foreign = a_on
		end

feature -- Transport commands (D-014)

	preset_position (a_index: INTEGER)
			-- Place the session at `a_index' before it starts - the
			-- "Continue at word N" doorway (FR-032).
		require
			stopped: is_stopped
			unsealed: not is_sealed
			in_text: a_index >= 1 and a_index <= text.token_count
		do
			position := a_index
		ensure
			placed: position = a_index
		end

	start_reading (a_now_ms: INTEGER)
			-- Stopped -> running, at the first streamable word (or where
			-- a previous pause left the position).
		require
			stopped: is_stopped
			unsealed: not is_sealed
			something_to_stream: has_streamable
		local
			l_at: INTEGER
		do
			if position = 0 then
				l_at := next_streamable (1)
				skipped_count := skipped_count + (l_at - 1)
				position := l_at
			end
			state := State_running
			stamp_and_arm (a_now_ms)
		ensure
			running: is_running
			placed: position >= 1
		end

	pause_reading
			-- Running -> paused: context page time; the sitting lives on.
		require
			running: is_running
		do
			state := State_paused
			pacer.disarm
			pause_count := pause_count + 1
		ensure
			paused: is_paused
			pause_recorded: pause_count = old pause_count + 1
			position_frame: position = old position
		end

	resume_at (a_index, a_now_ms: INTEGER)
			-- Paused -> running at the reader-marked comprehension point,
			-- re-ramping from recovery speed (DR-004).
		require
			paused: is_paused
			in_text: a_index >= 1 and a_index <= text.token_count
			never_forward: a_index <= position
		do
			rewind_spans.extend (position - a_index)
			position := a_index
			governor.reset_for_recovery
			state := State_running
			stamp_and_arm (a_now_ms)
		ensure
			running: is_running
			moved_back: position = a_index
			rewind_recorded: rewind_spans.count = old rewind_spans.count + 1
		end

	resume_at_sentence_start (a_now_ms: INTEGER)
			-- The zero-click default: back to the stopped sentence's head.
		require
			paused: is_paused
			placed: position >= 1
		do
			resume_at (sentence_start (position), a_now_ms)
		ensure
			running: is_running
		end

	replay_sentence (a_now_ms: INTEGER)
			-- Micro-rewind (Left while running): replay from this
			-- sentence's head - or the previous sentence's when already
			-- on a head. Speed untouched: a lapse, not a collapse.
		require
			running: is_running
			placed: position >= 1
		local
			l_t: INTEGER
		do
			l_t := sentence_start (position)
			if l_t = position and position > 1 then
				l_t := sentence_start (position - 1)
			end
			position := l_t
			stamp_and_arm (a_now_ms)
		ensure
			still_running: is_running
			moved_back: position <= old position
			speed_untouched: governor.current_wpm = old governor.current_wpm
		end

	skip_sentence_forward (a_now_ms: INTEGER)
			-- Jump to the next sentence's first streamable word; the
			-- jumped words are logged as skipped. Seals at text end.
		require
			running: is_running
			placed: position >= 1
		local
			i, l_next: INTEGER
		do
			from
				i := position + 1
			until
				i > text.token_count or else
					text.token (i).sentence_index > text.token (position).sentence_index
			loop
				i := i + 1
			end
			if i > text.token_count then
				seal (Seal_finished)
			else
				l_next := next_streamable (i)
				if l_next = 0 then
					skipped_count := skipped_count + (text.token_count - position)
					seal (Seal_finished)
				else
					skipped_count := skipped_count + (l_next - position - 1)
					position := l_next
					stamp_and_arm (a_now_ms)
				end
			end
		ensure
			forward_or_sealed: is_sealed or position > old position
		end

	tick (a_now_ms: INTEGER)
			-- The clock: advance when the current word's deadline passed.
		do
			if is_running and then pacer.should_advance (a_now_ms) then
				advance (a_now_ms)
			end
		end

	stop_and_seal
			-- Running or paused -> stopped, the sitting's record built.
			-- Position is KEPT (audiobook stop, not VLC stop).
		require
			live: is_running or is_paused
		do
			seal (Seal_stopped)
		ensure
			stopped: is_stopped
			sealed: is_sealed
			recorded: last_record /= Void
			position_kept: position = old position
		end

feature {NONE} -- Implementation

	timing: SR_TIMING_MODEL

	pacer: SR_PACER

	timestamps: ARRAYED_LIST [INTEGER]

	state: INTEGER

	State_stopped: INTEGER = 1
	State_running: INTEGER = 2
	State_paused: INTEGER = 3

	Seal_stopped: INTEGER = 1
	Seal_finished: INTEGER = 2

	advance (a_now_ms: INTEGER)
			-- Next streamable word - or the end of the text.
		require
			running: is_running
		local
			l_next: INTEGER
		do
			l_next := next_streamable (position + 1)
			if l_next = 0 then
				skipped_count := skipped_count + (text.token_count - position)
				seal (Seal_finished)
			else
				skipped_count := skipped_count + (l_next - position - 1)
				position := l_next
				governor.note_word_advanced
				timestamps.extend (a_now_ms)
				streamed_count := streamed_count + 1
				if pacer.is_far_behind (a_now_ms) then
					pacer.arm (a_now_ms, timing.display_ms (text.token (position), governor.current_wpm),
						timing.breather_ms (text.token (position), governor.current_wpm))
				else
					pacer.reschedule (timing.display_ms (text.token (position), governor.current_wpm),
						timing.breather_ms (text.token (position), governor.current_wpm))
				end
			end
		ensure
			moved_or_sealed: is_sealed or position > old position
		end

	stamp_and_arm (a_now_ms: INTEGER)
			-- The word at `position' begins its stage time now.
		require
			placed: position >= 1 and position <= text.token_count
		do
			timestamps.extend (a_now_ms)
			streamed_count := streamed_count + 1
			pacer.arm (a_now_ms, timing.display_ms (text.token (position), governor.current_wpm),
				timing.breather_ms (text.token (position), governor.current_wpm))
		end

	next_streamable (a_from: INTEGER): INTEGER
			-- First index at or past `a_from' passing the filter; 0 if none.
		local
			i: INTEGER
		do
			from
				i := a_from.max (1)
			until
				i > text.token_count or Result > 0
			loop
				if text.token (i).streams_under_filter (skip_foreign) then
					Result := i
				end
				i := i + 1
			end
		ensure
			found_streams: Result > 0 implies
				text.token (Result).streams_under_filter (skip_foreign)
		end

	seal (a_kind: INTEGER)
			-- Build the record; the sitting is over.
		do
			create last_record.make (text.title,
				streamed_count, skipped_count, pause_count, rewind_spans.count,
				governor.max_seen_wpm, effective_wpm)
			is_sealed := True
			state := State_stopped
			pacer.disarm
		ensure
			sealed: is_sealed and is_stopped
			recorded: last_record /= Void
		end

invariant
	one_state: state >= State_stopped and state <= State_paused
	sealed_is_stopped: is_sealed implies is_stopped
	position_in_text: position >= 0 and position <= text.token_count
	counts_sane: streamed_count >= 0 and skipped_count >= 0 and pause_count >= 0

end
