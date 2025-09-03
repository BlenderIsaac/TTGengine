extends Logic

var weapon_name : String

var grab_anim := "Activate"
var dismiss_anim := "Deactivate"

var grab_sound := "Out"
var dismiss_sound := "In"

var visibile_tween : Tween

func player_input(_button):
	if _button == "Action":
		if C.current_weapon == null:
			grab_weapon()
			return true
	
	if _button == "Special":
		if C.current_weapon != null:
			if C.current_weapon.name == weapon_name:
				dismiss_weapon()
				return true
	
	return false

func grab_weapon():
	C.set_weapon(C.weapons[weapon_name])
	audio.play(weapon_name + grab_sound)
	if current_anim == "Idle_loop":
		play_anim(grab_anim, 0.2)
		C.current_weapon.force_visibility = -1
		
		delay_forced_visibility(C.current_weapon, C.get_anim_key_frames().ShowAt)
	else:
		update_current_anim()

func dismiss_weapon():
	audio.play(weapon_name + dismiss_sound)
	if current_anim == "Idle_loop":
		play_anim(dismiss_anim, 0.2)
		C.current_weapon.force_visibility = 1
		
		delay_forced_visibility(C.current_weapon, C.get_anim_key_frames().HideAt)
		
		C.set_weapon(null)
	else:
		C.set_weapon(null)
		update_current_anim()


func delay_forced_visibility(weapon, delay):
	if visibile_tween:
		visibile_tween.stop()
	
	var tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(Callable(weapon, "set").bind("force_visibility", 0))


func update_current_anim():
	var anim_position = anim.current_animation_position
	
	play_anim(current_anim, 0.3)
	anim.seek(anim_position, true)
