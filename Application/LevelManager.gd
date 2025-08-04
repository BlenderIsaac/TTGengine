extends Node
class_name LevelManager

var currentLevel : Level
#var gameManager : GameManager


func load_level(load_command):
	if currentLevel != null:
		currentLevel.queue_free()
		currentLevel = null
	
	currentLevel = Level.new()
	add_child(currentLevel)


class LevelLoadCommand:
	
	enum {
		STORY,
		FREEPLAY,
		SUPERFREEPLAY,
		HUB,
	}
	
	var mode = STORY
	var mod = null
	var level = null
	var section = null
