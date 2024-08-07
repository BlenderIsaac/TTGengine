extends Node


var stored_audio = {}


func get_stream(path):
	if !stored_audio.has(path):
		stored_audio[path] = load_stream(path)
	
	return stored_audio.get(path)


func load_stream(path):
	if !SETTINGS.mobile:
		var audLoad = AudioLoader.new()
		var stream = audLoad.loadfile(path)
		
		return stream
	else:
		var stream = load(path)
		return stream
