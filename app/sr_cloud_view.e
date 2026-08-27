note
	description: "[
		The pause-time word cloud: the scope's top words in a wrapped
		flow, sized and warmed by rank - the text's themes at a glance
		(the ToC-before-the-book instinct, SQ3R by another door).
		Fed by the host; drawn here.
	]"
	author: "Larry Rix"

class
	SR_CLOUD_VIEW

create
	make

feature {NONE} -- Initialization

	make
		do
			create words.make (0)
			create surface.make (Cloud_height)
			surface.set_on_paint (agent paint)
		end

feature -- Access

	surface: SW_CANVAS

	words: ARRAYED_LIST [TUPLE [word: STRING_32; tally: INTEGER]]
			-- Descending by count.

feature -- Element change

	set_words (a_words: ARRAYED_LIST [TUPLE [word: STRING_32; tally: INTEGER]])
		do
			words := a_words
		ensure
			kept: words = a_words
		end

feature {NONE} -- Painting

	Cloud_height: REAL_64 = 460.0
	Margin: REAL_64 = 14.0

	paint (p: SW_PAINTER; a_x, a_y, a_w, a_h: REAL_64)
		local
			i: INTEGER
			cx, cy, l_size, l_adv, l_line_h: REAL_64
			l_entry: TUPLE [word: STRING_32; tally: INTEGER]
			l_label: STRING_32
		do
			p.set_color (Cloud_black)
			p.fill_rect (a_x, a_y, a_w, a_h)
			cx := Margin
			cy := 34.0
			l_line_h := 0.0
			from
				i := 1
			until
				i > words.count
			loop
				l_entry := words.i_th (i)
				l_size := size_for_rank (i)
				p.font (p.Role_mono, l_size, i <= 8)
				create l_label.make (l_entry.word.count + 6)
				l_label.append (l_entry.word)
				if i <= 12 then
					l_label.append_string_general (" ")
					l_label.append_string_general (l_entry.tally.out)
				end
				l_adv := p.advance (l_label)
				if cx + l_adv > a_w - Margin and cx > Margin then
					cx := Margin
					cy := cy + l_line_h + 10.0
					l_line_h := 0.0
				end
				if cy < a_h - 8.0 then
					p.set_color (color_for_rank (i))
					p.text (a_x + cx, a_y + cy, l_label)
				end
				l_line_h := l_line_h.max (l_size)
				cx := cx + l_adv + 16.0
				i := i + 1
			end
			if words.is_empty then
				p.font (p.Role_mono, 14.0, False)
				p.set_color (Dim)
				p.text (a_x + Margin, a_y + 34.0, "nothing to weigh in this scope")
			end
		end

	size_for_rank (a_rank: INTEGER): REAL_64
		require
			positive: a_rank >= 1
		do
			if a_rank <= 3 then
				Result := 36.0
			elseif a_rank <= 8 then
				Result := 27.0
			elseif a_rank <= 16 then
				Result := 21.0
			elseif a_rank <= 28 then
				Result := 16.0
			else
				Result := 13.0
			end
		ensure
			readable: Result >= 13.0
		end

	color_for_rank (a_rank: INTEGER): NATURAL_32
		require
			positive: a_rank >= 1
		do
			if a_rank <= 3 then
				Result := Accent_red
			elseif a_rank <= 8 then
				Result := Amber
			elseif a_rank <= 16 then
				Result := Ink_bright
			elseif a_rank <= 28 then
				Result := Ink_mid
			else
				Result := Dim
			end
		end

feature {NONE} -- Palette

	Cloud_black: NATURAL_32 = 0x111114
	Ink_bright: NATURAL_32 = 0xD8D8DC
	Ink_mid: NATURAL_32 = 0xA8A8AE
	Amber: NATURAL_32 = 0xE8A33D
	Accent_red: NATURAL_32 = 0xE5484D
	Dim: NATURAL_32 = 0x7A7A80

end
