note
	description: "[
		The deck, full VCR order: START (|<<), section and paragraph
		jumps both ways, PLAY/PAUSE, REPLAY/HERE, STOP, the BRAKE
		pedal, and the SPEED dial. Section buttons light up only when
		the text has detected sections. Labels under every glyph,
		per-button tooltips naming the key-combos, state-aware faces.
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
			surface.set_on_hover (agent hover)
		ensure
			reader_kept: reader = a_reader
		end

feature -- Access

	surface: SW_CANVAS

	on_play, on_here, on_stop, on_speed: detachable PROCEDURE

	on_brake_press, on_brake_release: detachable PROCEDURE

	on_start_over, on_par_back, on_par_fwd, on_sect_back, on_sect_fwd: detachable PROCEDURE

	on_cloud: detachable PROCEDURE

feature -- Element change

	wire (a_play, a_here, a_stop, a_speed, a_brake_press, a_brake_release,
			a_start_over, a_par_back, a_par_fwd, a_sect_back, a_sect_fwd,
			a_cloud: PROCEDURE)
		do
			on_play := a_play
			on_here := a_here
			on_stop := a_stop
			on_speed := a_speed
			on_brake_press := a_brake_press
			on_brake_release := a_brake_release
			on_start_over := a_start_over
			on_par_back := a_par_back
			on_par_fwd := a_par_fwd
			on_sect_back := a_sect_back
			on_sect_fwd := a_sect_fwd
			on_cloud := a_cloud
		end

