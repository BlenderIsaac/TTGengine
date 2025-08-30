extends Logic

var animation : String
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
	else:
		anim.play(animation)
		weapon.trigger()
		queue_weapon_recharge()


func queue_weapon_recharge():
	if rate_seconds <= 0.0:
		attack_charged = true
		return
	var tween := create_tween()
	tween.tween_interval(rate_seconds)
	tween.tween_callback(Callable(set).bind("attack_charged", true))

#
#func warn_target(target):
	#if target.has_method("warn"):
		#target.warn("projectile", [self])
#
