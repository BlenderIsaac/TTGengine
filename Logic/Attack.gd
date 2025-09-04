extends Logic

var anim_name : String
var sound_name : String
var take_logic_control := false

var rate_seconds := 0.4

var do_target := true
var target_range := 100.0
var target_cone := 0.8

var can_move := true
var activate_in_air := true

var look_at_opponent := true

var attack_charged := false

var dist_weight := 1.0
var angle_weight := 2.0
var friend_penalty := 3.0

var weapon : Weapon
var weapon_name : String

var chain_into : String
var freeze_moment := 0.0
var is_chaining := false
var time_left_tween : Tween

var is_freezing = false

func _ready():
	assert(weapon_name)
	weapon = C.weapons[weapon_name]
	
	if not attack_charged:
		queue_weapon_recharge()

func player_input(button):
	if button == "Action":
		if attack_charged:
			if weapon.active:
				if C.base_logic.active:
					if activate_in_air or C.is_on_floor():
						trigger()
						return true
		
		if chain_into and active:
			if is_freezing:
				is_freezing = false
				chain()
				return true
			
			if is_chaining == false:
				is_chaining = true
				return true
	return false

func trigger():
	if take_logic_control:
		C.current_logic = self
	else:
		if C.is_on_floor() and input_vector == Vector2():
			play_anim(anim_name, 0.0)
		
		start()


func start():
	attack_charged = false
	
	audio.play(sound_name)
	
	var opponent = C.find_opponent(target_cone, target_range)
	if look_at_opponent and opponent:
		C.mesh_angle_to = Basis.looking_at(opponent.global_position - C.global_position).get_euler().y
	
	weapon.trigger(opponent)
	queue_weapon_recharge()


func enter():
	super()
	assert(take_logic_control == true)
	
	start()
	
	play_anim(anim_name, 0.0)
	
	is_chaining = false
	is_freezing = false
	if !can_move:
		C.char_vel.x = 0
		C.char_vel.z = 0
	
	time_left_tween = create_tween()
	time_left_tween.tween_interval(C.get_anim().length)
	if freeze_moment > 0.0:
		time_left_tween.tween_callback(freeze)
		time_left_tween.tween_interval(freeze_moment)
	time_left_tween.tween_callback(end)


func chain():
	time_left_tween.kill()
	C.current_logic = C.logics[chain_into]


func exclusive_physics(_delta):
	if can_move:
		pass


func freeze():
	is_freezing = true
	
	if is_chaining:
		chain()


func end():
	C.current_logic = C.base_logic


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
