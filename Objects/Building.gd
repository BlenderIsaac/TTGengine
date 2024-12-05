extends Node3D

var b_pos = {}
var obj_left = []

var props
var attr
var gltf

@export var rand_spread = 1
@export var bounce_speed = 17
@export var bounce_height = 0.15

var turn_into_breakable = false

var build_range = 1.5
var bouncing = {}
var advancing = []

var finished = false

var coins = 0

var particles_size = Vector3(.6, 2.06, .6)
var particles_pos = Vector3(0, 2.224, 0)

var audio_player

var push_out_frames = -1

var aabb : AABB

var current_mod = ""
var sounds = {
	"BuildStart" : {
		"cSoundsPath" : ["LEGOFORM1.WAV"]
	},
	"BuildLoop" : {
		"cSoundsPath" : ["LEGOSHAKELP.WAV"]
	}
}

var col = null
var static_body = null
var trimesh_col = null

var character_body = null
var convex_col = null


func _ready():
	add_to_group("Build")
	audio_player = f.make("res://Scripts/AudioPlayer.tscn", position, self)
	audio_player.add_library(sounds, current_mod)
	setup()
	
	for b in b_pos.keys():
		var m = get_node(b)
		
		m.position.x = randf_range(-rand_spread, rand_spread)
		m.position.z = randf_range(-rand_spread, rand_spread)
		
		m.rotation.y = randf_range(-180, 180)

func setup():
	for child in get_children():
		if child is MeshInstance3D:
			if child.name.begins_with("Col"):
				col = child
				
				aabb = col.mesh.get_aabb()
				
				static_body = StaticBody3D.new()
				trimesh_col = CollisionShape3D.new()
				static_body.add_child(trimesh_col)
				static_body.transform = child.transform
				var trimesh_shape = child.mesh.create_trimesh_shape()
				trimesh_col.disabled = true
				trimesh_col.shape = trimesh_shape
				add_child(static_body)
				
				character_body = CharacterBody3D.new()
				convex_col = CollisionShape3D.new()
				character_body.add_child(convex_col)
				character_body.transform = child.transform
				var convex_shape = child.mesh.create_convex_shape(true, true)
				convex_col.disabled = true
				convex_col.shape = convex_shape
				add_child(character_body)
				
				col.hide()
			else:
				obj_left.append(str(child.name))
				b_pos[str(child.name)] = {"pos":child.position,"rot":child.rotation,"sca":child.scale}
				child.position = Vector3()
				child.rotation = Vector3()
				child.scale = Vector3(1, 1, 1)

var build_end = 0.0
var build_end_delay = .5
var building = false
var completely_done = false
func _process(_delta):
	
	if not finished:
		if building:
			
			if !audio_player.has_loop("BuildLoop"):
				if !audio_player.is_playing("BuildStart"):
					audio_player.start_loop("BuildLoop")
			
			if build_end <= 0.0:
				building = false
				audio_player.end_loop("BuildLoop")
			
			build_end -= _delta
		
		for m in advancing:
			if building == false:
				audio_player.play("BuildStart")
			
			building = true
			build_end = build_end_delay
			advance_to_final(m, _delta)
		
		for n in bouncing.keys():
			var m = get_node(n)
			var details = bouncing.get(n)
			
			m.position.y = details.og_pos.y + ((sin(details.time*bounce_height)) + 1)*bounce_height
			
			details.time += _delta*bounce_speed/bounce_height
			
			if details.time >= 30:
				
				m.position.y = details.og_pos.y
				
				bouncing.erase(n)
		
		for n in b_pos.keys():
			
			if obj_left.has(n):
				if not advancing.has(get_node(n)):
					if randf() < .001:
						
						if not bouncing.has(n):
							
							bounce_obj(get_node(n))
		
		if obj_left.size() <= 0:
			finish()
	else:
		
		
		if push_out_frames != -1:
			push_out_frames -= 1
			if push_out_frames == 0:
				character_body.queue_free()
		
		
		if not completely_done:
			var length = PI/build_jump_speed
			
			# If we have finished
			final_jump_timer += _delta
			final_jump_timer = clamp(final_jump_timer, 0.0, length)
			
			global_position.y = (sin(final_jump_timer*build_jump_speed)*build_jump_height)+final_jump_y_pos
			
			if final_jump_timer >= length:
				
				global_position.y = final_jump_y_pos
				completely_done = true
				audio_player.end_loop("BuildLoop")
				final_touches()


var build_jump_height = 1.2
var build_jump_speed = 6

var final_jump_y_pos = 0
var final_jump_timer = 0
func finish():
	finished = true
	final_jump_timer = 0
	final_jump_y_pos = global_position.y

func final_touches():
	
	var particles = l.get_load("res://Objects/built.tscn").instantiate()
	
	particles.position = aabb.position+position + aabb.size/2
	particles.emission_box_extents = aabb.size/2
	particles.rotation = rotation
	particles.current_mod = current_mod
	get_parent().add_child(particles)
	particles.emitting = true
	
	trimesh_col.disabled = false
	convex_col.disabled = false
	push_out_frames = 3
	
	# I think this might be slightly broken... I'm not sure
	# loop until we have dropped enough money
	coins = int(props.STUDS_DROPPED)
	while coins > 0:
		
		# Variables for the type of stud we are dropping and the value of that stud
		var type_drop = null
		var amount_drop = 0
		
		# Match the amount of money we have to the types of studs
