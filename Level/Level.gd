extends Node
class_name Level

var section_generator : SectionGenerator
var current_section : Section
var load_data : LevelManager.LevelLoadCommand
var level_data : Dictionary

func _init(_load_command : LevelManager.LevelLoadCommand):
	load_data = _load_command

func _ready():
	section_generator = SectionGeneratorTTGL.new()
	load_level_data()
	
	if load_data.section_override:
		load_section(load_data.section_override)
	else:
		load_section(level_data.StartSection)

func load_level_data():
	level_data = ResourceManager.load_level_json(load_data.level)

func load_section(section_name : String):
	if current_section:
		current_section.queue_free()
	
	var load_command = SectionLoadCommand.new(section_name, load_data.level)
	
	current_section = section_generator.generate(load_command)
	add_child(current_section)

class SectionLoadCommand:
	var mod_override : String
	var level : String
	var section : String
	
	func _init(_section : String, _level : String):
		section = _section
		level = _level
