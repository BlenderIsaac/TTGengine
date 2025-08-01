extends "res://Logic/LOGIC.gd"

# variables to do with deflect stamina regen
var regen_per_second = 1.0

# the maximum amount of bullets we can deflect before staggering
var max_stamina:float = 10.0
var stamina:float = 10.0

var damage_taken = 0
var max_damage_during_stagger = 2
var lag_weight = 1.0

var BlockStamina = null

var BackBar = null
var FrontBar = null
var LagBar = null
func _ready():
	
	generate_block_stamina()
	
	add_child(BlockStamina)
	
	update_vis()

func generate_block_stamina():
	BlockStamina = Node3D.new()
	BackBar = Sprite3D.new()
	FrontBar = Sprite3D.new()
	LagBar = Sprite3D.new()
	
	BlockStamina.add_child(BackBar)
	BlockStamina.add_child(FrontBar)
	BlockStamina.add_child(LagBar)
	
	BackBar.pixel_size = 0.0029
	FrontBar.pixel_size = 0.0029
	LagBar.pixel_size = 0.0029
	
	BackBar.texture = l.get_load("res://Textures/Bars/EmptyBar.png")
	FrontBar.texture = l.get_load("res://Textures/Bars/StaminaBar.png")
	LagBar.texture = l.get_load("res://Textures/Bars/StaminaBar.png")
	
	BackBar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	FrontBar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	LagBar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	FrontBar.render_priority = 2
	FrontBar.region_enabled = true
	FrontBar.region_rect.size = Vector2(512.0, 56.0)
	
	LagBar.render_priority = 1
	LagBar.region_enabled = true
	LagBar.region_rect.size = Vector2(512.0, 56.0)
	LagBar.modulate.a = 0.25
	
	BlockStamina.hide()
	BlockStamina.position = C.aim_pos*2 + Vector3(0, 0.1, 0)


func get_switched_var():
	return stamina/max_stamina

func set_switched_var(vars):
	stamina = vars*max_stamina


func die(_var):
	stamina = max_stamina

func can_switch():
	return false

func can_tag():
	return false


func change_stamina(value:float):
	
	stamina = value + stamina
	
	stamina = clampf(stamina, 0.0, max_stamina)
	
	update_vis()

func update_vis():
	
	FrontBar.region_rect.size = Vector2(clamp(lerpf(-0.00001, 512.0, float(stamina)/float(max_stamina)), -0.00001, 512.0), 56.0)
	FrontBar.offset.x = lerpf(-512.0/2.0, 0.0, float(stamina)/float(max_stamina))
	
	if stamina <= 0 and !C.movement_state == "Stamina":
		stagger()


func reset():
	BlockStamina.queue_free()


func exclusive_physics(_delta):
	stagger_timer += _delta
	
	anim.play(C.weapon_prefix+"Stagger", 0)
	
	var root_vel = C.get_root_vel(0, 1)/_delta
	
	if C.is_on_floor():
		# Calculate Gravity
		C.char_vel.y = C.get_base_movement_state().air_gravity*_delta*C.var_scale
	else:
		C.char_vel.y += C.get_base_movement_state().air_gravity*_delta*C.var_scale
	
	C.mesh_angle_lerp(_delta, 0.4)
	
	# Set the velocity
	C.set_velocity(C.char_vel+C.push_vel+root_vel)
	C.move_and_slide()
	
	if stagger_timer >= anim.current_animation_length:
		stamina = max_stamina
		update_vis()
		
		C.reset_movement_state()
		anim.play(C.weapon_prefix+"Idleloop", .3)


var staggered_weapon = ""
var stagger_timer = 0.0
func stagger():
	damage_taken = 0
	
	staggered_weapon = C.weapon_prefix
	
	if !staggered_weapon == "":
		if C.has_logic("BaseSwordAI"):
			C.get_logic("BaseSwordAI").force_weapon_out.append("Stamina")
	
	stagger_timer = 0.0
	C.set_movement_state("Stamina")


func exclusive_damage(damage:f.Damage):
	
	if damage.amount > 0:
		damage_taken += damage.amount
		
		if damage_taken >= max_damage_during_stagger:
			
			stamina = max_stamina
			update_vis()
			
			C.reset_movement_state()
			anim.play(C.weapon_prefix+"Idleloop", .3)
	
	C.generic_damage(damage.amount, damage.iframes)


var states_cant_regen = ["SwordBlock", "Stamina"]
func inclusive_physics(_delta):
	
	if !stamina == max_stamina:
		BlockStamina.show()
	else:
		BlockStamina.hide()
	
	if !C.movement_state == "Stamina":
		if C.has_logic("BaseSwordAI"):
			if C.get_logic("BaseSwordAI").force_weapon_out.has("Stamina"):
				C.get_logic("BaseSwordAI").force_weapon_out.erase("Stamina")
	
	var perc = float(stamina)/float(max_stamina)
	var stam_to = clamp(lerpf(-0.00001, 512.0, perc), -0.00001, 512.0)
	
	LagBar.region_rect.size = Vector2(lerp(LagBar.region_rect.size.x, stam_to, lag_weight), 56.0)
	
	LagBar.offset.x = lerp(LagBar.offset.x, lerpf(-512.0/2.0, 0.0, perc), lag_weight)
	
	lag_weight = _delta*10
	
	if not states_cant_regen.has(C.movement_state):
		if stamina < max_stamina:
			
			change_stamina(_delta*regen_per_second)
			
		elif stamina > max_stamina:
			stamina = max_stamina
			update_vis()
