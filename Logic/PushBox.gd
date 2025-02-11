extends "res://Logic/LOGIC.gd"

# Logic Type: Interaction
# Contains: Pushing boxes

var box_push_speed = 2.0
var valid_logics = ["Base", "PushBox"]

#var push_vel = 0.1

func inclusive_physics(_delta):
	
	current_box = null
	#var pushed = false
	
	if C.is_on_floor() and valid_logics.has(C.movement_state):
		if !C.AI:
			for i in range(C.get_slide_collision_count()):
				var collision = C.get_slide_collision(i)
				var normal = collision.get_normal(0)
				var collider = collision.get_collider(0)
				
				if collider:
					if collider.is_in_group("Pushable"):
						
						#var direction = "none"
						
						DebugDraw2D.set_text("normal"+str(i), normal)#.draw_arrow(C.position, C.position+normal)
						
						#match normal:
							#Vector3(0, 0, 1):
								#direction = "north"
							#Vector3(0, 0, -1):
								#direction = "south"
							#Vector3(1, 0, 0):
								#direction = "west"
							#Vector3(-1, 0, 0):
								#direction = "east"
						
						var norm2d = f.to_vec2(normal).normalized()
						var norm3d = Vector3(norm2d.x, 0, norm2d.y)
						
						if norm2d != Vector2():#!direction == "none":
							#push_vel = lerp(push_vel, 1.0, _delta)
							#pushed = true
							var vel = -norm3d*box_push_speed/collider.get_meta("weight")
							collider.velocity.x = vel.x#*push_vel
							collider.velocity.z = vel.z#*push_vel
							
							current_box = collider
							push_normal = norm3d
							
							if !C.movement_state == "PushBox":
								C.set_movement_state("PushBox")
	
	#if !C.AI:print(pushed)
	#if pushed == false:
		#push_vel = 0.1


func initiate():
	C.weapon_prefix = ""
	#push_vel = 0.1


var current_box = null
var push_normal = Vector3()
func exclusive_physics(_delta):
	
	if current_box == null:
		end()
	else:
		var move_dir = C.get_move_dir()
		C.velocity = -push_normal*box_push_speed*current_box.get_meta("weight")*5#*push_vel
		C.move_and_slide()
		
		anim.play("Pushloop", 0.1)
		
		C.mesh_angle_to = Basis.looking_at(push_normal).get_euler().y + PI
		C.mesh_angle_lerp(_delta, 0.3)
		
		var rot_to = Basis.looking_at(push_normal).get_euler().y + PI
		var move_to = null#Basis.looking_at(move_dir).get_euler().y
		
		if move_dir != Vector3():
			move_to = Basis.looking_at(move_dir).get_euler().y
		
		if move_to:
			var angle_diff = angle_difference(rot_to, move_to)
			
			if abs(angle_diff) >= PI/2:
				end()
		else:
			end()

func end():
	C.reset_movement_state()
	anim.play("Idleloop", .1)
