note
	description: "[
		One comprehension question: prompt, expected answer, the
		verbatim supporting quote that proves it, and the reader's
		self-judged outcome (the honor system is the honest system:
		the reader sees the expected answer and marks themself).
	]"
	author: "Larry Rix"

class
	SR_QUIZ_QUESTION

create
	make

feature {NONE} -- Initialization

	make (a_prompt, a_answer, a_quote: READABLE_STRING_32)
		require
			prompt_present: not a_prompt.is_empty
			answer_present: not a_answer.is_empty
			quote_present: not a_quote.is_empty
		do
			create prompt.make_from_string_general (a_prompt)
			create expected_answer.make_from_string_general (a_answer)
			create supporting_quote.make_from_string_general (a_quote)
		ensure
			prompt_kept: prompt.same_string_general (a_prompt)
		end

feature -- Access

	prompt, expected_answer, supporting_quote: STRING_32

	is_judged: BOOLEAN

	got_it: BOOLEAN
			-- Meaningful only when `is_judged'.

feature -- Element change

	judge (a_got_it: BOOLEAN)
			-- The reader's own verdict after seeing the expected answer.
		do
			is_judged := True
			got_it := a_got_it
		ensure
			judged: is_judged
			verdict_kept: got_it = a_got_it
		end

invariant
	prompt_present: not prompt.is_empty
	quote_present: not supporting_quote.is_empty

end
