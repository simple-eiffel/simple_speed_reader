note
	description: "[
		The RSVP frame: one word on near-black, the ORP letter red and
		pinned at fixed X with tick marks, the dim WPM readout below.
		Foreign-script tokens render centered, whole-word, no pivot.
		Blank during breathers - the video's dark frames.
	]"
	author: "Larry Rix"

class
	SR_STAGE_VIEW

create
	make

feature {NONE} -- Initialization

	make (a_reader: SIMPLE_SPEED_READER)
		do
			reader := a_reader
			font_size := 64.0
			create surface.make (400.0)
			surface.set_grow (1.0)
			surface.set_on_paint (agent paint)
			is_in_breather := False
		ensure
			reader_kept: reader = a_reader
		end

feature -- Access

	surface: SR_SURFACE

	font_size: REAL_64

	is_in_breather: BOOLEAN
			-- Fed each tick by the app; True blanks the word.

feature -- Element change

	set_breather (a_on: BOOLEAN)
		do
			is_in_breather := a_on
		ensure
			set: is_in_breather = a_on
		end

	set_font_size (a_size: REAL_64)
		require
			readable: a_size >= 16.0 and a_size <= 160.0
		do
			font_size := a_size
		ensure
			set: font_size = a_size
		end

feature {NONE} -- Painting

	reader: SIMPLE_SPEED_READER

	paint (p: SW_PAINTER; a_x, a_y, a_w, a_h: REAL_64)
		local
			l_pin, l_base, l_pre_w, l_piv_w, l_all_w: REAL_64
			l_word: STRING_32
			l_tok: SR_TOKEN
			l_s: STRING_32
		do
			p.set_color (Stage_black)
			p.fill_rect (a_x, a_y, a_w, a_h)
			l_pin := a_x + a_w * 0.5
			l_base := a_y + a_h * 0.46
			if reader.has_text and then reader.position >= 1 then
				l_tok := reader.current_token
				p.font (p.Role_mono, font_size, True)
				if not is_in_breather then
					l_word := l_tok.word
					if l_tok.is_latin then
						l_pre_w := p.advance (l_word.substring (1, l_tok.pivot_index - 1))
						l_piv_w := p.advance (l_word.substring (l_tok.pivot_index, l_tok.pivot_index))
						p.set_color (Ink)
						p.text (l_pin - l_pre_w - l_piv_w / 2, l_base,
							l_word.substring (1, l_tok.pivot_index - 1))
						p.set_color (Accent_red)
						p.text (l_pin - l_piv_w / 2, l_base,
							l_word.substring (l_tok.pivot_index, l_tok.pivot_index))
						p.set_color (Ink)
						p.text (l_pin + l_piv_w / 2, l_base,
							l_word.substring (l_tok.pivot_index + 1, l_word.count))
					else
						l_all_w := p.advance (l_word)
						p.set_color (Ink)
						p.text (l_pin - l_all_w / 2, l_base, l_word)
					end
				end
				if l_tok.is_latin then
					p.set_color (Accent_red)
					p.fill_rect (l_pin - 1.5, l_base - font_size - 20.0, 3.0, 16.0)
					p.fill_rect (l_pin - 1.5, l_base + 14.0, 3.0, 16.0)
				end
				p.font (p.Role_mono, 13.0, True)
				p.set_color (Dim)
				create l_s.make (24)
				l_s.append_string_general ("SPEED: ")
				l_s.append_string_general (reader.current_wpm.out)
				l_s.append_string_general (" WPM")
				if reader.is_held then
					l_s.append_string_general ("  [HELD]")
				end
				p.text (a_x + (a_w - p.advance (l_s)) / 2, a_y + a_h - 26.0, l_s)
			else
				p.font (p.Role_mono, 18.0, False)
				p.set_color (Dim)
				l_s := {STRING_32} "no text - Esc to the cockpit"
				p.text (a_x + (a_w - p.advance (l_s)) / 2, l_base, l_s)
			end
		end

feature {NONE} -- Palette (the video's)

	Stage_black: NATURAL_32 = 0x0D0D0F
	Ink: NATURAL_32 = 0xE8E8EA
	Accent_red: NATURAL_32 = 0xE5484D
	Dim: NATURAL_32 = 0x8A8A90

end
