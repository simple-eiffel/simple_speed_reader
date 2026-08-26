note
	description: "[
		How long a token owns the stage at a given WPM, and the blank
		breather after it (the video's dark frames). Pure queries; every
		linger class of D-011 is priced here and nowhere else.
	]"
	author: "Larry Rix"

class
	SR_TIMING_MODEL

feature -- Queries (pure)

	base_ms (a_wpm: INTEGER): INTEGER
			-- The plain word's share of a minute.
		require
			speed_lawful: a_wpm >= {SR_GOVERNOR}.Min_wpm
		do
			Result := 60000 // a_wpm
		ensure
			positive: Result > 0
		end

	display_ms (a_token: SR_TOKEN; a_wpm: INTEGER): INTEGER
			-- Base times the token's linger class, capped at x3; foreign
			-- script never faster than an effective Foreign_ceiling_wpm.
		require
			speed_lawful: a_wpm >= {SR_GOVERNOR}.Min_wpm
		local
			l_m: REAL_64
			l_base: INTEGER
		do
			l_base := base_ms (a_wpm)
			l_m := length_multiplier (a_token.word.count)
			if a_token.is_foreign_script then
				l_m := l_m.max (2.5)
			end
			if a_token.has_diacritics then
				l_m := l_m.max (1.6)
			end
			if a_token.is_numeric then
				l_m := l_m.max (1.8)
			end
			if a_token.is_acronym then
				l_m := l_m.max (1.4)
			end
			l_m := l_m.min (3.0)
			Result := (l_base * l_m).truncated_to_integer.max (l_base)
			if a_token.is_foreign_script then
				Result := Result.max (base_ms (Foreign_ceiling_wpm))
			end
		ensure
			positive: Result > 0
			at_least_base: Result >= base_ms (a_wpm)
			foreign_floored: (a_token.is_foreign_script and a_wpm > Foreign_ceiling_wpm)
				implies Result >= base_ms (Foreign_ceiling_wpm)
		end

	breather_ms (a_token: SR_TOKEN; a_wpm: INTEGER): INTEGER
			-- Blank stage after the token: 1 beat clause, 2 sentence,
			-- 3 paragraph; plain words flow.
		require
			speed_lawful: a_wpm >= {SR_GOVERNOR}.Min_wpm
		do
			if a_token.ends_paragraph then
				Result := 3 * base_ms (a_wpm)
			elseif a_token.ends_sentence then
				Result := 2 * base_ms (a_wpm)
			elseif a_token.has_clause_break then
				Result := base_ms (a_wpm)
			end
		ensure
			non_negative: Result >= 0
			plain_flows: (not a_token.ends_sentence and not a_token.has_clause_break
				and not a_token.ends_paragraph) implies Result = 0
			paragraph_longest: a_token.ends_paragraph implies Result = 3 * base_ms (a_wpm)
		end

feature -- Constants

	Foreign_ceiling_wpm: INTEGER = 350
			-- A foreign-script word displays as if the dial read at most this.

feature {NONE} -- Implementation

	length_multiplier (a_count: INTEGER): REAL_64
			-- Graduated bands: 1-5 x1.0, 6-8 x1.1, 9-11 x1.3, 12+ x1.5.
		require
			positive: a_count >= 1
		do
			if a_count <= 5 then
				Result := 1.0
			elseif a_count <= 8 then
				Result := 1.1
			elseif a_count <= 11 then
				Result := 1.3
			else
				Result := 1.5
			end
		ensure
			at_least_one: Result >= 1.0
		end

end
