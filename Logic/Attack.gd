extends Logic

var anim_name : String
var sound_name : String
var take_logic_control := false

var rate_seconds := 0.4

var do_target := true
var target_range := 100.0
var target_cone := 0.8

var can_move := true

var attack_charged := false

var dist_weight := 1.0
var angle_weight := 2.0
var friend_penalty := 3.0

var weapon : Weapon
var weapon_name : String

func _ready():
	assert(weapon_name)
	weapon = C.weapons[weapon_name]
	
	if not attack_charged:
		queue_weapon_recharge()

func player_input(button):
	if button == "Action":
		if C.current_weapon == weapon:
			if C.current_logic == C.base_logic:
				if attack_charged:
					trigger()
					return true
	return false


func trigger():
	if take_logic_control:
		C.current_logic = self
	
	attack_charged = false
	
	audio.play(sound_name)
	
	if C.is_on_floor():
		if input_vector == Vector2():
			play_anim(anim_name, 0.1)
	
	weapon.trigger(C.find_opponent(target_cone, target_range))
	queue_weapon_recharge()


func exclusive_physics(_delta):
	if can_move:
		pass


func queue_weapon_recharge():
	if rate_seconds <= 0.0:
		attack_charged = true
		return
	var tween := create_tween()
	tween.tween_interval(rate_seconds)
	tween.tween_callback(Callable(set).bind("attack_charged", true))


#func warn_target(target):
	#if target.has_method("warn"):
		#target.warn("projectile", [self])
