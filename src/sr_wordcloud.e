note
	description: "[
		Word significance for one text: frequency ranks over content
		words (stopwords out - modern and KJV function words alike),
		serving two faces: per-token color TIERS for the fisheye
		ribbon, and scoped TOP-WORD lists (document / section /
		paragraph) for the pause-time cloud.
	]"
	author: "Larry Rix"

class
	SR_WORDCLOUD

create
	make

feature {NONE} -- Initialization

	make (a_tokens: ARRAYED_LIST [SR_TOKEN])
			-- One frequency pass over the whole text; document tiers fixed.
		require
			some_tokens: not a_tokens.is_empty
		local
			i: INTEGER
			l_key: STRING_32
		do
			tokens := a_tokens
			create counts.make (a_tokens.count // 4 + 8)
			from
				i := 1
			until
				i > a_tokens.count
			loop
				l_key := content_key (a_tokens.i_th (i).word)
				if not l_key.is_empty then
					counts.force (counts.item (l_key) + 1, l_key)
				end
				i := i + 1
			end
			compute_tiers
		ensure
			tokens_kept: tokens = a_tokens
		end

feature -- Access

	tier_of (a_word: READABLE_STRING_32): INTEGER
			-- 0 = function word / unranked; 1 (common) .. 5 (hottest).
		local
			l_key: STRING_32
			l_count: INTEGER
		do
			l_key := content_key (a_word)
			if not l_key.is_empty then
				l_count := counts.item (l_key)
				if l_count >= tier_floor_5 then
					Result := 5
				elseif l_count >= tier_floor_4 then
					Result := 4
				elseif l_count >= tier_floor_3 then
					Result := 3
				elseif l_count >= 2 then
					Result := 2
				elseif l_count = 1 then
					Result := 1
				end
			end
		ensure
			tiered: Result >= 0 and Result <= 5
		end

	top_words (a_from, a_to, a_limit: INTEGER): ARRAYED_LIST [TUPLE [word: STRING_32; tally: INTEGER]]
			-- The most frequent content words inside tokens [a_from, a_to],
			-- descending, at most `a_limit'.
		require
			ordered: a_from >= 1 and a_from <= a_to and a_to <= tokens.count
			positive: a_limit >= 1
		local
			l_local: HASH_TABLE [INTEGER, STRING_32]
			i, j: INTEGER
			l_key: STRING_32
			l_entry: TUPLE [word: STRING_32; tally: INTEGER]
		do
			create l_local.make ((a_to - a_from) // 4 + 8)
			from
				i := a_from
			until
				i > a_to
			loop
				l_key := content_key (tokens.i_th (i).word)
				if not l_key.is_empty then
					l_local.force (l_local.item (l_key) + 1, l_key)
				end
				i := i + 1
			end
			create Result.make (a_limit)
			from
				l_local.start
			until
				l_local.after
			loop
				l_entry := [l_local.key_for_iteration.twin, l_local.item_for_iteration]
					-- insertion into a size-capped, sorted-descending list
				from
					j := 1
				until
					j > Result.count or else Result.i_th (j).tally < l_entry.tally
				loop
					j := j + 1
				end
				if j <= a_limit then
					if j > Result.count then
						Result.extend (l_entry)
					else
						Result.go_i_th (j)
						Result.put_left (l_entry)
					end
					if Result.count > a_limit then
						Result.finish
						Result.remove
					end
				end
				l_local.forth
			end
		ensure
			bounded: Result.count <= a_limit
			descending: across 2 |..| Result.count as ic all
				Result.i_th (ic).tally <= Result.i_th (ic - 1).tally end
		end

	content_key (a_word: READABLE_STRING_32): STRING_32
			-- The countable core of a word: lowercased, punctuation
			-- trimmed both ends, markdown marks stripped; empty when
			-- the word is a stopword, a number, or too short to mean.
		local
			i, j, l_code: INTEGER
		do
			create Result.make (a_word.count)
			from
				i := 1
			until
				i > a_word.count or else is_letterish (a_word.item (i).natural_32_code.to_integer_32)
			loop
				i := i + 1
			end
			from
				j := a_word.count
			until
				j < i or else is_letterish (a_word.item (j).natural_32_code.to_integer_32)
			loop
				j := j - 1
			end
			if j >= i then
				Result := a_word.substring (i, j).as_lower
			end
			if Result.count < 3 then
				Result.wipe_out
			elseif stopwords.has (Result.to_string_8) then
				Result.wipe_out
			else
				l_code := Result.item (1).natural_32_code.to_integer_32
				if l_code >= 48 and l_code <= 57 then
					Result.wipe_out -- verse refs and figures are not themes
				end
			end
		end

feature -- Access

	tokens: ARRAYED_LIST [SR_TOKEN]
			-- The text these ranks weigh (precondition vocabulary).

feature {NONE} -- Implementation

	counts: HASH_TABLE [INTEGER, STRING_32]

	tier_floor_3, tier_floor_4, tier_floor_5: INTEGER

	compute_tiers
			-- Tier floors from the observed peak: 5 = top fifth of the
			-- max count, 4 = top two-fifths, 3 = above a tenth (min 3).
		local
			l_max: INTEGER
		do
			from
				counts.start
			until
				counts.after
			loop
				l_max := l_max.max (counts.item_for_iteration)
				counts.forth
			end
			tier_floor_5 := (l_max * 3 // 5).max (4)
			tier_floor_4 := (l_max * 2 // 5).max (3)
			tier_floor_3 := (l_max // 10).max (3)
		end

	is_letterish (a_code: INTEGER): BOOLEAN
			-- A character worth keeping at a word's edge (letters of
			-- any script, digits, internal marks stay via trimming-only).
		do
			Result := (a_code >= 48 and a_code <= 57)
				or (a_code >= 65 and a_code <= 90)
				or (a_code >= 97 and a_code <= 122)
				or a_code >= 0x00C0
		end

	stopwords: HASH_TABLE [BOOLEAN, STRING_8]
			-- Modern English function words plus the KJV register.
		once
			create Result.make (160)
			across (<<
				"the", "and", "for", "that", "with", "this", "was", "his", "are",
				"but", "not", "you", "all", "they", "she", "her", "him", "have",
				"had", "has", "from", "one", "were", "which", "there", "their",
				"been", "when", "who", "will", "more", "out", "said", "what",
				"its", "about", "into", "than", "them", "can", "only", "other",
				"some", "could", "then", "these", "two", "may", "first", "any",
				"now", "such", "like", "our", "over", "man", "even", "most",
				"made", "after", "also", "did", "many", "before", "must",
				"through", "would", "should", "your", "because", "where", "how",
				"very", "just", "too", "own", "same", "each", "why", "does",
				"unto", "thee", "thou", "thy", "thine", "hath", "shall", "yea",
				"saith", "doth", "art", "wilt", "hast", "let", "upon", "came",
				"come", "went", "unto", "them", "him", "yet", "till", "among"
			>>) as w
			loop
				Result.force (True, w)
			end
		end

end
