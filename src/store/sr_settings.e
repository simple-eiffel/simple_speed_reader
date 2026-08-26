note
	description: "[
		The profile: speed anchors, filters, stage font, the AI door,
		and the resume point - a thin honest wrapper over simple_config.
		Everything has a sane default; save writes the whole profile.
	]"
	author: "Larry Rix"

class
	SR_SETTINGS

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
			-- Load the profile at `a_path' (missing file = defaults).
		require
			path_present: not a_path.is_empty
		do
			create file_path.make_from_string_general (a_path)
			create config.make_with_file (file_path.to_string_8)
			config.load
		ensure
			path_kept: file_path.same_string_general (a_path)
		end

feature -- Access (defaults per D-004/D-011)

	start_wpm: INTEGER
		do
			Result := bounded (config.integer_value ("start_wpm"), 250,
				{SR_GOVERNOR}.Min_wpm, 600)
		end

	recovery_wpm: INTEGER
		do
			Result := bounded (config.integer_value ("recovery_wpm"), 250,
				{SR_GOVERNOR}.Min_wpm, 600)
		end

	comfy_max_wpm: INTEGER
		do
			Result := bounded (config.integer_value ("comfy_max_wpm"), 900,
				200, {SR_GOVERNOR}.Max_wpm)
		end

	skip_foreign: BOOLEAN
		do
			Result := config.boolean_value ("skip_foreign")
		end

	font_size: INTEGER
		do
			Result := bounded (config.integer_value ("font_size"), 64, 16, 160)
		end

	quiz_opt_in: BOOLEAN
		do
			Result := config.boolean_value ("quiz_opt_in")
		end

	ollama_url: STRING_32
		do
			if attached config.string_value ("ollama_url") as al_s and then not al_s.is_empty then
				Result := al_s.to_string_32
			else
				Result := {STRING_32} "http://localhost:11435"
			end
		end

	ollama_model: STRING_32
		do
			if attached config.string_value ("ollama_model") as al_s and then not al_s.is_empty then
				Result := al_s.to_string_32
			else
				Result := {STRING_32} "huihui_ai/Qwen3.8-abliterated:latest"
			end
		end

	last_file_path: STRING_32
		local
			l_enc: SIMPLE_ENCODING
		do
			if attached config.string_value ("last_file_path") as al_s then
				create l_enc.make
				Result := l_enc.utf_8_to_utf_32 (al_s)
			else
				create Result.make_empty
			end
		end

	last_title: STRING_32
		local
			l_enc: SIMPLE_ENCODING
		do
			if attached config.string_value ("last_title") as al_s then
				create l_enc.make
				Result := l_enc.utf_8_to_utf_32 (al_s)
			else
				create Result.make_empty
			end
		end

	last_position: INTEGER
		do
			Result := config.integer_value ("last_position").max (0)
		end

feature -- Element change (each saves immediately - crash-honest)

	set_speeds (a_start, a_recovery, a_comfy: INTEGER)
		require
			lawful: a_start >= {SR_GOVERNOR}.Min_wpm and a_comfy <= {SR_GOVERNOR}.Max_wpm
				and a_start <= a_comfy and a_recovery <= a_comfy
		do
			config.set_integer ("start_wpm", a_start)
			config.set_integer ("recovery_wpm", a_recovery)
			config.set_integer ("comfy_max_wpm", a_comfy)
			config.save
		ensure
			kept: start_wpm = a_start and comfy_max_wpm = a_comfy
		end

	set_skip_foreign (a_on: BOOLEAN)
		do
			config.set_boolean ("skip_foreign", a_on)
			config.save
		ensure
			kept: skip_foreign = a_on
		end

	set_font_size (a_size: INTEGER)
		require
			readable: a_size >= 16 and a_size <= 160
		do
			config.set_integer ("font_size", a_size)
			config.save
		ensure
			kept: font_size = a_size
		end

	set_quiz_opt_in (a_on: BOOLEAN)
		do
			config.set_boolean ("quiz_opt_in", a_on)
			config.save
		end

	set_resume_point (a_file: READABLE_STRING_GENERAL; a_title: READABLE_STRING_GENERAL; a_position: INTEGER)
			-- Where reading stopped - the crash-safe bookmark. Paths and
			-- titles may carry any script: stored as UTF-8 bytes.
		require
			non_negative: a_position >= 0
		local
			l_enc: SIMPLE_ENCODING
		do
			create l_enc.make
			config.set_string ("last_file_path", l_enc.utf_32_to_utf_8 (a_file.to_string_32))
			config.set_string ("last_title", l_enc.utf_32_to_utf_8 (a_title.to_string_32))
			config.set_integer ("last_position", a_position)
			config.save
		ensure
			kept: last_position = a_position
		end

feature -- Access

	file_path: STRING_32

feature {NONE} -- Implementation

	config: SIMPLE_CONFIG

	bounded (a_value, a_default, a_min, a_max: INTEGER): INTEGER
			-- `a_value' clamped to [a_min, a_max]; `a_default' when unset (0).
		do
			if a_value = 0 then
				Result := a_default.max (a_min).min (a_max)
			else
				Result := a_value.max (a_min).min (a_max)
			end
		ensure
			in_range: Result >= a_min and Result <= a_max
		end

end
