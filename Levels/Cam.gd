extends Camera3D

@export var move_type = "Curves"

var targets = []
var closest_point

@export var distance = Vector3(0, 4, 6)#Vector3(0, 8, 12)#

@export var follow_path = false
var cam_path = null

var current_path_pos = 0.0

var curve_path_offsets = []
var y_dir = 0.0

var initial_snap = false

var start_timer = 0

var movement_to = 0.0
var movement_at = 0.0

var begin_transform_delay = 0.0
var begin_transform_override = false:
	set(value):
		begin_transform_override = value
		begin_transform_delay = 1.0

@onready var target_agent = $NavigationAgent3D

func _process(_delta):
	
	movement_at = lerp(movement_at, movement_to, _delta)
	
	if start_timer == 1:
		if begin_transform_override == false:
			target_agent.target_position = Vector3(get_special_avg_pos())
			snap()
	
	if begin_transform_override:
		if begin_transform_delay > 0:
			begin_transform_delay -= _delta
	
	if move_type == "Curves" and targets.size() > 0:
		
		var pos = get_special_avg_pos()
		var avg = get_target_avg_pos()
		
		if !follow_path:
			
			var new_transform = global_transform.looking_at(avg, Vector3.UP)
			global_transform = global_transform.interpolate_with(new_transform, 4 * _delta)
			
			var pos_to = distance+pos
			
			global_position.x = lerp(global_position.x, pos_to.x, 0.05*_delta*60)
			global_position.y = lerp(global_position.y, pos_to.y, 0.05*_delta*60)
			global_position.z = lerp(global_position.z, pos_to.z, 0.05*_delta*60)
		
		elif follow_path:
			
			if get_tree().get_nodes_in_group("CAMCURVE").size() == 0:
				follow_path = false
			else:
				# Final camera position
				var camera_pos = Vector3()
				var second_pos = Vector3()
				#var camera_rot = Vector3()
				
				# The closest position in each curve
				var closest_positions = []
				
				var offset_positions = []
				#var curve_rotations = []
				
				# The total distance to each closest position added up
				var total_distance = 0.0
				
				var power = 3.0
				
				for path_index in get_tree().get_nodes_in_group("CAMCURVE").size():
					
					var path = get_tree().get_nodes_in_group("CAMCURVE")[path_index]
					
					# The vec3 point closest to our characters avg pos
					var offset = path.curve.get_closest_offset(pos)
					
					if curve_path_offsets.size() != get_tree().get_nodes_in_group("CAMCURVE").size():
						curve_path_offsets.append(offset)
					
					curve_path_offsets[path_index] = move_toward(curve_path_offsets[path_index], offset, _delta*7)
					
					var point = path.curve.sample_baked(curve_path_offsets[path_index])
					var offset_point = path.curve.sample_baked(curve_path_offsets[path_index]+4.0)
					
					var dist = point.distance_to(pos)
					
					total_distance += pow(dist, power)
					
					closest_positions.append(point)
					offset_positions.append(offset_point)
					#curve_rotations.append(path.curve.sample_baked_with_rotation(offset).basis)
				
				#var total_weight = 0
				
				if closest_positions.size() > 1:
					for curve_index in closest_positions.size():
						
						var curve_pos = closest_positions[curve_index]
						
						var curve_dist = pow(curve_pos.distance_to(pos), power)
						
						var weight = ((total_distance-curve_dist)/total_distance)#/(closest_positions.size()-1)
						
						#total_weight += weight
						
						camera_pos += curve_pos * weight
						
						second_pos += offset_positions[curve_index] * weight
						
				else:
					camera_pos = closest_positions[0]
					second_pos = offset_positions[0]
				
				
				
				global_position = second_pos#f.LerpVector3(global_position, second_pos, _delta*60*0.5)#second_pos#camera_pos + Vector3(0, 0, 3).rotated(Vector3.UP, y_dir)
				
				$Debug.position = camera_pos
				$Debug2.position = second_pos
				
				var new_transform = global_transform.looking_at(avg, Vector3.UP)
				global_transform = global_transform.interpolate_with(new_transform, 4 * _delta)
	
	elif move_type == "Navigation" and targets.size() > 0 and begin_transform_delay <= 0:
		var avg = get_target_avg_pos()
		var pos = get_special_avg_pos()
		
		#var vec2_dist = f.to_vec2(global_position).distance_to(f.to_vec2(pos))
		var final_vec2_dist = f.to_vec2(global_position).distance_to(f.to_vec2(target_agent.get_final_position()))
		
		target_agent.target_position = Vector3(pos)
		
		var min_dist = 5.0
		#var pushaway_dist = 2.0
		
		#if final_vec2_dist < pushaway_dist:
			#target_agent.target_position = Vector3(pos) + Vector3(0.0, 0, 0).rotated(Vector3.UP, rotation.z)
			#min_dist = pushaway_dist
		
		if final_vec2_dist > min_dist:
			
			var next_pos = target_agent.get_next_path_position() + Vector3(0, -0.3, 0)
			
			if final_vec2_dist > 0.2:
				movement_to = 1.0
				var speed = (final_vec2_dist-min_dist)
				global_position += (next_pos-global_position).normalized()*minf(speed/30, 3.0)*movement_at
			else:
				movement_to = 0.0
		#elif final_vec2_dist < 3.0:
			#var next_pos = target_agent.get_next_path_position() + Vector3(0, -0.3, 0)
			#
			#if final_vec2_dist > 0.2:
				#
				#var speed = (final_vec2_dist-3.0)
				#global_position += (next_pos-global_position).normalized()*minf(speed/30, 3.0)
		
		
		rotation.z = 0
		if f.to_vec2(global_position-avg) == Vector2():
			rotation.x = -PI/2
			rotation.y = 0
		else:
			
			var new_transform = global_transform.looking_at(avg, Vector3.UP)
			global_transform = global_transform.interpolate_with(new_transform, 2 * _delta)
	
	
	start_timer += 1


func snap():
	
	var target_average = get_special_avg_pos()
	
	global_position = (target_agent.get_final_position() + Vector3(0, -0.3, 0))+Vector3(0.01, 0, 0)
	
	if f.to_vec2(global_position-target_average) == Vector2():
		rotation.x = -PI/2
		rotation.y = 0
	else:
		look_at(target_average)


func get_special_avg_pos():
	if targets.size() > 0:
		
		# get average of target position
		var target_pos = Vector3()
		
		
		if targets.size() > 1:
			var total_distance = 0
			
			for target in targets:
				var target_dist = (target.global_transform.origin+target.aim_pos).distance_to(global_position)
				
				total_distance += target_dist
			
			for target in targets:
				var target_dist = (target.global_transform.origin+target.aim_pos).distance_to(global_position)
				
				target_pos += (target.global_transform.origin + target.aim_pos) * (total_distance-target_dist)/total_distance
		else:
			target_pos = targets[0].global_transform.origin+targets[0].aim_pos
		
		
		return target_pos
	else:
		return Vector3()


func get_target_avg_pos():
	if targets.size() > 0:
		
		# get average of target position
		var target_average = Vector3()
		for target in targets:
			
			target_average += target.global_transform.origin+target.aim_pos
		
		target_average = target_average/targets.size()
		
		return target_average
	else:
		return Vector3()
