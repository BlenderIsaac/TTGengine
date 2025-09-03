extends CharacterController
class_name Player

var up_key := KEY_UP
var down_key := KEY_DOWN
var left_key := KEY_LEFT
var right_key := KEY_RIGHT

var action_key := KEY_J
var jump_key := KEY_K
var special_key := KEY_L

var tag_key := KEY_I

var switch_left_key := KEY_U
var switch_right_key := KEY_O

var money := 0
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
	
	if event is InputEventKey and event.echo == false and event.pressed == true:
		
		match event.physical_keycode:
			jump_key:
				press_button("Jump")
			action_key:
				press_button("Action")
			special_key:
				press_button("Special")

func get_axis():
	var vector = Vector2()
	vector.x += int(Input.is_physical_key_pressed(left_key))
	vector.x -= int(Input.is_physical_key_pressed(right_key))
	vector.y += int(Input.is_physical_key_pressed(up_key))
	vector.y -= int(Input.is_physical_key_pressed(down_key))
	
	return vector.normalized()

func reset_control_of(old_controlling : Character):
	old_controlling.will_respawn = false
	old_controlling.disconnect("death", player_death)
	old_controlling.disconnect("pickup_collided", player_pickup_collided)
	emit_signal("controlling_changed", controlling)

func set_control_to(new_controlling : Character):
	if controlling:
		reset_control_of(controlling)
	
	new_controlling.will_respawn = true
	new_controlling.connect("death", player_death)
	new_controlling.connect("pickup_collided", player_pickup_collided)
	
	controlling = new_controlling
	
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
		var tag_x = randf_range(-tag_from.tag_particle_spread.x, tag_from.tag_particle_spread.x)
		var tag_y = randf_range(-tag_from.tag_particle_spread.y, tag_from.tag_particle_spread.y)
		var tag_z = randf_range(-tag_from.tag_particle_spread.z, tag_from.tag_particle_spread.z)
		
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


func tag_character(tag : Character):
	
	# loop for the number of particles
	create_particles(controlling, tag)
	#create_particles(tag, self)
	
	# Stop the anim on the tag's Modulation and play DropIn to show the player that they have switched
	tag.get_node("Modulation").stop()
	tag.get_node("Modulation").play("DropIn")
