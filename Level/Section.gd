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
