extends Node
class_name LevelManager

var current_level : Level
var level_generator : SectionGenerator

var game_manager : GameManager

signal level_loading

func _ready():
	print("Level Manager created!")
	name = "Level Manager"
	print("Creating player characters to exist in memory")


func load_level(load_command):
	print("Loading level...")
	emit_signal("level_loading")
	print("Level Load Command:")
	print(load_command)
	if current_level != null:
		current_level.queue_free()
		current_level = null
	
	current_level = Level.new(load_command)
	current_level.mode = load_command.mode
	current_level.connect("party_created", game_manager.assign_party)
	add_child(current_level)


class LevelLoadCommand:
	
	var mode = Level.LevelMode.STORY
	var mod = null
	var level = null
	var section_override = null
	
	func _to_string() -> String:
		return "From Mod {0}, loads {1} in section {2} in mode {3}".format([mod, level, section_override, mode])
