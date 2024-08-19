extends Node3D


func _ready():
	var mod = "Ahsoka Show"
	var export_path = SETTINGS.mod_path+"/"+mod+"/characters/anims/astromech/"
	
	#var special_folder = ""#"hello"
	#
	#if special_folder != "":
		#export_path += special_folder + "/"
	
	var glb_path = "res://Animations/AstromechRig.glb"
	
	f.make(glb_path, Vector3(), self)
	
	for anim_name in get_child(0).get_node("AnimationPlayer").get_animation_list():
		var anim_path = export_path + anim_name + ".res"
		print("exported ", anim_name, " to ", glb_path)
		export_anim(anim_name, anim_path)


func export_anim(anim, path):
	var an# = AnimationPlayer.new()
	an = get_child(0).get_node("AnimationPlayer")
	
	ResourceSaver.save(an.get_animation(anim), path)
