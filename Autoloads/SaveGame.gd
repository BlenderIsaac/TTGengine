extends Node

var encrypt_key = "abc123"
var encrypted = false
var ext = ".txt"

var saves_path = "user://"

enum LevelState {LOCKED, UNLOCKED}
enum ModeState {NORMAL, UNLOCKED_FREEPLAY, UNLOCKED_SUPER_FREEPLAY}

enum CharacterState {LOCKED, UNLOCKED, BOUGHT}
enum RedBrickState {NOT_BOUGHT, BOUGHT}

var generic_level = {
	"LevelState" : LevelState.LOCKED,
	"ModeState" : ModeState.NORMAL,
	"StoryModeStudGoal" : false,
	"FreeplayStudGoal" : false,
	"RedBrickCollected" : false,
	"MinikitsFound" : [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	
	"StoryModeTime" : -1,
	"FreeplayTime" : -1,
	"SuperFreeplayTime" : -1,
}

var save_data = {
	"ModData" : {
		"Ahsoka Show" : {
			"LevelData" : {
				"EscapeOnArcana" : {
					"LevelState" : LevelState.UNLOCKED,
					"MinikitsFound" : [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
					"ModeState" : ModeState.UNLOCKED_FREEPLAY,
					"StoryModeStudGoal" : false,
					"FreeplayStudGoal" : false,
					"RedBrickCollected" : false,
					
					"StoryModeTime" : 60,
					"FreeplayTime" : -1,
					"SuperFreeplayTime" : -1,
				},
				"RescueTheWitch" : {
					"LevelState" : LevelState.LOCKED,
					"MinikitsFound" : [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
					"ModeState" : ModeState.NORMAL,
					"StoryModeStudGoal" : true,
					"FreeplayStudGoal" : true,
					"RedBrickCollected" : true,
					
					"StoryModeTime" : -1,
					"FreeplayTime" : -1,
					"SuperFreeplayTime" : -1,
				}
			}
		}
	}
}

"""
What we need to save
- Settings
	- Screen settings
	- Visual settings
	- Music settings
	- Control Presets data
- Last Loaded Save Game

- Save Game data
	- Last loaded Mod
	- Last 2 played characters
	- Mod data
		- Time played
		- Stud count
		- Level data
			- Level State [Locked, Unlocked]
			- Minikits found 0000000000 based on how many minkits there are
			
			- Mode State [Base (Storymode), Unlocked Freeplay, Unlocked Super Freeplay]
			
			- Story Mode True Jedi achieved
			- Freeplay True Jedi achieved
			- Super Freeplay True Jedi achieved (not required to 100% the game)
			
			- Red Brick collected
			
			- Fastest time (Storymode)
			- Fastest time (Freeplay)
			- Fastest time (Super Freeplay)
		- Character data
			- State [Locked, Unlocked, Bought]
		- Red Brick data
			- State [Not Bought, Bought]

"""

var mod_when_last_opened:String = ""

func _ready():
	load_game("test")
	load_mod_game("test", "Ahsoka Show")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game("test")
		save_mod_game("test", "Ahsoka Show")

func open_save_file(file_name, mode_flags:FileAccess.ModeFlags):
	if !FileAccess.file_exists(saves_path+file_name) and mode_flags == FileAccess.READ: 
		return null
	
	var game:FileAccess
	if encrypted:
		game = FileAccess.open_encrypted_with_pass(saves_path+file_name, mode_flags, encrypt_key)
	else:
		game = FileAccess.open(saves_path+file_name, mode_flags)
	
	return game

func load_settings():
	pass

func save_settings():
	pass

func load_game(save_name):
	var save = open_save_file(save_name+ext, FileAccess.READ)
	
	if !save:
		return
	
	# this is player save specific stuff
	# load what mod we are in
	mod_when_last_opened = save.get_line()
	
	save.close()

func save_game(save_name):
	var save = open_save_file(save_name+ext, FileAccess.WRITE)
	
	# this is player save specific stuff
	# store what mod we are in
	save.store_line(Levels.level_state.Mod)
	
	save.close()

func encode_level_data(level_data):
	var encode_string = ""
	encode_string += str(level_data.LevelState)
	encode_string += str(level_data.ModeState)
	encode_string += str(int(level_data.StoryModeStudGoal))
	encode_string += str(int(level_data.FreeplayStudGoal))
	encode_string += str(int(level_data.RedBrickCollected))
	
	for m in level_data.MinikitsFound:
		encode_string += str(m)
	
	encode_string += str(level_data.StoryModeTime)+"T"
	encode_string += str(level_data.FreeplayTime)+"T"
	encode_string += str(level_data.SuperFreeplayTime)
	
	return encode_string

func decode_level_data(encode_string:String):
	var level_data = generic_level.duplicate(true)
	
	level_data.LevelState = int(encode_string[0])
	level_data.ModeState = int(encode_string[1])
	level_data.StoryModeStudGoal = bool(int(encode_string[2]))
	level_data.FreeplayStudGoal = bool(int(encode_string[3]))
	level_data.RedBrickCollected = bool(int(encode_string[4]))
	
	for i in range(0, 10):
		level_data.MinikitsFound[i] = int(encode_string[5+i])
	
	var splits = encode_string.substr(15).split("T")
	
	level_data.StoryModeTime = int(splits[0])
	level_data.FreeplayTime = int(splits[1])
	level_data.SuperFreeplayTime = int(splits[2])
	
	return level_data

func load_mod_game(save_name, mod):
	var save:FileAccess = open_save_file(save_name+"_mod_"+mod+ext, FileAccess.READ)
	if save:
		var LevelData = {}
		
		while !save.eof_reached():
			var n = save.get_line()
			var d = save.get_line()
			if n != "":
				LevelData[n] = decode_level_data(d)
		
		save_data.ModData.get(mod).LevelData = LevelData
		
		save.close()

func save_mod_game(save_name, mod):
	var save = open_save_file(save_name+"_mod_"+mod+ext, FileAccess.WRITE)
	var LevelData = save_data.ModData.get(mod).LevelData
	
	for level_name in LevelData.keys():
		var dictionary = LevelData[level_name]
		
		save.store_line(level_name)
		save.store_line(encode_level_data(dictionary))
	
	save.close()

func _process(_delta):
	
	if Input.is_action_just_pressed("ui_home"):
		var capture = get_viewport().get_texture().get_image()
		
		var _time = Time.get_datetime_string_from_system()
		
		var filename = "user://Screenshot-{0}.png".format({"0":randi()})
		
		capture.save_png(filename)
