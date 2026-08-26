note
	description: "[
		The honest account of one sealed sitting: what was dialed, what
		was achieved, what was skipped, how often attention was repaired.
	]"
	author: "Larry Rix"

class
	SR_RUN_RECORD

create
	make

feature {NONE} -- Initialization

	make (a_title: READABLE_STRING_GENERAL;
			a_streamed, a_skipped, a_pauses, a_rewinds, a_max_wpm, a_effective_wpm: INTEGER)
		require
			title_present: not a_title.is_empty
			counts_sane: a_streamed >= 0 and a_skipped >= 0 and a_pauses >= 0 and a_rewinds >= 0
			speeds_sane: a_max_wpm >= 0 and a_effective_wpm >= 0
		do
			create title.make_from_string_general (a_title)
			streamed_count := a_streamed
			skipped_count := a_skipped
			pause_count := a_pauses
			rewind_count := a_rewinds
			nominal_max_wpm := a_max_wpm
			effective_wpm := a_effective_wpm
		ensure
			streamed_kept: streamed_count = a_streamed
		end

feature -- Access

	title: STRING_32

	streamed_count: INTEGER
			-- Words actually shown.

	skipped_count: INTEGER
			-- Words passed over (foreign-skip filter, sentence skips).

	pause_count, rewind_count: INTEGER

	nominal_max_wpm: INTEGER
			-- Fastest the dial reached.

	effective_wpm: INTEGER
			-- streamed words over wall time - breathers, lingers and all.

	summary_line: STRING_32
			-- One cockpit-ready sentence.
		do
			create Result.make (96)
			Result.append_string_general ("Read ")
			Result.append_string_general (streamed_count.out)
			Result.append_string_general (" words - peak ")
			Result.append_string_general (nominal_max_wpm.out)
			Result.append_string_general (" WPM, effective ")
			Result.append_string_general (effective_wpm.out)
			Result.append_string_general (" WPM - ")
			Result.append_string_general (pause_count.out)
			Result.append_string_general (" pauses, ")
			Result.append_string_general (rewind_count.out)
			Result.append_string_general (" rewinds")
			if skipped_count > 0 then
				Result.append_string_general (", ")
				Result.append_string_general (skipped_count.out)
				Result.append_string_general (" skipped")
			end
		ensure
			told: not Result.is_empty
		end

invariant
	counts_sane: streamed_count >= 0 and skipped_count >= 0
		and pause_count >= 0 and rewind_count >= 0

end
