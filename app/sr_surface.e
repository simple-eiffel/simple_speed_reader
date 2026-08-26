note
	description: "[
		A key-hearing canvas: SW_CANVAS that accepts keyboard focus and
		forwards keys and chars to agents - the transport map's ear.
	]"
	author: "Larry Rix"

class
	SR_SURFACE

inherit
	SW_CANVAS
		redefine
			accepts_focus, handle_key, handle_char
		end

create
	make

feature -- Input

	accepts_focus: BOOLEAN
			-- Keys land here.
		do
			Result := True
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		do
			if attached on_vk as al_h then
				al_h.call (a_vk, a_shift)
			end
		end

	handle_char (a_code: INTEGER)
		do
			if attached on_char as al_h then
				al_h.call (a_code)
			end
		end

feature -- Access

	on_vk: detachable PROCEDURE [INTEGER, BOOLEAN]

	on_char: detachable PROCEDURE [INTEGER]

feature -- Element change

	set_on_vk (a_agent: PROCEDURE [INTEGER, BOOLEAN])
		do
			on_vk := a_agent
		ensure
			set: on_vk = a_agent
		end

	set_on_char (a_agent: PROCEDURE [INTEGER])
		do
			on_char := a_agent
		ensure
			set: on_char = a_agent
		end

end
