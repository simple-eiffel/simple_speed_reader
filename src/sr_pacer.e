note
	description: "[
		The deadline scheduler binding wall-clock ticks to word advances.
		Deadlines anchor to the PREVIOUS deadline, never to now, so tick
		jitter costs at most one tick of display time and never drifts.
	]"
	author: "Larry Rix"

class
	SR_PACER

feature -- Access

	is_armed: BOOLEAN

	next_deadline_ms: INTEGER
			-- When the current word's stage time (display + breather) ends.

	display_end_ms: INTEGER
			-- When the word blanks into its breather.

feature -- Status

	should_advance (a_now_ms: INTEGER): BOOLEAN
			-- Has the current word's deadline passed?
		do
			Result := is_armed and then a_now_ms - next_deadline_ms >= 0
		end

	in_breather (a_now_ms: INTEGER): BOOLEAN
			-- Blank-stage portion of the current word's time?
		do
			Result := is_armed and then a_now_ms - display_end_ms >= 0
				and then a_now_ms - next_deadline_ms < 0
		end

	is_far_behind (a_now_ms: INTEGER): BOOLEAN
			-- Deadline lags reality by more than Catchup_limit_ms
			-- (machine slept, window dragged): re-anchor, don't machine-gun.
		do
			Result := is_armed and then a_now_ms - next_deadline_ms > Catchup_limit_ms
		end

feature -- Commands

	arm (a_now_ms, a_display_ms, a_breather_ms: INTEGER)
			-- Fresh anchor at now (start, resume, re-anchor).
		require
			display_positive: a_display_ms > 0
			breather_non_negative: a_breather_ms >= 0
		do
			display_end_ms := a_now_ms + a_display_ms
			next_deadline_ms := display_end_ms + a_breather_ms
			is_armed := True
		ensure
			armed: is_armed
			ordered: next_deadline_ms >= display_end_ms
		end

	reschedule (a_display_ms, a_breather_ms: INTEGER)
			-- Next word's window, anchored to the old deadline: no drift.
		require
			armed: is_armed
			display_positive: a_display_ms > 0
			breather_non_negative: a_breather_ms >= 0
		do
			display_end_ms := next_deadline_ms + a_display_ms
			next_deadline_ms := display_end_ms + a_breather_ms
		ensure
			anchored: display_end_ms = old next_deadline_ms + a_display_ms
			ordered: next_deadline_ms >= display_end_ms
		end

	disarm
		do
			is_armed := False
		ensure
			disarmed: not is_armed
		end

feature -- Constants

	Catchup_limit_ms: INTEGER = 1000

invariant
	ordered_when_armed: is_armed implies next_deadline_ms >= display_end_ms

end
