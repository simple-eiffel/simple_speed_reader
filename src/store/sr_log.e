note
	description: "[
		The honest ledger: every sealed sitting as one SQLite row -
		dialed vs achieved vs retained, pauses and rewinds included.
		Titles stored as UTF-8 (SIMPLE_SQL_ROW.string_value decodes).
	]"
	author: "Larry Rix"

class
	SR_LOG

create
	make

feature {NONE} -- Initialization

	make (a_db_path: READABLE_STRING_GENERAL)
		require
			path_present: not a_db_path.is_empty
		do
			create db.make (a_db_path)
			db.execute ("[
				CREATE TABLE IF NOT EXISTS runs (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
					title TEXT NOT NULL,
					streamed INTEGER NOT NULL,
					skipped INTEGER NOT NULL,
					pauses INTEGER NOT NULL,
					rewinds INTEGER NOT NULL,
					max_wpm INTEGER NOT NULL,
					effective_wpm INTEGER NOT NULL,
					quiz_score INTEGER NOT NULL DEFAULT -1
				)
			]")
		end

feature -- Access

	run_count: INTEGER
		local
			l_r: SIMPLE_SQL_RESULT
		do
			l_r := db.query ("SELECT COUNT(*) AS c FROM runs")
			if not l_r.is_empty then
				Result := l_r [1].integer_value ("c")
			end
		ensure
			non_negative: Result >= 0
		end

	recent_lines (a_limit: INTEGER): ARRAYED_LIST [STRING_32]
			-- The newest runs, one cockpit-ready line each.
		require
			positive: a_limit >= 1
		local
			l_r: SIMPLE_SQL_RESULT
			l_line: STRING_32
			l_score: INTEGER
		do
			create Result.make (a_limit)
			l_r := db.query_with_args (
				"SELECT at, title, streamed, max_wpm, effective_wpm, quiz_score FROM runs ORDER BY id DESC LIMIT ?",
				<<a_limit>>)
			across
				l_r.rows as r
			loop
				create l_line.make (96)
				l_line.append (r.string_value ("at"))
				l_line.append_string_general ("  ")
				l_line.append (r.string_value ("title"))
				l_line.append_string_general (" - ")
				l_line.append_string_general (r.integer_value ("streamed").out)
				l_line.append_string_general (" words, peak ")
				l_line.append_string_general (r.integer_value ("max_wpm").out)
				l_line.append_string_general (", effective ")
				l_line.append_string_general (r.integer_value ("effective_wpm").out)
				l_score := r.integer_value ("quiz_score")
				if l_score >= 0 then
					l_line.append_string_general (", quiz ")
					l_line.append_string_general (l_score.out)
					l_line.append_string_general ("%%")
				end
				Result.extend (l_line)
			end
		ensure
			bounded: Result.count <= a_limit
		end

feature -- Element change

	record_run (a_record: SR_RUN_RECORD; a_quiz_score: INTEGER)
			-- One sealed sitting into the ledger; `a_quiz_score' -1 = untested.
		require
			score_lawful: a_quiz_score >= -1 and a_quiz_score <= 100
		local
			l_enc: SIMPLE_ENCODING
		do
			create l_enc.make
			db.execute_with_args ("[
				INSERT INTO runs (title, streamed, skipped, pauses, rewinds, max_wpm, effective_wpm, quiz_score)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?)
			]", <<l_enc.utf_32_to_utf_8 (a_record.title),
				a_record.streamed_count, a_record.skipped_count,
				a_record.pause_count, a_record.rewind_count,
				a_record.nominal_max_wpm, a_record.effective_wpm, a_quiz_score>>)
		ensure
			grown: run_count = old run_count + 1
		end

	close
		do
			db.close
		end

feature {NONE} -- Implementation

	db: SIMPLE_SQL_DATABASE

end
