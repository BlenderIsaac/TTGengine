extends WeaponEffect
class_name WeaponMesh

var mesh_node : Node3D
var animation_player : AnimationPlayer


class LoadDetails extends WeaponEffect.LoadDetails:
	var model : ResourceManager.ModelLoadDetails
	var materials := []
	
	func gen2():
		var weapon_mesh = WeaponMesh.new()
		
		var mesh = model.gen()
		
		weapon_mesh.add_child(mesh)
		weapon_mesh.mesh_node = mesh
		
		return weapon_mesh
