extends BoneAttachment3D
class_name WeaponMesh

var mesh_node : Node3D
var animation_player : AnimationPlayer


class LoadDetails:
	var model : ResourceManager.ModelLoadDetails
	var bone : int
	var materials := []
	
	func gen():
		var weapon_mesh = WeaponMesh.new()
		
		weapon_mesh.bone_idx = bone
		
		var mesh = model.gen()
		
		weapon_mesh.add_child(mesh)
		weapon_mesh.mesh_node = mesh
		
		return weapon_mesh