#				if current_money >= 100000 and max_drop > 100000:
#					type_drop = "Pink"
#					amount_drop = 100000
#				elif current_money >= 10000 and max_drop > 10000:
		if coins >= 10000: # remove when pink gets added
			type_drop = "Purple"
			amount_drop = 10000
		elif coins >= 1000:
			type_drop = "Blue"
			amount_drop = 1000
		elif coins >= 100:
			type_drop = "Gold"
			amount_drop = 100
		elif coins >= 10:
			type_drop = "Silver"
			amount_drop = 10
		
		# If we have found a stud to drop
		if not type_drop == null:
			# add the amount we just dropped to the sum of what we have dropped
			coins -= amount_drop
			# drop the stud, based on what type the stud is
			drop_stud(type_drop)
	
	if turn_into_breakable:
		spawn_replacement()
		queue_free()


# Variables to control how high and far studs fly out when we drop them
var stud_spread = 2
var stud_max_height = 6.0
var stud_min_height = 1.0
var stud_spawn_range = .1

func drop_stud(type):
	# Get a reference to the stud in memory
	var sTUD_pICKUP = l.get_load("res://Objects/Stud.tscn")
	
	# Create a new stud
	var stud = sTUD_pICKUP.instantiate()
	# Add the stud to the scene
	get_parent().add_child(stud)
	# Set the type of the stud
	stud.set_type(type)
	
	stud.add_collision_exception_with(static_body)
	stud.add_collision_exception_with(character_body)
	
	# Randomize a y velocity value between the min and max stud velocity height
	var rand_vel_up = randf_range(stud_min_height, stud_max_height)
	# Randomize a variable for a direction the stud will
	# fly and normalize it to make it equal in all direcitons
	var rand_vel_top = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	# Multiply the directional velocity by the stud spread
	rand_vel_top = rand_vel_top*stud_spread
	
	# create a final variable combining all the random values
	var final_rand_vel = Vector3(rand_vel_top.x, rand_vel_up, rand_vel_top.y)
	
	# Set the studs velocity to that final variable
	stud.linear_velocity = final_rand_vel
	
	# Set the global position of the stud to our position, just a little higher
	stud.global_position = global_position+Vector3(0, 1, 0)+Vector3(rand_vel_top.x, 0, rand_vel_top.y)*stud_spawn_range


func spawn_replacement():
	var replacement = l.get_load("res://Objects/MoistureEvapourater.tscn").instantiate()
	
	replacement.position = position
	replacement.rotation = rotation
	replacement.scale = scale
	get_parent().add_child(replacement)


func bounce_obj(m):
	bouncing[m.name] = {"og_pos" : m.position, "time" : 0}

func stop_bounce(m):
	m.position = bouncing[m.name].og_pos
	bouncing.erase(m.name)


var build_speed = 5
func advance_to_final(m, delta):
	
	if b_pos.has(m.name):
		
		var jump_from = m.get_meta("pos_from")
		var jump_to = b_pos.get(m.name).pos
		
		var timer = m.get_meta("progress") + delta * build_speed
		timer = clamp(timer, 0.0, 1.0)
		m.set_meta("progress", timer)
		
		var height = 1#jump_from.distance_to(jump_to)/2.5
		
		m.position = f.LerpVector3(jump_from, jump_to, timer)
		
		m.position.y = lerp(jump_from.y, jump_to.y, timer) + (sin(timer*PI)*height)
		
		m.rotation = f.LerpAngleVector3(m.rotation, b_pos.get(m.name).rot, timer)
		m.scale = f.LerpVector3(m.scale, b_pos.get(m.name).sca, timer)
		
		if timer == 1.0:
			snap_to_final(m)
			advancing.erase(m)
			obj_left.remove_at(0)


func get_distance_to_final(m):
	if b_pos.has(m.name):
		return m.position.distance_to(b_pos.get(m.name).pos)
	return null


func snap_to_final(m):
	if b_pos.has(m.name):
		m.position = b_pos.get(m.name).pos
		m.rotation = b_pos.get(m.name).rot
		m.scale = b_pos.get(m.name).sca


func snap_all_to_final():
	for m in get_children():
		if m is MeshInstance3D:
			snap_to_final(m)


func advance_next():
	if not obj_left.is_empty():
		var next_obj = get_node(obj_left[0])
		if not advancing.has(next_obj):
			start_advancing(next_obj)


func start_advancing(m):
	if bouncing.has(m.name):
		stop_bounce(m)
	
	m.set_meta("pos_from", m.position)
	m.set_meta("progress", 0.0)
	advancing.append(m)


func get_pos():
	var b = get_parent().get_node("Breakables/BreakableObject")
	var final_dict = {}
	for m in b.get_children():
		if m is MeshInstance3D:
			var m_name = m.name
			var m_pos = {"pos" : m.position, "rot" : m.rotation, "sca" : m.scale}
			final_dict[m_name] = m_pos
