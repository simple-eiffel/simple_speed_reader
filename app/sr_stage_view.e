note
	description: "[
		The RSVP frame: the primary word on near-black, the ORP letter
		red and pinned at fixed X with tick marks, the dim WPM readout
		below. Foreign-script tokens render centered, whole-word, no
		pivot. The 1-9 reading window flanks the primary with fisheye
		neighbors - smaller and dimmer with distance, inked by their
		word-cloud tier. Blank during breathers - the video's dark frames.
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
			word_window := 1
			create surface.make (400.0)
			surface.set_grow (1.0)
			surface.set_on_paint (agent paint)
			is_in_breather := False
			word_alpha := 1.0
		ensure
			reader_kept: reader = a_reader
			solo_window: word_window = 1
		end

feature -- Access

	surface: SW_CANVAS

	font_size: REAL_64

	word_window: INTEGER
			-- The 1-9 key law: 1 = the primary word alone; level N >= 2
			-- flanks it with the facade's window_left_span / window_right_span
			-- fisheye neighbors.

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

	set_word_window (a_level: INTEGER)
		require
			lawful: a_level >= 1 and a_level <= 9
		do
			word_window := a_level
		ensure
			set: word_window = a_level
		end

	word_alpha: REAL_64
			-- Fade-mode brightness of the word (1.0 = crisp).

	set_word_alpha (a_alpha: REAL_64)
		require
			unit: a_alpha >= 0.0 and a_alpha <= 1.0
		do
			word_alpha := a_alpha
		ensure
			set: word_alpha = a_alpha
		end

