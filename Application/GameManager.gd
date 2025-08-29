extends Node
class_name GameManager

var current_mod : String
var current_party : Array
var level_manager : LevelManager
var interface : Interface
var players : Array = []

func _ready():
	print("Starting Game Manager")
	name = "Game Manager"
	
	# spawn basic player
	var player = Player.new()
	add_child(player)
	players.append(player)
	
	spawn_level_manager()
	spawn_interface()
	
	interface.load_screen(Interface.MAIN_MENU)


func party_created(new_party):
	while len(players) > len(new_party):
		var removed_player = players.pop_back()
		removed_player.delete()
	
	for i in range(len(players)):
		players[i].controlling = new_party[i]


func spawn_level_manager():
	level_manager = LevelManager.new()
	level_manager.game_manager = self
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
