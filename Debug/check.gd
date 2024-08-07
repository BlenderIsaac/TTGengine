extends Node3D

var lightsaber_history = []
var light_steps = 3

func _process(delta):
	lightsaber_tick()


func lightsaber_tick():
	
	var debug = $Sprite3D
	
	var skele = get_node("Mesh/Armature/Skeleton3D")
	var rot = skele.get_bone_global_pose(19).basis
	var pose = skele.get_bone_global_pose(19)
	
	debug.global_position = pose.origin# + (Vector3(0, 1, 0))
	debug.global_transform.basis = rot
	
	var debug2 = $Sprite3D2
	
	debug2.global_position = $BoneAttachment3D.global_position
	debug2.global_rotation = $BoneAttachment3D.global_rotation
	
	#debug.global_position = Basis.looking_at(rot).get_euler()
	#debug.global_position = Vector3(0, 1, 0) * rot
	
	
#	var ls_node = TrailParent
#	#debug.global_position = ls_node.get_node("End").global_position
#	lightsaber_history.append(
#			{
#			"Start" = ls_node.get_node("Start").global_position, 
#			"End" = ls_node.get_node("End").global_position
#			}
#		)
#
#	lightsaber_history.reverse()
#
#	var index = 0
#	var st = SurfaceTool.new()
#	st.begin(Mesh.PRIMITIVE_TRIANGLES)
#	for saber_tri in lightsaber_history:
#
#
#		if not index == 0:
#
#			var tri_data = []
#			tri_data.append_array([saber_tri.Start, saber_tri.End, lightsaber_history[index-1].End]) # Triangle 1
#			tri_data.append_array([saber_tri.Start, lightsaber_history[index-1].End, lightsaber_history[index-1].Start]) # Triangle 2
#
#			var x_pos2 = ((index-1)/float(light_steps))
#			var x_pos1 = (((index-1)/float(light_steps))+1.0/float(light_steps))
#
#			var uv_data = [
#				Vector2(x_pos1, 1), Vector2(x_pos1, 0), Vector2(x_pos2, 0),
#				Vector2(x_pos1, 1), Vector2(x_pos2, 0), Vector2(x_pos2, 1),
#			]
#
#			var tri_index = 0
#			for tri in tri_data:
#				st.set_uv(uv_data[tri_index])
#				st.add_vertex(tri)
#				tri_index += 1
#
#		var m = TrailParent.get_node("SaberSwipe")
#		m.mesh = st.commit()
#
#		index += 1
#
#	lightsaber_history.reverse()
#
#	while lightsaber_history.size() > light_steps:
#		lightsaber_history.remove_at(0)
