extends Node3D
class_name AudioPlayer

@export var universal = false

var sound_effects = {}
var currently_looping_sounds = []
var currently_playing_sounds = []

var disposed = false

func _process(_delta):
	
	for child in get_children():
		if !child.playing:
			
			for sound in currently_playing_sounds:
				if sound[2] == child:
					currently_playing_sounds.erase(sound)
			
			child.queue_free()
	
	if !get_children().size() > 0 and disposed:
		queue_free()


func dispose(parent_to):
	get_parent().remove_child(self)
	parent_to.add_child(self)
	
	disposed = true


func play(title, config={}):
	
	if sound_effects.has(title):
		
		var paths = sound_effects.get(title)
		
		if paths.size() > 0:
			var sound_num = randi_range(0, paths.size()-1)
			var new_sfx
			if universal:
				new_sfx = AudioStreamPlayer.new()
			else:
				new_sfx = AudioStreamPlayer3D.new()
			var stream = ResourceManager.load_sound(paths[sound_num])
			
			new_sfx.pitch_scale = randf_range(0.95, 1.05)
			
			add_child(new_sfx)
			
			for c in config.keys():
				new_sfx.set(c, config.get(c))
			
			new_sfx.stream = stream
			
			new_sfx.play()
			
			currently_playing_sounds.append([title, config, new_sfx])
	else:
		print("Missing sound effect: ", title)


func is_playing(title, config={}):
	for sound in currently_playing_sounds:
		if sound[0] == title and sound[1] == config:
			return true
	return false


func start_loop(title, config={}):
	if sound_effects.has(title):
		
		var paths = sound_effects.get(title)
		
		if paths.size() > 0:
			var new_sfx
			if universal:
				new_sfx = AudioStreamPlayer.new()
			else:
				new_sfx = AudioStreamPlayer3D.new()
			var stream = ResourceManager.load_sound(paths[0])
			
			add_child(new_sfx)
			
			for c in config.keys():
				new_sfx.set(c, config.get(c))
			
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			new_sfx.stream = stream
			
			new_sfx.play()
			
			currently_looping_sounds.append([title, config, new_sfx])
	else:
		print("Missing sound loop: ", title)


func end_loop(title, config={}):
	for loop in currently_looping_sounds:
		if loop[0] == title and loop[1] == config:
			loop[2].stop()
			currently_looping_sounds.erase(loop)
			break


func has_loop(title, config={}):
	for loop in currently_looping_sounds:
		if loop[0] == title and loop[1] == config:
			return true
	return false


func clear_loops():
	
	for loop in currently_looping_sounds.duplicate():
		
		end_loop(loop[0], loop[1])


func clear():
	sound_effects = {}


func set_sound(sound_name, paths):
	sound_effects[sound_name] = paths


func add_library(library):
	var dupe = library.duplicate()
	for sound_name in dupe.keys():
		set_sound(sound_name, dupe.get(sound_name))
