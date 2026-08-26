note
	description: "[
		One streamable word: text, ORP pivot, structure flags, and the
		linger classification the timing model prices. Immutable value.
		The ORP law (pivot_for_length) lives here and nowhere else.
	]"
	author: "Larry Rix"

class
	SR_TOKEN

create
	make

feature {NONE} -- Initialization

	make (a_word: READABLE_STRING_GENERAL; a_sentence, a_paragraph, a_source_start: INTEGER;
			a_ends_sentence, a_ends_paragraph, a_has_clause_break: BOOLEAN)
			-- One tokenized word with its place in the text's structure.
		require
			word_not_empty: not a_word.is_empty
			positive_sentence: a_sentence >= 1
			positive_paragraph: a_paragraph >= 1
			positive_source: a_source_start >= 1
			paragraph_closes_sentence: a_ends_paragraph implies a_ends_sentence
		do
			create word.make_from_string_general (a_word)
			sentence_index := a_sentence
			paragraph_index := a_paragraph
			source_start := a_source_start
			ends_sentence := a_ends_sentence
			ends_paragraph := a_ends_paragraph
			has_clause_break := a_has_clause_break
			classify
			pivot_index := settled_pivot
		ensure
			word_kept: word.same_string_general (a_word)
			sentence_kept: sentence_index = a_sentence
			paragraph_kept: paragraph_index = a_paragraph
		end

feature -- Access

	word: STRING_32

	pivot_index: INTEGER
			-- ORP: the letter pinned (red) at the stage's fixed X.
			-- Meaningful for Latin script only; combining-mark-avoiding.

	sentence_index, paragraph_index, source_start: INTEGER

	ends_sentence, ends_paragraph, has_clause_break: BOOLEAN

feature -- Classification (D-011/D-013)

	script: INTEGER
			-- One of the Script_* constants, from Unicode blocks.

	has_diacritics: BOOLEAN
			-- Latin with extended-Latin diacritics (agape-macron, hesed-dot)?

	is_numeric: BOOLEAN
			-- Contains a digit (1,234 - Gen 1:3 - H7225)?

	is_acronym: BOOLEAN
			-- Two or more ASCII capitals, no lowercase (LXX, MT, YHWH)?

	is_latin: BOOLEAN
		do
			Result := script = Script_latin
		end

	is_foreign_script: BOOLEAN
		do
			Result := script /= Script_latin
		end

	streams_under_filter (a_skip_foreign: BOOLEAN): BOOLEAN
			-- D-013: the foreign-skip filter keeps Latin (transliterations included).
		do
			Result := is_latin or not a_skip_foreign
		ensure
			latin_always: is_latin implies Result
		end

feature -- Script constants

	Script_latin: INTEGER = 1
	Script_hebrew: INTEGER = 2
	Script_greek: INTEGER = 3
	Script_other: INTEGER = 4

feature -- The ORP law (Single Choice: the only place this rule exists)

	pivot_for_length (a_count: INTEGER): INTEGER
			-- Spritz-convention pivot, verified against the source video:
			-- 1 -> 1, 2-5 -> 2, 6-9 -> 3, 10-13 -> 4, 14+ -> 5.
		require
			positive: a_count >= 1
		do
			if a_count = 1 then
				Result := 1
			elseif a_count <= 5 then
				Result := 2
			elseif a_count <= 9 then
				Result := 3
			elseif a_count <= 13 then
				Result := 4
			else
				Result := 5
			end
		ensure
			inside: Result >= 1 and Result <= a_count
		end

feature {NONE} -- Implementation

	classify
			-- Scan the word once; set script and linger flags.
		local
			i, l_code, l_upper: INTEGER
			l_heb, l_grk, l_other, l_dia, l_num, l_lower: BOOLEAN
		do
			from
				i := 1
			until
				i > word.count
			loop
				l_code := word.item (i).natural_32_code.to_integer_32
				if l_code >= 0x0590 and l_code <= 0x05FF then
					l_heb := True
				elseif (l_code >= 0x0370 and l_code <= 0x03FF)
					or (l_code >= 0x1F00 and l_code <= 0x1FFF)
				then
					l_grk := True
				elseif l_code >= 0x0400 and l_code < 0x1E00
					and not (l_code >= 0x1D00 and l_code <= 0x1DBF)
				then
						-- Cyrillic, Armenian, Arabic, Devanagari... - not our pivots.
					l_other := True
				end
				if (l_code >= 0x00C0 and l_code <= 0x024F)
					or (l_code >= 0x1E00 and l_code <= 0x1EFF)
					or (l_code >= 0x0300 and l_code <= 0x036F)
				then
					l_dia := True
				end
				if l_code >= 48 and l_code <= 57 then
					l_num := True
				end
				if l_code >= 65 and l_code <= 90 then
					l_upper := l_upper + 1
				elseif l_code >= 97 and l_code <= 122 then
					l_lower := True
				end
				i := i + 1
			end
			if l_heb then
				script := Script_hebrew
			elseif l_grk then
				script := Script_greek
			elseif l_other then
				script := Script_other
			else
				script := Script_latin
			end
			has_diacritics := script = Script_latin and l_dia
			is_numeric := l_num
			is_acronym := l_upper >= 2 and not l_lower
		ensure
			script_known: script >= Script_latin and script <= Script_other
		end

	settled_pivot: INTEGER
			-- pivot_for_length, stepped left off combining marks (niqqud
			-- must never be the red letter). Best-effort: a pathological
			-- all-combining word pivots at 1.
		do
			Result := pivot_for_length (word.count)
			from
			until
				Result <= 1 or else not is_combining_code (word.item (Result).natural_32_code.to_integer_32)
			loop
				Result := Result - 1
			end
		ensure
			inside: Result >= 1 and Result <= word.count
		end

	is_combining_code (a_code: INTEGER): BOOLEAN
			-- Combining diacritical marks (general, Hebrew points/accents, supplement).
		do
			Result := (a_code >= 0x0300 and a_code <= 0x036F)
				or (a_code >= 0x0591 and a_code <= 0x05C7)
				or (a_code >= 0x1DC0 and a_code <= 0x1DFF)
		end

invariant
	word_present: not word.is_empty
	pivot_inside: pivot_index >= 1 and pivot_index <= word.count
	paragraph_end_is_sentence_end: ends_paragraph implies ends_sentence
	script_known: script >= Script_latin and script <= Script_other
	diacritics_are_latin: has_diacritics implies is_latin

end