feature {NONE} -- Geometry (VCR order)

	Deck_height: REAL_64 = 72.0
	Zone_w: REAL_64 = 84.0
	Button_count: INTEGER = 11

	Btn_start: INTEGER = 1
	Btn_sect_back: INTEGER = 2
	Btn_par_back: INTEGER = 3
	Btn_play: INTEGER = 4
	Btn_here: INTEGER = 5
	Btn_par_fwd: INTEGER = 6
	Btn_sect_fwd: INTEGER = 7
	Btn_stop: INTEGER = 8
	Btn_brake: INTEGER = 9
	Btn_speed: INTEGER = 10
	Btn_cloud: INTEGER = 11

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
				when Btn_start then
					p.set_color (Ink)
					p.fill_rect (gx - 13.0, gy - 10.0, 3.0, 20.0)
					triangle_left (p, gx - 3.0, gy, 8.0)
					triangle_left (p, gx + 9.0, gy, 8.0)
					glyph_label (p, gx, a_y, "START")
				when Btn_sect_back then
					p.set_color (sections_ink)
					triangle_left (p, gx - 5.0, gy, 9.0)
					triangle_left (p, gx + 7.0, gy, 9.0)
					glyph_label (p, gx, a_y, "SECT")
				when Btn_par_back then
					p.set_color (Ink)
					p.fill_rect (gx - 10.0, gy - 10.0, 3.0, 20.0)
					triangle_left (p, gx + 4.0, gy, 9.0)
					glyph_label (p, gx, a_y, "PARA")
				when Btn_play then
					p.set_color (Ink)
					if reader.is_running then
						p.fill_rect (gx - 8.0, gy - 10.0, 5.0, 20.0)
						p.fill_rect (gx + 3.0, gy - 10.0, 5.0, 20.0)
						glyph_label (p, gx, a_y, "PAUSE")
					else
						triangle_right (p, gx - 2.0, gy, 11.0)
						glyph_label (p, gx, a_y, "PLAY")
					end
				when Btn_here then
					p.set_color (Ink)
					p.fill_rect (gx - 11.0, gy - 10.0, 3.0, 20.0)
					triangle_right (p, gx + 2.0, gy, 9.0)
					if reader.is_running then
						glyph_label (p, gx, a_y, "REPLAY")
					else
						glyph_label (p, gx, a_y, "HERE")
					end
				when Btn_par_fwd then
					p.set_color (Ink)
					triangle_right (p, gx - 4.0, gy, 9.0)
					p.fill_rect (gx + 7.0, gy - 10.0, 3.0, 20.0)
					glyph_label (p, gx, a_y, "PARA")
				when Btn_sect_fwd then
					p.set_color (sections_ink)
					triangle_right (p, gx - 7.0, gy, 9.0)
					triangle_right (p, gx + 5.0, gy, 9.0)
					glyph_label (p, gx, a_y, "SECT")
				when Btn_stop then
					p.set_color (Ink)
					p.fill_rect (gx - 9.0, gy - 9.0, 18.0, 18.0)
					glyph_label (p, gx, a_y, "STOP")
				when Btn_brake then
					if is_brake_pressed or reader.is_braking then
						p.set_color (Accent_red)
					else
						p.set_color (Ink)
					end
					brake_glyph (p, gx, gy)
					glyph_label (p, gx, a_y, "BRAKE - hold")
				when Btn_speed then
					p.set_color (Ink)
					speed_glyph (p, gx, gy)
					glyph_label (p, gx, a_y, "SPEED")
				when Btn_cloud then
					p.set_color (Ink)
					cloud_glyph (p, gx, gy)
					glyph_label (p, gx, a_y, "CLOUD")
				else
				end
				i := i + 1
			end
		end

	sections_ink: NATURAL_32
			-- Lit when the text has sections; ghosted when it does not.
		do
			if reader.has_sections then
				Result := Ink
			else
				Result := Ghost
			end
		end

	triangle_right (p: SW_PAINTER; a_cx, a_cy, a_r: REAL_64)
		do
			p.triangle_fill (a_cx - a_r * 0.7, a_cy - a_r,
				a_cx - a_r * 0.7, a_cy + a_r, a_cx + a_r, a_cy)
		end

	triangle_left (p: SW_PAINTER; a_cx, a_cy, a_r: REAL_64)
		do
			p.triangle_fill (a_cx + a_r * 0.7, a_cy - a_r,
				a_cx + a_r * 0.7, a_cy + a_r, a_cx - a_r, a_cy)
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

	cloud_glyph (p: SW_PAINTER; a_cx, a_cy: REAL_64)
			-- A little cumulus: three arcs on a baseline.
		do
			p.set_line_width (2.0)
			p.arc_stroke (a_cx - 6.0, a_cy + 2.0, 5.0, 1.57, 4.71)
			p.arc_stroke (a_cx, a_cy - 3.0, 6.5, 2.6, 6.1)
			p.arc_stroke (a_cx + 7.0, a_cy + 2.0, 5.0, 4.71, 7.85)
			p.line (a_cx - 6.0, a_cy + 7.0, a_cx + 7.0, a_cy + 7.0, 2.0)
		end

	speed_glyph (p: SW_PAINTER; a_cx, a_cy: REAL_64)
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

	press (a_px, a_py: REAL_64)
		do
			inspect button_at (a_px, surface.width)
			when 1 then
				call_if (on_start_over)
			when 2 then
				if reader.has_sections then
					call_if (on_sect_back)
				end
			when 3 then
				call_if (on_par_back)
			when 4 then
				call_if (on_play)
			when 5 then
				call_if (on_here)
			when 6 then
				call_if (on_par_fwd)
			when 7 then
				if reader.has_sections then
					call_if (on_sect_fwd)
				end
			when 8 then
				call_if (on_stop)
			when 9 then
				is_brake_pressed := True
				call_if (on_brake_press)
			when 10 then
				call_if (on_speed)
			when 11 then
				call_if (on_cloud)
			else
			end
		end

	call_if (a_agent: detachable PROCEDURE)
		do
			if attached a_agent as al_a then
				al_a.call
			end
		end

	release (a_x, a_y: INTEGER)
		do
			if is_brake_pressed then
				is_brake_pressed := False
				call_if (on_brake_release)
			end
		end

	hover (a_px, a_py: REAL_64)
			-- Retarget the tooltip to the button under the pointer -
			-- key-combo discovery lives here.
		do
			inspect button_at (a_px, surface.width)
			when 1 then
				surface.set_tooltip ("START OVER - back to word one, the ramp begins again from your start speed")
			when 2 then
				if reader.has_sections then
					surface.set_tooltip ("Previous SECTION (headings found in this text)")
				else
					surface.set_tooltip ("Sections: none detected in this text - it lights up when headings are found")
				end
			when 3 then
				surface.set_tooltip ("Previous PARAGRAPH - to its head first, then back one each press")
			when 4 then
				if reader.is_running then
					surface.set_tooltip ("PAUSE - Space, or click the stage")
				else
					surface.set_tooltip ("PLAY - resume at the sentence head - Space")
				end
			when 5 then
				if reader.is_running then
					surface.set_tooltip ("REPLAY this sentence at pace - Left arrow")
				else
					surface.set_tooltip ("Resume exactly HERE - Enter, or click a word above")
				end
			when 6 then
				surface.set_tooltip ("Next PARAGRAPH (skipped words are logged honestly)")
			when 7 then
				if reader.has_sections then
					surface.set_tooltip ("Next SECTION (headings found in this text)")
				else
					surface.set_tooltip ("Sections: none detected in this text - it lights up when headings are found")
				end
			when 8 then
				surface.set_tooltip ("STOP and log the run - Esc")
			when 9 then
				surface.set_tooltip ("BRAKE - hold with the mouse - key B toggles - drag left to scrub back")
			when 10 then
				surface.set_tooltip ("SPEED drawer - keys: +/- 25 wpm, Shift 50, Ctrl+Shift 100 - Alt +/- font size")
			when 11 then
				surface.set_tooltip ("WORD CLOUD - key W - the themes of the document, section or paragraph")
			else
				surface.set_tooltip ("")
			end
		end

feature {NONE} -- Palette

	Band_black: NATURAL_32 = 0x0F0F12
	Ink: NATURAL_32 = 0xC8C8CC
	Ghost: NATURAL_32 = 0x3C3C42
	Accent_red: NATURAL_32 = 0xE5484D
	Dim: NATURAL_32 = 0x8A8A90

end
