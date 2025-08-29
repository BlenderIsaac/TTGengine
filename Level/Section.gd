extends Node3D
class_name Section

var doors = []
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

func _ready():
	await get_tree().create_timer(0.15).timeout
	transition_pause = false

@warning_ignore("unused_parameter")
func i_am_dead(object):
	pass
