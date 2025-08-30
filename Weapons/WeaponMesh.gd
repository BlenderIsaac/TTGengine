extends BoneAttachment3D
class_name WeaponMesh

var mesh_node : Node3D
var animation_player : AnimationPlayer
var important_positions = {}



class LoadDetails:
	var dir : ResourceManager.LoadDir
	var file : String
	var ext : String
	var bone : int
	var important_positions := {}
	var materials := []
	
	func gen():
		var weapon_mesh = WeaponMesh.new()
		
		weapon_mesh.bone_idx = bone
		weapon_mesh.important_positions = important_positions
		
		var mesh : Node3D
		
		match ext:
			"obj":
				mesh = ResourceManager.load_obj(dir, file + "." + ext)
			"glb":
				mesh = ResourceManager.load_gltf(ResourceManager.GltfLoadDetails.new(dir, file))
				if mesh.has_node("AnimationPlayer"):
					weapon_mesh.animation_player = mesh.get_node("AnimationPlayer")
		
		weapon_mesh.add_child(mesh)
		weapon_mesh.mesh_node = mesh
		
		return weapon_mesh
