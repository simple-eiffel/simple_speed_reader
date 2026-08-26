note
	description: "[
		The headless AI worker - spawned by the GUI so the pump never
		waits on a model (the ocr_capture pattern; the curl call in
		OLLAMA_CLIENT is synchronous by nature).

		  --quiz <in.txt> <out.json> <url> <model> <count>

		Reads UTF-8 text, asks the local model for `count' questions as
		STRICT JSON [{"q","a","quote"}], writes the payload (or
		{"error": ...}) UTF-8 to <out.json>. Exit is always orderly:
		the GUI learns everything from the file.
	]"
	author: "Larry Rix"

class
	SR_WORKER

create
	make

feature {NONE} -- Initialization

	make
		local
			l_args: ARGUMENTS_32
		do
			create l_args
			if l_args.argument_count >= 6 and then l_args.argument (1).same_string_general ("--quiz") then
				run_quiz (l_args.argument (2).to_string_32, l_args.argument (3).to_string_32,
					l_args.argument (4).to_string_32, l_args.argument (5).to_string_32,
					l_args.argument (6).to_integer_32.max (1).min (12))
			else
				io.put_string ("usage: --quiz <in.txt> <out.json> <url> <model> <count>%N")
			end
		end

feature {NONE} -- The one job

	run_quiz (a_in, a_out, a_url, a_model: STRING_32; a_count: INTEGER)
		local
			l_text, l_payload: STRING_32
			l_client: OLLAMA_CLIENT
			l_response: AI_RESPONSE
		do
			l_text := read_utf8 (a_in)
			if l_text.is_empty then
				write_utf8 (a_out, {STRING_32} "{%"error%": %"worker could not read the text%"}")
			else
				create l_client.make_with_base_url (a_url)
				l_client.set_model (a_model)
				l_response := l_client.ask_with_system (system_prompt (a_count), user_prompt (l_text))
				if l_response.is_success then
					l_payload := extract_json_array (l_response.text)
					if l_payload.is_empty then
						write_utf8 (a_out, {STRING_32} "{%"error%": %"model reply held no JSON array%"}")
					else
						write_utf8 (a_out, l_payload)
					end
				else
					write_utf8 (a_out, {STRING_32} "{%"error%": %"" +
						escaped (if attached l_response.error_message as al_e then al_e
							else {STRING_32} "model call failed" end) + {STRING_32} "%"}")
				end
			end
		end

	system_prompt (a_count: INTEGER): STRING_32
		do
			create Result.make (512)
			Result.append_string_general ("You write reading-comprehension quizzes. Reply with ONLY a JSON array, no prose, no code fences: [{%"q%": question, %"a%": short expected answer, %"quote%": a VERBATIM quote from the passage that proves the answer}]. Exactly ")
			Result.append_string_general (a_count.out)
			Result.append_string_general (" items. Every quote MUST be copied character-for-character from the passage - never paraphrase a quote.")
		end

	user_prompt (a_text: STRING_32): STRING_32
		do
			create Result.make (a_text.count + 64)
			Result.append_string_general ("The passage:%N%N")
			Result.append (a_text)
		end

feature {NONE} -- Plumbing

	Max_passage_chars: INTEGER = 9000
			-- A local model's honest context share (num_ctx truncation
			-- is silent - cap ourselves and say so in the design).

	read_utf8 (a_path: STRING_32): STRING_32
			-- Whole file, UTF-8 decoded, BOM stripped, capped at
			-- Max_passage_chars on a word boundary.
		local
			l_f: RAW_FILE
			l_raw: STRING_8
			l_enc: SIMPLE_ENCODING
			i: INTEGER
		do
			create Result.make_empty
			create l_f.make_with_name (a_path)
			if l_f.exists and then l_f.is_readable then
				l_f.open_read
				create l_raw.make (l_f.count)
				l_f.read_stream (l_f.count)
				l_raw.append (l_f.last_string)
				l_f.close
				create l_enc.make
				Result := l_enc.utf_8_to_utf_32 (l_raw)
				if not Result.is_empty and then Result.item (1).natural_32_code = 0xFEFF then
					Result.remove_head (1)
				end
				if Result.count > Max_passage_chars then
					i := Max_passage_chars
					from
					until
						i <= 1 or else Result.item (i).natural_32_code = 32
							or else Result.item (i).natural_32_code = 10
					loop
						i := i - 1
					end
					Result.keep_head (i.max (1))
				end
			end
		end

	write_utf8 (a_path: STRING_32; a_content: STRING_32)
			-- Write to a .tmp sibling, then rename into place: the
			-- polling GUI must never read a half-written payload.
		local
			l_f: RAW_FILE
			l_enc: SIMPLE_ENCODING
		do
			create l_enc.make
			create l_f.make_create_read_write (a_path + {STRING_32} ".tmp")
			l_f.put_string (l_enc.utf_32_to_utf_8 (a_content))
			l_f.close
			l_f.rename_file (a_path)
		end

	extract_json_array (a_reply: STRING_32): STRING_32
			-- The [ ... ] slab inside a reply that may carry think
			-- blocks (Qwen3), code fences, or prose. Thinking is cut
			-- first; then the outermost array brackets.
		local
			l_clean: STRING_32
			l_lo, l_hi, l_ts, l_te: INTEGER
		do
			create Result.make_empty
			l_clean := a_reply.twin
			from
				l_ts := l_clean.substring_index ({STRING_32} "<think>", 1)
			until
				l_ts = 0
			loop
				l_te := l_clean.substring_index ({STRING_32} "</think>", l_ts)
				if l_te > 0 then
					l_clean.remove_substring (l_ts, l_te + 7)
				else
					l_clean.keep_head (l_ts - 1)
				end
				l_ts := l_clean.substring_index ({STRING_32} "<think>", 1)
			end
			l_lo := l_clean.index_of ({CHARACTER_32} '[', 1)
			l_hi := l_clean.last_index_of ({CHARACTER_32} ']', l_clean.count)
			if l_lo > 0 and then l_hi > l_lo then
				Result := l_clean.substring (l_lo, l_hi)
			end
		end

	escaped (a_s: STRING_32): STRING_32
			-- `a_s' safe inside a JSON string literal.
		local
			i, l_code: INTEGER
		do
			create Result.make (a_s.count)
			from
				i := 1
			until
				i > a_s.count
			loop
				l_code := a_s.item (i).natural_32_code.to_integer_32
				if l_code = 34 or l_code = 92 then
					Result.append_code (92)
					Result.append_character (a_s.item (i))
				elseif l_code = 10 or l_code = 13 or l_code = 9 then
					Result.append_character (' ')
				else
					Result.append_character (a_s.item (i))
				end
				i := i + 1
			end
		end

end
