note
	description: "[
		Clean text in, the token stream out: words split on whitespace,
		paragraph breaks on blank lines, sentence and clause flags from
		trailing punctuation. The single place structure is decided.
	]"
	author: "Larry Rix"

class
	SR_TOKENIZER

feature -- Queries

	is_blank (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Nothing but whitespace?
		local
			i, l_code: INTEGER
		do
			Result := True
			from
				i := 1
			until
				i > a_text.count or not Result
			loop
				l_code := a_text.item (i).natural_32_code.to_integer_32
				if l_code /= 32 and l_code /= 9 and l_code /= 10 and l_code /= 13 then
					Result := False
				end
				i := i + 1
			end
		end

feature -- Operations

	tokenize (a_clean: READABLE_STRING_GENERAL): ARRAYED_LIST [SR_TOKEN]
			-- The stream, with sentence/paragraph structure.
		require
			has_substance: not is_blank (a_clean)
		local
			l_words: ARRAYED_LIST [TUPLE [w: STRING_32; start: INTEGER; par_after: BOOLEAN]]
			l_buf: STRING_32
			i, l_code, l_start, l_newlines, l_sent, l_par: INTEGER
			l_last: TUPLE [w: STRING_32; start: INTEGER; par_after: BOOLEAN]
			l_ends_s, l_ends_p, l_clause: BOOLEAN
		do
			create l_words.make (a_clean.count // 6 + 8)
			create l_buf.make (24)
			l_start := 1
				-- Pass 1: split on whitespace, marking paragraph gaps.
			from
				i := 1
			until
				i > a_clean.count
			loop
				l_code := a_clean.item (i).natural_32_code.to_integer_32
				if l_code = 32 or l_code = 9 or l_code = 10 or l_code = 13 then
					if not l_buf.is_empty then
						l_words.extend ([l_buf.twin, l_start, False])
						l_buf.wipe_out
					end
					if l_code = 10 then
						l_newlines := l_newlines + 1
						if l_newlines >= 2 and l_words.count > 0 then
							l_last := l_words.last
							l_last.par_after := True
						end
					end
				else
					if l_buf.is_empty then
						l_start := i
						l_newlines := 0
					end
					l_buf.append_character (a_clean.item (i))
				end
				i := i + 1
			end
			if not l_buf.is_empty then
				l_words.extend ([l_buf.twin, l_start, False])
			end
				-- Pass 2: flags and structural indexes.
			create Result.make (l_words.count)
			l_sent := 1
			l_par := 1
			from
				i := 1
			until
				i > l_words.count
			loop
				l_ends_p := l_words.i_th (i).par_after or i = l_words.count
				l_ends_s := l_ends_p or ends_sentence_word (l_words.i_th (i).w)
				l_clause := (not l_ends_s) and has_clause_tail (l_words.i_th (i).w)
				Result.extend (create {SR_TOKEN}.make (
					l_words.i_th (i).w, l_sent, l_par, l_words.i_th (i).start,
					l_ends_s, l_ends_p, l_clause))
				if l_ends_s then
					l_sent := l_sent + 1
				end
				if l_ends_p then
					l_par := l_par + 1
				end
				i := i + 1
			end
		ensure
			some_tokens: not Result.is_empty
			last_closes: Result.last.ends_sentence
			sentences_monotone: across 2 |..| Result.count as ic all
				Result.i_th (ic).sentence_index >= Result.i_th (ic - 1).sentence_index end
			paragraphs_monotone: across 2 |..| Result.count as ic all
				Result.i_th (ic).paragraph_index >= Result.i_th (ic - 1).paragraph_index end
		end

feature {NONE} -- Implementation

	ends_sentence_word (a_w: STRING_32): BOOLEAN
			-- Ends in . ! ? or their Unicode kin, closing quotes allowed after.
		local
			l_code: INTEGER
		do
			l_code := last_marking_code (a_w)
			Result := l_code = 46 or l_code = 33 or l_code = 63
				or l_code = 0x2026 -- horizontal ellipsis
		end

	has_clause_tail (a_w: STRING_32): BOOLEAN
			-- Ends in , ; : or a dash, closing quotes allowed after.
		local
			l_code: INTEGER
		do
			l_code := last_marking_code (a_w)
			Result := l_code = 44 or l_code = 59 or l_code = 58
				or l_code = 0x2014 or l_code = 0x2013 -- em, en dash
		end

	last_marking_code (a_w: STRING_32): INTEGER
			-- Code of the last character once closing quotes/brackets are skipped.
			-- 0 for a word of nothing but closers.
		local
			i, l_code: INTEGER
			l_closer: BOOLEAN
		do
			from
				i := a_w.count
				l_closer := True
			until
				i < 1 or not l_closer
			loop
				l_code := a_w.item (i).natural_32_code.to_integer_32
				l_closer := l_code = 34 or l_code = 39 -- " '
					or l_code = 41 or l_code = 93 or l_code = 125 -- ) ] }
					or l_code = 0x201D or l_code = 0x2019 -- ” ’
					or l_code = 0x00BB -- »
				if l_closer then
					i := i - 1
				end
			end
			if i >= 1 then
				Result := a_w.item (i).natural_32_code.to_integer_32
			end
		end

end
