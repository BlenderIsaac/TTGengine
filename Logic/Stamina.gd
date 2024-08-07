extends "res://Logic/LOGIC.gd"

# variables to do with deflect stamina regen
var regen_timer = 0.0
var regen_time = 1.0

# the maximum amount of bullets we can deflect before staggering
var max_stamina = 10
var stamina = 10

var damage_taken = 0
var max_damage_during_stagger = 2


var BlockStamina = null
func _ready():
	BlockStamina = Label3D.new()#l.get_load("res://Logic/block_stamina_backup.tscn").instantiate()
	BlockStamina.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	BlockStamina.text = ""
	BlockStamina.visible = false
	BlockStamina.position.y = 1.948
	
	add_child(BlockStamina)


func die(_var):
	stamina = max_stamina

func can_switch():
	return false

func can_tag():
	return false


func change_stamina(value):
	
	stamina += value
	
	stamina = floori(stamina)
	stamina = mini(stamina, max_stamina)
	
	update_vis()

func update_vis():
	if stamina > 0:
		BlockStamina.text = "-".repeat(floori(max_stamina-stamina))+"I".repeat(floor(stamina))
	else:
		BlockStamina.text = ""
	
	if !stamina == max_stamina:
		BlockStamina.show()
	else:
		BlockStamina.hide()
	
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


func exclusive_damage(value, _who_from):
	
	if value > 0:
		damage_taken += value
		
		if damage_taken >= max_damage_during_stagger:
			
			stamina = max_stamina
			update_vis()
			
			C.reset_movement_state()
			anim.play(C.weapon_prefix+"Idleloop", .3)
	
	C.generic_damage(value)


var states_cant_regen = ["SwordBlock", "Stamina"]
func inclusive_physics(_delta):
	
	if !C.movement_state == "Stamina":
		if C.has_logic("BaseSwordAI"):
			if C.get_logic("BaseSwordAI").force_weapon_out.has("Stamina"):
				C.get_logic("BaseSwordAI").force_weapon_out.erase("Stamina")
	
	if not states_cant_regen.has(C.movement_state):
		if stamina < max_stamina:
			
			regen_timer += _delta
			
			if regen_timer >= regen_time:
				change_stamina(1)
				regen_timer = 0.0
			
		elif stamina > max_stamina:
			stamina = max_stamina
			update_vis()
	else:
		regen_timer = 0.0
