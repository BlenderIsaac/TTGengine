extends Node
class_name LevelManager

var current_level : Level
var level_generator : LevelGenerator


func _ready():
	name = "Level Manager"
	level_generator = LevelGeneratorTTGL.new()

func load_level(load_command):
	print("Loading level...")
	print("Level Load Command:")
	print(load_command)
	if current_level != null:
		current_level.queue_free()
		current_level = null
	
	var full_load_command = load_command.duplicate()
	
	if !full_load_command.section:
		full_load_command.section = ResourceManager.load_level_json(full_load_command.level).StartSection
	
	current_level = level_generator.generate(full_load_command)
	add_child(current_level)


class LevelLoadCommand:
	
	enum {
		STORY,
		FREEPLAY,
		SUPERFREEPLAY,
		HUB,
	}
	
	var mode = STORY
	var mod = null
	var level = null
	var section = null
	
	func _to_string() -> String:
		return "From Mod {0}, loads {1} in section {2} in mode {3}".format([mod, level, section, mode])
	
	func duplicate():
		var new_load_command = LevelLoadCommand.new()
		new_load_command.mode = mode
		new_load_command.mod = mod
		new_load_command.level = level
		new_load_command.section = section
		return new_load_command
