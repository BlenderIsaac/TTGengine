extends CharacterController
class_name Player

var game_manager : GameManager

var keybind : GameManager.Keybind
var controller_device = 0

var money := 200
var player_color : Color

var number : int

var audio : AudioPlayer

func _ready():
	audio = AudioPlayer.new()
	audio.universal = true
	add_child(audio)
	
	var dir = ResourceManager.ResLoadDir.new()
	
	var heart_sound = ResourceManager.SoundLoadDetails.new(dir, "Sounds/HEART.WAV")
	audio.set_sound("HeartPickup", [heart_sound])
	
	# add coins
	# add switching
	# add tagging

func _physics_process(_delta):
	if controlling:
		var axis = get_axis()
		axis = axis.rotated(-get_viewport().get_camera_3d().rotation.y + PI)
		set_input_vector(axis)

func _input(event):
	match keybind.control_type:
		0:
			if event is InputEventKey and event.echo == false and event.pressed == true:
				input(event.physical_keycode)
		1:
			if event is InputEventJoypadButton and event.pressed and event.device == controller_device:
				input(event.button_index)

func input(code):
	match code:
		keybind.jump_key:
			press_button("Jump")
		keybind.action_key:
			press_button("Action")
		keybind.special_key:
			press_button("Special")
		keybind.tag_key:
			attempt_tag()

func is_bind_pressed(bind):
	match keybind.control_type:
		0:
			print(Input.is_key_pressed(keybind.get(bind)))
			return Input.is_key_pressed(keybind.get(bind))
		1:
			return Input.is_joy_button_pressed(controller_device, keybind.get(bind))

func get_axis():
	if keybind.control_type == 0:
		var vector = Vector2()
		vector.x += int(Input.is_physical_key_pressed(keybind.left_key))
		vector.x -= int(Input.is_physical_key_pressed(keybind.right_key))
		vector.y += int(Input.is_physical_key_pressed(keybind.up_key))
		vector.y -= int(Input.is_physical_key_pressed(keybind.down_key))
		
		return vector.normalized()
	else:
		var x = Input.get_joy_axis(controller_device, JOY_AXIS_LEFT_X)
		var y = Input.get_joy_axis(controller_device, JOY_AXIS_LEFT_Y)
		
		var deadzone = 0.1
		if abs(x) < deadzone:x = 0.0
		if abs(y) < deadzone:y = 0.0
		
		return -Vector2(x, y).normalized()

func reset_control_of(old_controlling : Character):
	set_input_vector(Vector2(0, 0))
	old_controlling.disconnect("death", player_death)
	old_controlling.disconnect("pickup_collided", player_pickup_collided)
	emit_signal("controlling_changed", null)

func set_control_to(new_controlling : Character):
	if controlling:
		reset_control_of(controlling)
	
	new_controlling.connect("death", player_death)
	new_controlling.connect("pickup_collided", player_pickup_collided)
	
	controlling = new_controlling
	set_input_vector(Vector2(0, 0))
	
	emit_signal("controlling_changed", controlling)

func delete():
	if controlling:
		reset_control_of(controlling)
	queue_free()

func player_death():
	
	# Drop studs
	var max_drop := 2000 # The amount of studs we will at max drop... in OG TCS it makes you drop half when you are below 2000 right?
	
	if int(float(money)/2.0) < max_drop:
		max_drop = snappedi(int(float(money)/2.0), 10)
	
	var drop_types = f.get_stud_values_for_count(max_drop)
	
	var drop = 0
	for stud in drop_types:
		drop += f.stud_value[stud]
		controlling.drop_stud(stud)
	
	money -= drop

func player_pickup_collided(pickup):
	if pickup is HeartPickup:
		controlling.change_health(1)
		audio.play("HeartPickup")
		pickup.queue_free()


func attempt_tag():
	if game_manager.level_manager.current_level and controlling and !controlling.dead:
		var tag = find_tag()
		
		if tag:
			var other_players = game_manager.players
			
			for player : Player in other_players:
				if player != self:
					if player.controlling == tag:
						if player.is_bind_pressed("tag_key"):
							tag_character(tag, player)
						return
			
			tag_character(tag)

func find_tag():
	var party = game_manager.level_manager.current_level.party
	
	var best_member = null
	for member : Character in party:
		if member == controlling:
			continue
		
		if member.dead:
			continue
		
		if best_member == null:
			var des = get_des(member)
			if des:
				best_member = member
			continue
		
		var best_des = get_des(best_member)
		var new_des = get_des(member)
		
		if new_des and best_des:
			if new_des < best_des:
				best_member = member
	
	return best_member

func get_des(character : Character):
	var dist_squared = character.global_position.distance_squared_to(controlling.global_position)
	var angle = abs(f.angle_to_angle(controlling.mesh_angle_to, Basis.looking_at(character.global_position - controlling.global_position).get_euler().y))
	
	if dist_squared > 2 * 2:
		return null
	 
	if angle > PI/3:
		return null
	
	return angle * (dist_squared * 3)

# A function that tags a character
# The number of particles that spawn when tagging
var tag_part_num = 3
# The spread of the particles
var tag_particle_spread = Vector3(.2, .5, .2)
func create_particles(tag_from : Character, tag_to : Character):
	for i in tag_part_num:
		# Create a new particle
		var tag_particle = ResourceManager.load_scene("Objects/tag_particle").instantiate()
		
		# Set the target of the tag particle
		tag_particle.target = tag_to
		
		# Generate random coordinates for the particle to be placed at, based off tag_particle_spread
		var tag_x = randf_range(-tag_particle_spread.x, tag_particle_spread.x)
		var tag_y = randf_range(-tag_particle_spread.y, tag_particle_spread.y)
		var tag_z = randf_range(-tag_particle_spread.z, tag_particle_spread.z)
		
		# Set the material override to the tag particle material - TODO: globalize later into a global particle material
		var matte_details = ResourceManager.MaterialLoadDetails.new()
		matte_details.base_material = "tag particle"
		matte_details.color = player_color
		tag_particle.get_node("Trail").material_override = ResourceManager.load_material(matte_details)
		# Set the position to our position added to the aiming position and the random pos
		tag_particle.position = controlling.aim_pos + tag_from.position+Vector3(tag_x, tag_y, tag_z)
		# Tell the tag_particle where it originated - so it can go to that same position on the tagged character
		# This is so they don't group up while following
		tag_particle.randomization = Vector3(tag_x, tag_y, tag_z)
		
		# Add the tag particle to the scene
		controlling.section.add_child(tag_particle)

func tag_character(tag : Character, other_player = null):
	
	# loop for the number of particles
	create_particles(controlling, tag)
	if other_player:
		other_player.create_particles(tag, controlling)
	
	var from = controlling
	var to = tag
	
	set_control_to(to)
	if other_player:
		other_player.set_control_to(from)
	
	# Stop the anim on the tag's Modulation and play DropIn to show the player that they have switched
	to.get_node("Modulation").stop()
	to.get_node("Modulation").play("DropIn")
	
	if other_player:
		from.get_node("Modulation").stop()
		from.get_node("Modulation").play("DropIn")
	
	game_manager.emit_signal("players_changed", game_manager.players)
