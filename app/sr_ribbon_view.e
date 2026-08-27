note
	description: "[
		The fisheye ribbon (D-015): one line of the real surrounding
		words, tiny at the edges swelling to the current word at
		center - where am I, at a glance. Streamed side normal,
		upcoming side dimmer, center brightest over a red tick.
		Every word is a clickable resume point. Paused posture only.
	]"
	author: "Larry Rix"

class
	SR_RIBBON_VIEW

create
	make

feature {NONE} -- Initialization

	make (a_reader: SIMPLE_SPEED_READER)
		do
			reader := a_reader
			create word_rects.make (48)
			create surface.make (Ribbon_height)
			surface.set_on_paint (agent paint)
			surface.set_on_press (agent press)
		ensure
			reader_kept: reader = a_reader
		end

feature -- Access

	surface: SW_CANVAS

	on_word_click: detachable PROCEDURE [INTEGER]

feature -- Element change

	set_on_word_click (a_agent: PROCEDURE [INTEGER])
		do
			on_word_click := a_agent
		ensure
			set: on_word_click = a_agent
		end

feature {NONE} -- Painting

	reader: SIMPLE_SPEED_READER

	word_rects: ARRAYED_LIST [TUPLE [ix: INTEGER; rx, rw: REAL_64]]

	Ribbon_height: REAL_64 = 64.0
	Center_size: REAL_64 = 26.0
	Decay: REAL_64 = 0.72
	Floor_scale: REAL_64 = 0.24
	Gap: REAL_64 = 9.0

	scale_at (a_distance: INTEGER): REAL_64
			-- D-015: max (0.24, 0.72^|d|).
		require
			non_negative: a_distance >= 0
		local
			i: INTEGER
		do
			Result := 1.0
			from
				i := 1
			until
				i > a_distance or Result <= Floor_scale
			loop
				Result := Result * Decay
				i := i + 1
			end
			Result := Result.max (Floor_scale)
		ensure
			bounded: Result >= Floor_scale and Result <= 1.0
		end

	paint (p: SW_PAINTER; a_x, a_y, a_w, a_h: REAL_64)
		local
			l_pos, i, d: INTEGER
			cx, l_size, l_adv, l_base, l_left_edge, l_right_edge: REAL_64
		do
			p.set_color (Band_black)
			p.fill_rect (a_x, a_y, a_w, a_h)
			word_rects.wipe_out
			if reader.has_text and then reader.position >= 1 then
				l_pos := reader.position
				l_base := a_y + a_h * 0.62
					-- The center word, pinned mid-band over its red tick.
				l_size := Center_size
				p.font (p.Role_mono, l_size, True)
				l_adv := p.advance (reader.token (l_pos).word)
				cx := a_x + a_w / 2.0 - l_adv / 2.0
				p.set_color (Accent_red)
				p.fill_rect (a_x + a_w / 2.0 - 1.5, a_y + a_h - 8.0, 3.0, 5.0)
				p.set_color (Ink_center)
				p.text (cx, l_base, reader.token (l_pos).word)
				word_rects.extend ([l_pos, cx - a_x, l_adv])
				l_left_edge := cx - Gap
				l_right_edge := cx + l_adv + Gap
					-- Leftward: already-streamed words shrink away.
				from
					i := l_pos - 1
					d := 1
				until
					i < 1 or l_left_edge < a_x + 4.0
				loop
					l_size := Center_size * scale_at (d)
					p.font (p.Role_mono, l_size, False)
					l_adv := p.advance (reader.token (i).word)
					if l_left_edge - l_adv >= a_x + 4.0 then
						p.set_color (Ink_read)
						p.text (l_left_edge - l_adv, l_base, reader.token (i).word)
						word_rects.extend ([i, l_left_edge - l_adv - a_x, l_adv])
					end
					l_left_edge := l_left_edge - l_adv - Gap
					i := i - 1
					d := d + 1
				end
					-- Rightward: what is coming, dimmer still.
				from
					i := l_pos + 1
					d := 1
				until
					i > reader.token_count or l_right_edge > a_x + a_w - 4.0
				loop
					l_size := Center_size * scale_at (d)
					p.font (p.Role_mono, l_size, False)
					l_adv := p.advance (reader.token (i).word)
					if l_right_edge + l_adv <= a_x + a_w - 4.0 then
						p.set_color (Ink_ahead)
						p.text (l_right_edge, l_base, reader.token (i).word)
						word_rects.extend ([i, l_right_edge - a_x, l_adv])
					end
					l_right_edge := l_right_edge + l_adv + Gap
					i := i + 1
					d := d + 1
				end
			end
		end

	press (a_px, a_py: REAL_64)
		do
			across
				word_rects as r
			loop
				if a_px >= r.rx and a_px <= r.rx + r.rw then
					if attached on_word_click as al_h then
						al_h.call (r.ix)
					end
				end
			end
		end

feature {NONE} -- Palette

	Band_black: NATURAL_32 = 0x0F0F12
	Ink_center: NATURAL_32 = 0xF0F0F2
	Ink_read: NATURAL_32 = 0x9A9AA0
	Ink_ahead: NATURAL_32 = 0x55555C
	Accent_red: NATURAL_32 = 0xE5484D

end
