extends Logic

@export var is_backjump : bool = false
@export var is_airjump : bool = false
@export var animation : String = "Jump"
@export var sound : String = "Jump"
@export var height = 2.3


func trigger():
	play_anim(animation, 0.0, "air")
	audio.play(sound)
	C.char_vel.y = height * var_scale


func player_input(button):
	if button == "Jump":
		if C.base_logic.active:
			if C.is_on_floor() or is_airjump:
				if is_backjump:
					if C.base_logic.move_delay_timer < C.base_logic.move_delay:
						trigger()
						return true
				else:
					trigger()
					return true
	
	return false
