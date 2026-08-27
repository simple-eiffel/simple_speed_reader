note
	description: "One work the reader chose: title and its token stream."
	author: "Larry Rix"

class
	SR_TEXT

create
	make

feature {NONE} -- Initialization

	make (a_title: READABLE_STRING_GENERAL; a_tokens: ARRAYED_LIST [SR_TOKEN])
		require
			title_present: not a_title.is_empty
			some_tokens: not a_tokens.is_empty
		do
			create title.make_from_string_general (a_title)
			tokens := a_tokens
		ensure
			title_kept: title.same_string_general (a_title)
			tokens_kept: tokens = a_tokens
		end

feature -- Access

	title: STRING_32

	tokens: ARRAYED_LIST [SR_TOKEN]

	token_count: INTEGER
		do
			Result := tokens.count
		ensure
			positive: Result >= 1
		end

	section_count: INTEGER
			-- How many heading-bounded sections the tokenizer found.
		do
			Result := tokens.last.section_index
		ensure
			positive: Result >= 1
		end

	has_sections: BOOLEAN
			-- Real internal structure (>= 2 sections) - the section
			-- navigation buttons enable on this.
		do
			Result := section_count >= 2
		end

	token (a_index: INTEGER): SR_TOKEN
		require
			in_text: a_index >= 1 and a_index <= token_count
		do
			Result := tokens.i_th (a_index)
		end

invariant
	titled: not title.is_empty
	never_empty: not tokens.is_empty

end
