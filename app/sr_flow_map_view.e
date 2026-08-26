note
	description: "[
		The flow map: the whole text as unreadable word-proportional
		texture down the left edge, read half brighter, a red cursor at
		the streaming word. Paused, a click seeks (backward only).
	]"
	author: "Larry Rix"

class
	SR_FLOW_MAP_VIEW

create
	make

feature {NONE} -- Initialization

	make (a_reader: SIMPLE_SPEED_READER)
		do
			reader := a_reader
			create surface.make (400.0)
			surface.set_grow (0.16)
			surface.set_on_paint (agent paint)
			surface.set_on_press (agent press)
		ensure
			reader_kept: reader = a_reader
		end

feature -- Access

	surface: SR_SURFACE

	on_seek: detachable PROCEDURE [INTEGER]
			-- Token index picked on the map.

feature -- Element change

	set_on_seek (a_agent: PROCEDURE [INTEGER])
		do
			on_seek := a_agent
		ensure
			set: on_seek = a_agent
		end

feature {NONE} -- Painting

	reader: SIMPLE_SPEED_READER

	last_height: REAL_64

	paint (p: SW_PAINTER; a_x, a_y, a_w, a_h: REAL_64)
		local
			n, r, idx, l_pos: INTEGER
			l_bw, l_cy: REAL_64
			l_tok: SR_TOKEN
		do
			last_height := a_h
			p.set_color (Gutter_black)
			p.fill_rect (a_x, a_y, a_w, a_h)
			n := reader.token_count
			l_pos := reader.position
			if n >= 2 and a_h >= 2.0 then
				from
					r := 0
				until
					r >= a_h.truncated_to_integer
				loop
					idx := 1 + (r * (n - 1)) // (a_h.truncated_to_integer - 1).max (1)
					l_tok := reader.token (idx.min (n))
					l_bw := 3.0 + l_tok.word.count.min (14) * (a_w - 8.0) / 15.0
					if l_tok.is_foreign_script then
						p.set_color (Foreign_tint)
					elseif idx <= l_pos then
						p.set_color (Read_bright)
					else
						p.set_color (Ahead_dim)
					end
					p.fill_rect (a_x + 3.0, a_y + r, l_bw, 1.0)
					r := r + 2
				end
				if l_pos >= 1 then
					l_cy := (l_pos - 1) * (a_h - 3.0) / (n - 1)
					p.set_color (Accent_red)
					p.fill_rect (a_x, a_y + l_cy, a_w, 3.0)
				end
			end
		end

	press (a_px, a_py: REAL_64)
		local
			n, idx: INTEGER
		do
			n := reader.token_count
			if n >= 2 and last_height >= 2.0 and attached on_seek as al_h then
				idx := (1.0 + a_py * (n - 1) / last_height).truncated_to_integer.max (1).min (n)
				al_h.call (idx)
			end
		end

feature {NONE} -- Palette

	Gutter_black: NATURAL_32 = 0x0A0A0C
	Read_bright: NATURAL_32 = 0x86868C
	Ahead_dim: NATURAL_32 = 0x36363C
	Foreign_tint: NATURAL_32 = 0x7A4A50
	Accent_red: NATURAL_32 = 0xE5484D

end
