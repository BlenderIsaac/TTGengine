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
	"LevelState" : LevelState.UNLOCKED,#LOCKED,
	"MinikitsFound" : "0000000000",
	"ModeState" : ModeState.NORMAL,
	"StoryModeStudGoal" : false,
	"FreeplayStudGoal" : false,
	"RedBrickCollected" : false,
	
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
					"MinikitsFound" : "0000000000",
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
					"MinikitsFound" : "0000000000",
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

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game("test")

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


func load_mod_game(save_name, mod):
	pass

func save_mod_game(save_name):
	pass
