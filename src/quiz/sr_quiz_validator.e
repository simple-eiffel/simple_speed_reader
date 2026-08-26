note
	description: "[
		The anti-hallucination gate (D-007/DR-005): a question survives
		only if its supporting quote occurs verbatim in the text,
		whitespace-normalized. Pure queries.
	]"
	author: "Larry Rix"

class
	SR_QUIZ_VALIDATOR

feature -- Queries

	is_quote_in_text (a_quote, a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Verbatim containment once runs of whitespace collapse to
			-- single spaces (line wraps must not defeat honesty).
		require
			quote_present: not a_quote.is_empty
			text_present: not a_text.is_empty
		do
			Result := normalized (a_text).has_substring (normalized (a_quote))
		end

	normalized (a_s: READABLE_STRING_GENERAL): STRING_32
			-- `a_s' with every whitespace run as one space, trimmed.
		local
			i, l_code: INTEGER
			l_in_gap: BOOLEAN
		do
			create Result.make (a_s.count)
			from
				i := 1
				l_in_gap := True -- leading gap swallowed
			until
				i > a_s.count
			loop
				l_code := a_s.item (i).natural_32_code.to_integer_32
				if l_code = 32 or l_code = 9 or l_code = 10 or l_code = 13 then
					if not l_in_gap then
						Result.append_character (' ')
						l_in_gap := True
					end
				else
					Result.append_character (a_s.item (i))
					l_in_gap := False
				end
				i := i + 1
			end
			Result.right_adjust
		ensure
			no_doubles: not Result.has_substring ({STRING_32} "  ")
		end

end
