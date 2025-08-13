extends Node
class_name ApplicationManager

var savePath = "user://saves/"
var currentSaveSlot = -1
var currentGameManager = null

func _ready():
	print("Starting Application Manager")
	LoadSaveSlot(0)

func LoadSaveSlot(index):
	print("Loading save slot " + str(index))
	## Load here
	SpawnGameManager()

func SpawnGameManager():
	if currentGameManager != null:
		currentGameManager.queue_free()
		currentGameManager = null
	
	currentGameManager = GameManager.new()
	add_child(currentGameManager)


func SaveSaveSlot(_index):
	pass
