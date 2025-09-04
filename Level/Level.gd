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

var party = []
var freeplay_characters_details = []

func _init(_load_command : LevelManager.LevelLoadCommand):
	load_data = _load_command

func _ready():
	section_generator = SectionGeneratorTTGL.new()
	load_level_data()
	
	# generate party members
	for party_member in level_data.Party:
		var details = ResourceManager.TTGCCharFolderCharacterLoadDetails.new(party_member)
		details.load_details()
		var c : Character = details.gen()
		c.will_respawn = true
		party.append(c)
	
	emit_signal("party_created", party)
	
	if load_data.section_override:
		load_section(load_data.section_override)
	else:
		load_section(level_data.StartSection)


func load_level_data():
	level_data = ResourceManager.load_level_json(load_data.level)

func load_section(section_name : String):
	emit_signal("exiting_section")
	if current_section:
		# extract party members
		for party_member in party:
			party_member.section = null
			current_section.remove_child(party_member)
		
		current_section.queue_free()
	
	var load_command = SectionLoadCommand.new(section_name, load_data.level)
	current_section = section_generator.generate(load_command)
	
	# inject party members
	for party_member in party:
		party_member.section = current_section
		party_member.position = current_section.player_starting_positions[0] #TODO techincally we need to average from 1 to 2
		current_section.add_child(party_member)
	
	emit_signal("entering_section")
	add_child(current_section)
	emit_signal("entered_section")

class SectionLoadCommand:
	var mod_override : String
	var level : String
	var section : String
	
	func _init(_section : String, _level : String):
		section = _section
		level = _level