feature {NONE} -- Painting

	reader: SIMPLE_SPEED_READER

	paint (p: SW_PAINTER; a_x, a_y, a_w, a_h: REAL_64)
		local
			l_pin, l_base, l_pre_w, l_piv_w, l_all_w: REAL_64
			l_left_edge, l_right_edge, l_gap, l_adv: REAL_64
			i, d, l_left_n, l_right_n: INTEGER
			l_word, l_nw: STRING_32
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
						p.set_color (faded (Ink))
						p.text (l_pin - l_pre_w - l_piv_w / 2, l_base,
							l_word.substring (1, l_tok.pivot_index - 1))
						p.set_color (faded (Accent_red))
						p.text (l_pin - l_piv_w / 2, l_base,
							l_word.substring (l_tok.pivot_index, l_tok.pivot_index))
						p.set_color (faded (Ink))
						p.text (l_pin + l_piv_w / 2, l_base,
							l_word.substring (l_tok.pivot_index + 1, l_word.count))
						l_left_edge := l_pin - l_pre_w - l_piv_w / 2
						l_right_edge := l_pin + l_piv_w / 2
							+ p.advance (l_word.substring (l_tok.pivot_index + 1, l_word.count))
					else
						l_all_w := p.advance (l_word)
						p.set_color (faded (Ink))
						p.text (l_pin - l_all_w / 2, l_base, l_word)
						l_left_edge := l_pin - l_all_w / 2
						l_right_edge := l_pin + l_all_w / 2
					end
					if word_window >= 2 then
							-- The reading window (1-9 keys): real neighbors
							-- flank the primary, fisheye-small and dimmer
							-- with distance, inked by word-cloud tier.
							-- Words that miss the stage edge drop, ribbon-style.
						l_left_n := reader.window_left_span (word_window)
						l_right_n := reader.window_right_span (word_window)
						l_gap := (font_size * 0.32).max (10.0)
						from
							i := reader.position - 1
							d := 1
						until
							d > l_left_n or i < 1 or l_left_edge - l_gap < a_x + 8.0
						loop
							l_nw := reader.token (i).word
							p.font (p.Role_mono, neighbor_size (d), False)
							l_adv := p.advance (l_nw)
							if l_left_edge - l_gap - l_adv >= a_x + 8.0 then
								p.set_color (neighbor_color (i, d))
								p.text (l_left_edge - l_gap - l_adv, l_base, l_nw)
							end
							l_left_edge := l_left_edge - l_gap - l_adv
							i := i - 1
							d := d + 1
						end
						from
							i := reader.position + 1
							d := 1
						until
							d > l_right_n or i > reader.token_count
								or l_right_edge + l_gap > a_x + a_w - 8.0
						loop
							l_nw := reader.token (i).word
							p.font (p.Role_mono, neighbor_size (d), False)
							l_adv := p.advance (l_nw)
							if l_right_edge + l_gap + l_adv <= a_x + a_w - 8.0 then
								p.set_color (neighbor_color (i, d))
								p.text (l_right_edge + l_gap, l_base, l_nw)
							end
							l_right_edge := l_right_edge + l_gap + l_adv
							i := i + 1
							d := d + 1
						end
					end
				end
				if l_tok.is_latin then
					p.set_color (Accent_red)
					p.fill_rect (l_pin - 1.5, l_base - font_size - 20.0, 3.0, 16.0)
					p.fill_rect (l_pin - 1.5, l_base + 14.0, 3.0, 16.0)
				end
				p.font (p.Role_mono, 21.0, True)
				p.set_color (Dim)
				create l_s.make (32)
				l_s.append_string_general ("SPEED: ")
				l_s.append_string_general (reader.current_wpm.out)
				if reader.target_wpm > reader.current_wpm then
					l_s.append_string_general (" -> ")
					l_s.append_string_general (reader.target_wpm.out)
				end
				l_s.append_string_general (" WPM")
				if reader.is_braking then
					l_s.append_string_general ("  [BRAKE]")
				elseif reader.is_held then
					l_s.append_string_general ("  [HELD]")
				end
				p.text (a_x + (a_w - p.advance (l_s)) / 2, a_y + a_h - 30.0, l_s)
			else
				p.font (p.Role_mono, 18.0, False)
				p.set_color (Dim)
				l_s := {STRING_32} "no text - Esc to the cockpit"
				p.text (a_x + (a_w - p.advance (l_s)) / 2, l_base, l_s)
			end
		end

	faded (a_color: NATURAL_32): NATURAL_32
			-- `a_color' at fade-mode brightness - the primary's ink.
		do
			Result := toward_stage (a_color, word_alpha)
		end

	toward_stage (a_color: NATURAL_32; a_vis: REAL_64): NATURAL_32
			-- `a_color' lerped toward the stage black: `a_vis' 1.0 = full
			-- ink, 0.0 = swallowed - alpha on a solid ground, without
			-- touching cairo alpha.
		require
			unit: a_vis >= 0.0 and a_vis <= 1.0
		local
			l_r, l_g, l_b: INTEGER
		do
			l_r := lerp_channel ((Stage_black |>> 16).bit_and (0xFF).to_integer_32,
				(a_color |>> 16).bit_and (0xFF).to_integer_32, a_vis)
			l_g := lerp_channel ((Stage_black |>> 8).bit_and (0xFF).to_integer_32,
				(a_color |>> 8).bit_and (0xFF).to_integer_32, a_vis)
			l_b := lerp_channel (Stage_black.bit_and (0xFF).to_integer_32,
				a_color.bit_and (0xFF).to_integer_32, a_vis)
			Result := (l_r.to_natural_32 |<< 16) + (l_g.to_natural_32 |<< 8) + l_b.to_natural_32
		end

	lerp_channel (a_bg, a_fg: INTEGER; a_vis: REAL_64): INTEGER
		require
			bytes: a_bg >= 0 and a_bg <= 255 and a_fg >= 0 and a_fg <= 255
			unit: a_vis >= 0.0 and a_vis <= 1.0
		do
			Result := a_bg + ((a_fg - a_bg) * (a_vis * 100.0).truncated_to_integer) // 100
		ensure
			byte: Result >= 0 and Result <= 255
		end

	neighbor_size (a_distance: INTEGER): REAL_64
			-- Fisheye type taper: Neighbor_decay^d of the stage font,
			-- floored legible - the primary towers, context trails away.
		require
			positive: a_distance >= 1
		do
			Result := (font_size * decayed (Neighbor_decay, Neighbor_floor, a_distance)).max (9.0)
		ensure
			legible: Result >= 9.0
			smaller_than_primary: Result < font_size
		end

	neighbor_color (a_index, a_distance: INTEGER): NATURAL_32
			-- Word-cloud tier ink for the neighbor at `a_index', dimmed
			-- toward the stage black with distance, melting in fade mode.
		require
			in_text: reader.has_text and then (a_index >= 1 and a_index <= reader.token_count)
			positive: a_distance >= 1
		local
			l_ink: NATURAL_32
		do
			inspect reader.cloud_tier (a_index)
			when 5 then
				l_ink := Accent_red
			when 4 then
				l_ink := Amber
			when 3 then
				l_ink := Ink_bright
			when 2 then
				l_ink := Ink_mid
			else
				l_ink := Neighbor_ink
			end
			Result := toward_stage (l_ink, word_alpha * decayed (Dim_decay, Dim_floor, a_distance))
		end

	decayed (a_factor, a_floor: REAL_64; a_distance: INTEGER): REAL_64
			-- `a_factor'^`a_distance', floored at `a_floor'.
		require
			shrinking: a_factor > 0.0 and a_factor < 1.0
			floored: a_floor > 0.0 and a_floor < 1.0
			positive: a_distance >= 1
		local
			i: INTEGER
		do
			Result := 1.0
			from
				i := 1
			until
				i > a_distance or Result <= a_floor
			loop
				Result := Result * a_factor
				i := i + 1
			end
			Result := Result.max (a_floor)
		ensure
			bounded: Result >= a_floor and Result <= a_factor.max (a_floor)
		end

feature {NONE} -- Palette (the video's; tier inks shared with the ribbon)

	Stage_black: NATURAL_32 = 0x0D0D0F
	Ink: NATURAL_32 = 0xE8E8EA
	Accent_red: NATURAL_32 = 0xE5484D
	Dim: NATURAL_32 = 0x8A8A90
	Amber: NATURAL_32 = 0xE8A33D
	Ink_bright: NATURAL_32 = 0xD8D8DC
	Ink_mid: NATURAL_32 = 0xB0B0B6
	Neighbor_ink: NATURAL_32 = 0xA8A8AE
			-- Unranked neighbors' plain ink, pre-dim.

feature {NONE} -- Reading window laws

	Neighbor_decay: REAL_64 = 0.66
			-- Fisheye size taper per step out from the primary.

	Neighbor_floor: REAL_64 = 0.30

	Dim_decay: REAL_64 = 0.72
			-- Brightness taper per step out - dimmer, never invisible.

	Dim_floor: REAL_64 = 0.34

invariant
	window_lawful: word_window >= 1 and word_window <= 9
	readable_type: font_size >= 16.0 and font_size <= 160.0

end
