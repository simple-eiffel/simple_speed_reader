note
	description: "[
		The regression surface: on pause, the surrounding sentences as a
		readable page, the stopped word marked. Click the word where
		comprehension was last solid - that becomes the resume point.
	]"
	author: "Larry Rix"

class
	SR_CONTEXT_VIEW

create
	make

feature {NONE} -- Initialization

	make (a_reader: SIMPLE_SPEED_READER)
		do
			reader := a_reader
			create word_rects.make (200)
			create surface.make (400.0)
			surface.set_grow (1.0)
			surface.set_on_paint (agent paint)
			surface.set_on_press (agent press)
		ensure
			reader_kept: reader = a_reader
		end

feature -- Access

	surface: SR_SURFACE

	on_word_click: detachable PROCEDURE [INTEGER]
			-- Token index the reader marked as the comprehension point.

feature -- Element change

	set_on_word_click (a_agent: PROCEDURE [INTEGER])
		do
			on_word_click := a_agent
		ensure
			set: on_word_click = a_agent
		end

feature {NONE} -- Painting

	reader: SIMPLE_SPEED_READER

	word_rects: ARRAYED_LIST [TUPLE [ix: INTEGER; rx, ry, rw, rh: REAL_64]]
			-- Canvas-relative hit boxes, rebuilt each paint.

	Margin: REAL_64 = 26.0
	Body_size: REAL_64 = 19.0

	paint (p: SW_PAINTER; a_x, a_y, a_w, a_h: REAL_64)
		local
			i, l_start, l_end, l_pos, l_sent: INTEGER
			cx, cy, l_wadv, l_space, l_lh: REAL_64
			l_word: STRING_32
			l_hint: STRING_32
		do
			p.set_color (Page_black)
			p.fill_rect (a_x, a_y, a_w, a_h)
			word_rects.wipe_out
			if reader.has_text and then reader.position >= 1 then
				l_pos := reader.position
				l_sent := reader.token (l_pos).sentence_index
					-- Two sentences of runway back, three ahead.
				from
					l_start := l_pos
				until
					l_start = 1 or else reader.token (l_start - 1).sentence_index < l_sent - 2
				loop
					l_start := l_start - 1
				end
				from
					l_end := l_pos
				until
					l_end = reader.token_count or else reader.token (l_end + 1).sentence_index > l_sent + 3
				loop
					l_end := l_end + 1
				end
				p.font (p.Role_mono, 12.0, False)
				p.set_color (Dim)
				l_hint := {STRING_32} "PAUSED - click the word you last truly read - Space resumes at the sentence head - Esc stops"
				p.text (a_x + Margin, a_y + 22.0, l_hint)
				p.font (p.Role_mono, Body_size, False)
				l_space := p.advance ({STRING_32} " ")
				l_lh := Body_size * 1.65
				cx := Margin
				cy := 56.0
				from
					i := l_start
				until
					i > l_end
				loop
					l_word := reader.token (i).word
					l_wadv := p.advance (l_word)
					if i > l_start and then reader.token (i - 1).ends_paragraph then
						cx := Margin
						cy := cy + l_lh * 1.5
					elseif cx + l_wadv > a_w - Margin then
						cx := Margin
						cy := cy + l_lh
					end
					if cy < a_h - 8.0 then
						if i = l_pos then
							p.set_color (Accent_red)
							p.fill_rect (a_x + cx - 3.0, a_y + cy - Body_size - 2.0, l_wadv + 6.0, l_lh - 4.0)
							p.set_color (Page_black)
						elseif i < l_pos then
							p.set_color (Ink_read)
						else
							p.set_color (Ink_ahead)
						end
						p.text (a_x + cx, a_y + cy, l_word)
						word_rects.extend ([i, cx - 2.0, cy - Body_size - 2.0, l_wadv + 4.0, l_lh])
					end
					cx := cx + l_wadv + l_space
					i := i + 1
				end
			end
		end

	press (a_px, a_py: REAL_64)
			-- Canvas-relative click: find the word, report its index.
		do
			across word_rects as r loop
				if a_px >= r.rx and a_px <= r.rx + r.rw
					and a_py >= r.ry and a_py <= r.ry + r.rh
				then
					if attached on_word_click as al_h then
						al_h.call (r.ix)
					end
				end
			end
		end

feature {NONE} -- Palette

	Page_black: NATURAL_32 = 0x111114
	Ink_read: NATURAL_32 = 0xC6C6CA
	Ink_ahead: NATURAL_32 = 0x6E6E74
	Accent_red: NATURAL_32 = 0xE5484D
	Dim: NATURAL_32 = 0x8A8A90

end
