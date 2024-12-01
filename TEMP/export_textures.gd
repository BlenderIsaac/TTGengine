extends Node


func _process(_delta):
	if Input.is_action_just_pressed("e"):
		var img:Image = $SubViewportContainer/SubViewport.get_viewport().get_texture().get_image()
		img.save_png(SETTINGS.mod_path+"/Ahsoka Show/characters/textures/body.png")
