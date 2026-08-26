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
