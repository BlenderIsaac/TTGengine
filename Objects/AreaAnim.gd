extends "res://Scripts/TriggerAnim.gd"

func extends_ready():
	connect("body_entered", character_enter)
	connect("body_exited", character_exit)
	
	self.collision_mask = 3
	add_to_group("AnimArea")


func is_triggering():
	var valid_in_area = []
	for character in in_area:
		
		if f.is_character_valid(character):
			valid_in_area.append(character)
		else:
			if !f.does_character_exist(character):
				valid_in_area.erase(character)
	
	return !valid_in_area.is_empty()


var in_area = []
func character_enter(character):
	if character.is_in_group("Character"):
		in_area.append(character)


func character_exit(character):
	if character.is_in_group("Character"):
		if in_area.has(character):
			in_area.erase(character)
