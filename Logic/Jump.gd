extends Logic

var is_backflip : bool = false
var is_airjump : bool = false
var animation : String = "Jump"
var sound : String = "Jump"
var speed = 2.3

func trigger():
	anim.play(animation)
	audio.play(sound)
	C.char_vel.y = speed * var_scale


func player_input(button):
	if button == "Jump":
		if C.is_on_floor():
			trigger()
			return true
	
	return false
