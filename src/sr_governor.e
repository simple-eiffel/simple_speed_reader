note
	description: "[
		Session speed governance - the speed law. current climbs toward
		target (+Ramp_step per Ramp_interval_words); HOLD pins target at
		current; back-off lowers the session's ambition without touching
		the profile ceiling; recovery re-ramps from recovery_wpm.
	]"
	author: "Larry Rix"

class
	SR_GOVERNOR

create
	make

feature {NONE} -- Initialization

	make (a_start, a_recovery, a_comfy_max: INTEGER)
		require
			floor_start: a_start >= Min_wpm
			floor_recovery: a_recovery >= Min_wpm
			order_start: a_start <= a_comfy_max
			order_recovery: a_recovery <= a_comfy_max
			ceiling: a_comfy_max <= Max_wpm
		do
			start_wpm := a_start
			recovery_wpm := a_recovery
			comfy_max_wpm := a_comfy_max
			current_wpm := a_start
			target_wpm := a_comfy_max
			session_target_wpm := a_comfy_max
			max_seen_wpm := a_start
		ensure
			starts_at_start: current_wpm = a_start
			aiming_at_comfy: target_wpm = a_comfy_max
		end

feature -- Access

	current_wpm: INTEGER
			-- The dialed rate right now.

	target_wpm: INTEGER
			-- Where the ramp is climbing to (pinned = current while held).

	session_target_wpm: INTEGER
			-- The ambition HOLD will release back to.

	comfy_max_wpm: INTEGER
			-- The profile ceiling; only set_comfy_max moves it.

	start_wpm, recovery_wpm: INTEGER

	max_seen_wpm: INTEGER
			-- Fastest current_wpm reached (for the run record).

	is_held: BOOLEAN

feature -- Braking (D-016)

	is_braking: BOOLEAN

	is_easing_home: BOOLEAN

	is_brake_active: BOOLEAN
		do
			Result := is_braking or is_easing_home
		end

	pre_brake_wpm: INTEGER
			-- The cruise the release eases back to.

	was_held_before_brake: BOOLEAN

	brake_floor_wpm: INTEGER

feature -- Constants

	Min_wpm: INTEGER = 100
	Max_wpm: INTEGER = 1500
	Ramp_step: INTEGER = 25
	Ramp_interval_words: INTEGER = 12
	Nudge_step: INTEGER = 25
	Brake_floor: INTEGER = 300
	Brake_tick_step: INTEGER = 6
			-- Per 12 ms tick: ~500 wpm/s - a 900->300 glide in ~1.2 s.

