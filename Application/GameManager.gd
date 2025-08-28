extends Node
class_name GameManager

var current_mod : String
var current_party : Array
var level_manager : LevelManager
var interface : Interface
var current_players : Array
var current_player_controllers : Array

func _ready():
	print("Starting Game Manager")
	name = "Game Manager"
	
	spawn_level_manager()
	spawn_interface()
	
	set_mod("Ahsoka Show")
	var c = ResourceManager.CharFolderCharacterLoadDetails.new("Bob")
	c.load_details()
	#print(c.animations.Idleloop.file)
	#breakpoint
	
	interface.load_screen(Interface.MAIN_MENU)


func spawn_level_manager():
	level_manager = LevelManager.new()
	add_child(level_manager)


func spawn_interface():
	interface = Interface.new()
	interface.connect("choose_level", level_manager.load_level)
	interface.connect("choose_mod", set_mod)
	interface.game_manager = self
	add_child(interface)


func set_mod(new_mod):
	current_mod = new_mod
	ResourceManager.current_mod = current_mod
