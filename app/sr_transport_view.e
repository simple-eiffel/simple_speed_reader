note
	description: "[
		The deck: tape-transport controls drawn like they mean it -
		PLAY (resume at the sentence head), HERE (resume exactly),
		STOP, the BRAKE pedal (press and HOLD: resumes braked at the
		floor; release eases up to cruise), and the SPEED dial chip.
		Labels under every glyph, VCR-honest. Paused posture's bar.
	]"
	author: "Larry Rix"

class
	SR_TRANSPORT_VIEW

create
	make

feature {NONE} -- Initialization

	make (a_reader: SIMPLE_SPEED_READER)
		do
			reader := a_reader
			create surface.make (Deck_height)
			surface.set_on_paint (agent paint)
			surface.set_on_press (agent press)
			surface.set_on_release (agent release)
		ensure
			reader_kept: reader = a_reader
		end

feature -- Access

	surface: SW_CANVAS

	on_play, on_here, on_stop, on_speed: detachable PROCEDURE

	on_brake_press, on_brake_release: detachable PROCEDURE

feature -- Element change

	wire (a_play, a_here, a_stop, a_speed, a_brake_press, a_brake_release: PROCEDURE)
		do
			on_play := a_play
			on_here := a_here
			on_stop := a_stop
			on_speed := a_speed
			on_brake_press := a_brake_press
			on_brake_release := a_brake_release
		end

feature {NONE} -- Geometry

	Deck_height: REAL_64 = 72.0
	Zone_w: REAL_64 = 92.0
	Button_count: INTEGER = 5

	Btn_play: INTEGER = 1
	Btn_here: INTEGER = 2
	Btn_stop: INTEGER = 3
	Btn_brake: INTEGER = 4
	Btn_speed: INTEGER = 5

	deck_left (a_w: REAL_64): REAL_64
		do
			Result := (a_w - Zone_w * Button_count) / 2.0
		end

	button_at (a_px, a_w: REAL_64): INTEGER
			-- 0 outside the deck.
		local
			l_i: INTEGER
		do
			l_i := (((a_px - deck_left (a_w)) / Zone_w).truncated_to_integer) + 1
			if a_px >= deck_left (a_w) and l_i >= 1 and l_i <= Button_count then
				Result := l_i
			end
		end

feature {NONE} -- Painting

	reader: SIMPLE_SPEED_READER

	is_brake_pressed: BOOLEAN

	paint (p: SW_PAINTER; a_x, a_y, a_w, a_h: REAL_64)
		local
			gx, gy: REAL_64
			i: INTEGER
		do
			p.set_color (Band_black)
			p.fill_rect (a_x, a_y, a_w, a_h)
			gy := a_y + 28.0
			from
				i := 1
			until
				i > Button_count
			loop
				gx := a_x + deck_left (a_w) + Zone_w * (i - 1) + Zone_w / 2.0
				inspect i
				when 1 then
					p.set_color (Ink)
					triangle_right (p, gx - 2.0, gy, 11.0)
					glyph_label (p, gx, a_y, "PLAY")
				when 2 then
					p.set_color (Ink)
					p.fill_rect (gx - 11.0, gy - 10.0, 3.0, 20.0)
					triangle_right (p, gx + 2.0, gy, 9.0)
					glyph_label (p, gx, a_y, "HERE")
				when 3 then
					p.set_color (Ink)
					p.fill_rect (gx - 9.0, gy - 9.0, 18.0, 18.0)
					glyph_label (p, gx, a_y, "STOP")
				when 4 then
					if is_brake_pressed or reader.is_braking then
						p.set_color (Accent_red)
					else
						p.set_color (Ink)
					end
					brake_glyph (p, gx, gy)
					glyph_label (p, gx, a_y, "BRAKE - hold")
				when 5 then
					p.set_color (Ink)
					speed_glyph (p, gx, gy)
					glyph_label (p, gx, a_y, "SPEED")
				else
				end
				i := i + 1
			end
		end

	triangle_right (p: SW_PAINTER; a_cx, a_cy, a_r: REAL_64)
			-- A filled play-style triangle pointing right.
		do
			p.triangle_fill (a_cx - a_r * 0.7, a_cy - a_r,
				a_cx - a_r * 0.7, a_cy + a_r, a_cx + a_r, a_cy)
		end

	brake_glyph (p: SW_PAINTER; a_cx, a_cy: REAL_64)
			-- The automotive brake-warning mark: a circle holding an
			-- exclamation, flanked by two arcs. Any driver knows it.
		do
			p.set_line_width (2.0)
			p.circle_stroke (a_cx, a_cy, 8.0)
			p.fill_rect (a_cx - 1.2, a_cy - 5.0, 2.4, 6.0)
			p.fill_rect (a_cx - 1.2, a_cy + 2.6, 2.4, 2.4)
			p.arc_stroke (a_cx, a_cy, 12.5, 2.4, 3.9)
			p.arc_stroke (a_cx, a_cy, 12.5, -0.75, 0.75)
		end

	speed_glyph (p: SW_PAINTER; a_cx, a_cy: REAL_64)
			-- A little dial: half-gauge with a needle.
		do
			p.set_line_width (2.0)
			p.arc_stroke (a_cx, a_cy + 4.0, 10.0, 3.4, 6.02)
			p.line (a_cx, a_cy + 4.0, a_cx + 6.0, a_cy - 4.0, 2.0)
		end

	glyph_label (p: SW_PAINTER; a_cx, a_y: REAL_64; a_text: READABLE_STRING_GENERAL)
		do
			p.font (p.Role_mono, 10.0, False)
			p.set_color (Dim)
			p.text (a_cx - p.advance (a_text) / 2.0, a_y + Deck_height - 12.0, a_text)
		end

feature {NONE} -- Input

	last_width: REAL_64

	press (a_px, a_py: REAL_64)
		do
			inspect button_at (a_px, surface.width)
			when 1 then
				if attached on_play as al_h then
					al_h.call
				end
			when 2 then
				if attached on_here as al_h then
					al_h.call
				end
			when 3 then
				if attached on_stop as al_h then
					al_h.call
				end
			when 4 then
				is_brake_pressed := True
				if attached on_brake_press as al_h then
					al_h.call
				end
			when 5 then
				if attached on_speed as al_h then
					al_h.call
				end
			else
			end
		end

	release (a_x, a_y: INTEGER)
		do
			if is_brake_pressed then
				is_brake_pressed := False
				if attached on_brake_release as al_h then
					al_h.call
				end
			end
		end

feature {NONE} -- Palette

	Band_black: NATURAL_32 = 0x0F0F12
	Ink: NATURAL_32 = 0xC8C8CC
	Accent_red: NATURAL_32 = 0xE5484D
	Dim: NATURAL_32 = 0x8A8A90

end
