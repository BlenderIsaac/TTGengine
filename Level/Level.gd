extends Node
class_name Level

signal party_created(new_party : Array)
signal exiting_section
signal entering_section
signal entered_section

var section_generator : SectionGenerator
var current_section : Section
var load_data : LevelManager.LevelLoadCommand
var level_data : Dictionary
var player_money_data = {}

var mode := LevelMode.STORY

enum LevelMode {
	STORY,
	FREEPLAY,
	SUPERFREEPLAY,
	HUB,
}

var party = []
var freeplay_characters_details = [
	ResourceManager.TTGCCharFolderCharacterLoadDetails.new("Stormtrooper"),
	ResourceManager.TTGCCharFolderCharacterLoadDetails.new("JediBob"),
]

func _init(_load_command : LevelManager.LevelLoadCommand):
	load_data = _load_command

func _ready():
	section_generator = SectionGeneratorTTGL.new()
	load_level_data()
	
	generate_party()
	
	if load_data.section_override:
		load_section(load_data.section_override)
	else:
		load_section(level_data.StartSection)

func load_level_data():
	level_data = ResourceManager.load_level_json(load_data.level)

func load_section(section_name : String, door_id = -1):
	await get_tree().process_frame
	
	emit_signal("exiting_section")
	if current_section:
		# extract party members
		for party_member in party:
			party_member.section = null
			current_section.remove_child(party_member)
		
		current_section.queue_free()
		current_section = null
	
	var load_command = SectionLoadCommand.new(section_name, load_data.level)
	current_section = section_generator.generate(load_command)
	current_section.door_entered = door_id
	current_section.level = self
	
	if door_id == -1:
		current_section.switch_game_cam_to(section_generator.begin_cam_transform)
	else:
		current_section.switch_game_cam_to(current_section.doors[door_id].cam_transform)
	
	# inject party members
	var idx = 0
	for party_member in party:
		party_member.section = current_section
		party_member.position = current_section.get_starting_position(idx, len(party))
		
		current_section.add_child(party_member)
		idx += 1
	
	emit_signal("entering_section")
	add_child(current_section)
	
	emit_signal("entered_section")

func generate_party():
	match mode:
		LevelMode.STORY:
			for party_member in level_data.Party:
				create_party_character(ResourceManager.TTGCCharFolderCharacterLoadDetails.new(party_member))
		LevelMode.FREEPLAY:
			for i in range(4):
				var c = create_party_character(freeplay_characters_details[i % len(freeplay_characters_details)])
				c.freeplay_char_idx = i
	
	emit_signal("party_created", party)

func create_party_character(details):
	details.load_details()
	var c : Character = details.gen()
	c.will_respawn = true
	party.append(c)
	return c

class SectionLoadCommand:
	var mod_override : String
	var level : String
	var section : String
	
	func _init(_section : String, _level : String):
		section = _section
		level = _level