feature -- Commands

	note_word_advanced
			-- One word consumed; climb the ramp if an interval completed.
		do
			if not is_held and current_wpm < target_wpm then
				words_since_ramp := words_since_ramp + 1
				if words_since_ramp >= Ramp_interval_words then
					words_since_ramp := 0
					current_wpm := (current_wpm + Ramp_step).min (target_wpm)
				end
			end
			max_seen_wpm := max_seen_wpm.max (current_wpm)
		ensure
			monotone_up: current_wpm >= old current_wpm
			never_past_target: current_wpm <= target_wpm
			target_frame: target_wpm = old target_wpm
			comfy_frame: comfy_max_wpm = old comfy_max_wpm
		end

	hold
			-- Pin the ramp at the current speed.
		require
			not_held: not is_held
		do
			is_held := True
			target_wpm := current_wpm
		ensure
			held: is_held
			pinned: target_wpm = current_wpm
			current_frame: current_wpm = old current_wpm
			ambition_kept: session_target_wpm = old session_target_wpm
		end

	release_hold
			-- Resume the climb toward the session's ambition.
		require
			held: is_held
		do
			is_held := False
			target_wpm := session_target_wpm.min (comfy_max_wpm)
			current_wpm := current_wpm.min (target_wpm)
		ensure
			released: not is_held
			target_restored: target_wpm = old session_target_wpm.min (comfy_max_wpm)
		end

	back_off (a_amount: INTEGER)
			-- Lower this session's ambition; the profile ceiling stands.
		require
			sanctioned_step: a_amount = 25 or a_amount = 50 or a_amount = 100
		do
			target_wpm := (target_wpm - a_amount).max (Min_wpm)
			session_target_wpm := session_target_wpm.min (target_wpm)
			current_wpm := current_wpm.min (target_wpm)
		ensure
			lowered: target_wpm = (old target_wpm - a_amount).max (Min_wpm)
			current_clamped: current_wpm <= target_wpm
			comfy_frame: comfy_max_wpm = old comfy_max_wpm
		end

	raise_target (a_amount: INTEGER)
			-- Raise the target by a sanctioned step (+/=, with Shift 50,
			-- with Ctrl+Shift 100).
		require
			sanctioned_step: a_amount = 25 or a_amount = 50 or a_amount = 100
			not_held: not is_held
		do
			target_wpm := (target_wpm + a_amount).min (comfy_max_wpm)
			session_target_wpm := session_target_wpm.max (target_wpm)
		ensure
			raised_capped: target_wpm = (old target_wpm + a_amount).min (comfy_max_wpm)
			current_frame: current_wpm = old current_wpm
		end

	lower_target (a_amount: INTEGER)
			-- Lower the target by a sanctioned step; ambition and the
			-- current pace follow down.
		require
			sanctioned_step: a_amount = 25 or a_amount = 50 or a_amount = 100
		do
			target_wpm := (target_wpm - a_amount).max (Min_wpm)
			session_target_wpm := session_target_wpm.min (target_wpm)
			current_wpm := current_wpm.min (target_wpm)
		ensure
			lowered_floored: target_wpm = (old target_wpm - a_amount).max (Min_wpm)
			current_clamped: current_wpm <= target_wpm
		end

	nudge_up
			-- Raise the target one step (Up / '.').
		require
			not_held: not is_held
		do
			raise_target (Nudge_step)
		ensure
			raised_capped: target_wpm = (old target_wpm + Nudge_step).min (comfy_max_wpm)
		end

	nudge_down
			-- Lower the target one step (Down / ',').
		do
			lower_target (Nudge_step)
		ensure
			lowered_floored: target_wpm = (old target_wpm - Nudge_step).max (Min_wpm)
		end

	reset_for_recovery
			-- Comprehension recovered from a rewind: re-ramp gently.
		do
			current_wpm := recovery_wpm.min (target_wpm)
			words_since_ramp := 0
		ensure
			at_recovery: current_wpm = recovery_wpm.min (target_wpm)
			target_frame: target_wpm = old target_wpm
		end

	apply_brake
			-- D-016: begin the eased glide toward the brake floor. A
			-- pinned hold is remembered and restored when the ease home
			-- completes.
		require
			idle: not is_brake_active
		do
			is_braking := True
			pre_brake_wpm := current_wpm
			was_held_before_brake := is_held
			if is_held then
				is_held := False
				target_wpm := session_target_wpm.min (comfy_max_wpm)
			end
			brake_floor_wpm := Brake_floor.max (Min_wpm).min (pre_brake_wpm)
		ensure
			braking: is_braking
			cruise_remembered: pre_brake_wpm = old current_wpm
			hold_remembered: was_held_before_brake = old is_held
		end

	release_brake
			-- Let go: ease back up toward the pre-brake cruise.
		require
			braking: is_braking
		do
			is_braking := False
			is_easing_home := True
		ensure
			easing: is_easing_home and not is_braking
		end

	brake_glide_tick
			-- One clock tick of glide (down while braking, up while
			-- easing home); restores a remembered hold at arrival.
		do
			if is_braking then
				current_wpm := (current_wpm - Brake_tick_step).max (brake_floor_wpm)
			elseif is_easing_home then
				current_wpm := (current_wpm + Brake_tick_step).min (pre_brake_wpm.min (target_wpm))
				if current_wpm >= pre_brake_wpm.min (target_wpm) then
					is_easing_home := False
					if was_held_before_brake and not is_held then
						hold
					end
				end
			end
		ensure
			glide_down: (old is_braking) implies current_wpm <= old current_wpm
			glide_up: (old is_easing_home) implies current_wpm >= old current_wpm
		end

	set_comfy_max (a_wpm: INTEGER)
		require
			sane: a_wpm >= Min_wpm and a_wpm <= Max_wpm
		do
			comfy_max_wpm := a_wpm
			target_wpm := target_wpm.min (comfy_max_wpm)
			session_target_wpm := session_target_wpm.min (comfy_max_wpm)
			current_wpm := current_wpm.min (target_wpm)
		ensure
			set: comfy_max_wpm = a_wpm
			clamped: target_wpm <= comfy_max_wpm
		end

feature {NONE} -- Implementation

	words_since_ramp: INTEGER

invariant
	floor: Min_wpm <= current_wpm
	order: current_wpm <= target_wpm
	ceiling: target_wpm <= comfy_max_wpm
	ambition_sane: session_target_wpm >= Min_wpm and session_target_wpm <= comfy_max_wpm
	recovery_sane: recovery_wpm >= Min_wpm and recovery_wpm <= comfy_max_wpm
	held_pins: is_held implies current_wpm = target_wpm

end
