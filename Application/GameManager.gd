extends Node
class_name GameManager

var currentMod : String
var currentParty : Array
var levelManager : LevelManager
var interface : Interface
var currentPlayers : Array
var resourceManager : ResourceManager

func _ready():
	print("Starting Game Manager")
	name = "Game Manager"
	
	
	SpawnLevelManager()
	SpawnInterface()
	
	interface.load_screen(Interface.MAIN_MENU)

func SpawnInterface():
	print("Spawning Interface")
	if interface != null:
		interface.queue_free()
		interface = null
	
	interface = Interface.new()
	interface.game_manager = self
	add_child(interface)

func SpawnLevelManager():
	if levelManager != null:
		levelManager.queue_free()
		levelManager = null
	
	levelManager = LevelManager.new()
	add_child(levelManager)
