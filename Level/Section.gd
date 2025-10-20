extends Node3D
class_name Section

var level : Level

var doors = {}
var collectables = []
var level_script
var ai_manager
var raw_section_data

var camera : Camera3D
var environment : WorldEnvironment
var sun : DirectionalLight3D

var death_height : float

var player_starting_positions = []

var transition_pause = true

var door_entered = -1

func _ready():
	await get_tree().create_timer(0.15).timeout
	transition_pause = false

func get_starting_position(player_idx, player_count):
	if door_entered == -1:
		return get_position_between(player_starting_positions[0], player_starting_positions[1], player_idx, player_count)
	else:
		return get_position_between(doors[door_entered].spawn_positions[0], doors[door_entered].spawn_positions[0], player_idx, player_count)

func get_position_between(pos1, pos2, idx, count):
	if count == 0:
		return pos1
	elif count == 1:
		return (pos1 + pos2) / 2.0
	else:
		return lerp(pos1, pos2, float(idx) / float(count - 1))

func switch_game_cam_to(trans : Transform3D):
	if camera:
		camera.queue_free()
	
	camera = ResourceManager.create_scene("Level/GameCam", Vector3(), self)
	camera.begin_transform_override = true
	camera.transform = trans
	camera.get_node("Collision").position = trans.origin
	camera.current = true

@warning_ignore("unused_parameter")
func i_am_dead(object):
	pass
