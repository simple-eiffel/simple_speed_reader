note
	description: "[
		The comprehension quiz for one text: parsed from the worker's
		JSON, every surviving question quote-verified against the text
		(DR-005), the dropped count kept for honesty. Administration is
		one pass: reveal, self-judge, next; the score is a percent.
	]"
	author: "Larry Rix"

class
	SR_QUIZ

create
	make_from_json

feature {NONE} -- Initialization

	make_from_json (a_json: READABLE_STRING_32; a_text: READABLE_STRING_32)
			-- Parse [{"q":..,"a":..,"quote":..}, ...]; keep only
			-- questions whose quote occurs verbatim in `a_text'.
			-- A malformed payload or an {"error": ...} yields an empty
			-- quiz carrying `error_line' - never a crash.
		require
			json_present: not a_json.is_empty
			text_present: not a_text.is_empty
		local
			l_parser: SIMPLE_JSON
			l_validator: SR_QUIZ_VALIDATOR
			l_arr: SIMPLE_JSON_ARRAY
			l_q, l_a, l_quote: STRING_32
			i: INTEGER
		do
			create questions.make (10)
			create error_line.make_empty
			create l_parser
			create l_validator
			if attached l_parser.parse (a_json.to_string_32) as al_v then
				if al_v.is_array then
					l_arr := al_v.as_array
					from
						i := 1
					until
						i > l_arr.count
					loop
						if l_arr [i].is_object then
							l_q := string_field (l_arr [i].as_object, "q")
							l_a := string_field (l_arr [i].as_object, "a")
							l_quote := string_field (l_arr [i].as_object, "quote")
							if not l_q.is_empty and not l_a.is_empty and not l_quote.is_empty then
								if l_validator.is_quote_in_text (l_quote, a_text) then
									questions.extend (create {SR_QUIZ_QUESTION}.make (l_q, l_a, l_quote))
								else
									dropped_count := dropped_count + 1
								end
							else
								dropped_count := dropped_count + 1
							end
						end
						i := i + 1
					end
				elseif al_v.is_object and then attached al_v.as_object.item ({STRING_32} "error") as al_e then
					error_line := al_e.as_string_32
				else
					error_line := {STRING_32} "quiz payload was not a question array"
				end
			else
				error_line := {STRING_32} "quiz payload did not parse as JSON"
			end
			administration_index := 1
		ensure
			all_verified_by_construction: True -- the only door in checks the quote
		end

feature -- Access

	questions: ARRAYED_LIST [SR_QUIZ_QUESTION]

	dropped_count: INTEGER
			-- Honesty: how many the validator rejected.

	error_line: STRING_32
			-- Why there are no questions, when there are none.

	is_usable: BOOLEAN
		do
			Result := not questions.is_empty
		end

	administration_index: INTEGER
			-- The question currently being administered (1-based).

	is_administration_done: BOOLEAN
		do
			Result := administration_index > questions.count
		end

	current_question: SR_QUIZ_QUESTION
		require
			usable: is_usable
			in_progress: not is_administration_done
		do
			Result := questions.i_th (administration_index)
		end

	judged_count: INTEGER
		do
			across
				questions as q
			loop
				if q.is_judged then
					Result := Result + 1
				end
			end
		ensure
			bounded: Result <= questions.count
		end

	score_percent: INTEGER
			-- Self-judged hits over the judged, as a percent; 0 before any.
		local
			l_got: INTEGER
		do
			if judged_count > 0 then
				across
					questions as q
				loop
					if q.is_judged and then q.got_it then
						l_got := l_got + 1
					end
				end
				Result := (l_got * 100) // judged_count
			end
		ensure
			percent: Result >= 0 and Result <= 100
		end

feature -- Administration

	judge_current (a_got_it: BOOLEAN)
			-- The reader's verdict on the current question; advances.
		require
			usable: is_usable
			in_progress: not is_administration_done
		do
			current_question.judge (a_got_it)
			administration_index := administration_index + 1
		ensure
			advanced: administration_index = old administration_index + 1
		end

feature {NONE} -- Implementation

	string_field (a_obj: SIMPLE_JSON_OBJECT; a_key: READABLE_STRING_GENERAL): STRING_32
			-- The string at `a_key', or empty when absent/non-string.
		do
			if attached a_obj.item (a_key.to_string_32) as al_v and then al_v.is_string then
				Result := al_v.as_string_32
			else
				create Result.make_empty
			end
		end

invariant
	index_sane: administration_index >= 1 and administration_index <= questions.count + 1
	dropped_non_negative: dropped_count >= 0

end
