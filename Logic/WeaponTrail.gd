extends "res://Logic/LOGIC.gd"

# Logic Type: Weapon Trail
# Contains: A configurable weapon trail


var sword_slash_start = Vector3(0, .485, 0)
var sword_slash_end = Vector3(0, 1.894, 0)
var sword_slash_texture_path = "LightsaberTrailGreen.png"
var sword_slash_material = "SwipeTrailBase.tres"

var lightsaber_history = []
var light_steps = 3

var our_prefix = "Sword"

var only_trail_on_anims = []

var trail_bone = 19

var TrailParent


func _process(_delta):
	
	if C.dead:
		TrailParent.get_node("SaberSwipe").hide()
	else:
		TrailParent.get_node("SaberSwipe").show()
	
	if !only_trail_on_anims == []:
		if !anim.current_animation in only_trail_on_anims:
			lightsaber_history = []
			#TrailParent.get_node("SaberSwipe").hide()


func _ready():
	spawn_objects()
	
	var swipe_path = SETTINGS.mod_path+"/"+C.origin_mod+"/characters/materials/"+sword_slash_material
	var swipe_matte = l.get_load(swipe_path)
	swipe_matte = swipe_matte.duplicate()
	TrailParent.get_node("SaberSwipe").material_override = swipe_matte
	
	var texture_path = SETTINGS.mod_path+"/"+C.origin_mod+"/characters/textures/"+sword_slash_texture_path
	
	swipe_matte.albedo_texture = MATERIALS.load_texture(texture_path)
	
	TrailParent.get_node("End").position = sword_slash_end
	TrailParent.get_node("Start").position = sword_slash_start


func spawn_objects():
	
	TrailParent = BoneAttachment3D.new()
	
	var EndNode = Node3D.new()
	var StartNode = Node3D.new()
	
	var MeshInstance = MeshInstance3D.new()
	
	TrailParent.add_child(EndNode)
	TrailParent.add_child(StartNode)
	TrailParent.add_child(MeshInstance)
	MeshInstance.top_level = true
	
	EndNode.name = "End"
	StartNode.name = "Start"
	MeshInstance.name = "SaberSwipe"
	
	get_node("../../Mesh/Armature/Skeleton3D").add_child(TrailParent)
	
	MeshInstance.global_position = Vector3()
	MeshInstance.global_rotation = Vector3()
	
	TrailParent.bone_idx = trail_bone


func reset():
	TrailParent.free()

func inclusive_process(_delta):
	lightsaber()

func lightsaber():
	if C.weapon_prefix == our_prefix:
		lightsaber_tick()
	else:
		lightsaber_history.clear()
		TrailParent.get_node("SaberSwipe").mesh = null

func lightsaber_tick():
	
	var ls_node = TrailParent
	#debug.global_position = ls_node.get_node("End").global_position
	lightsaber_history.append(
			{
			"Start" = ls_node.get_node("Start").global_position, 
			"End" = ls_node.get_node("End").global_position
			}
		)
	
	lightsaber_history.reverse()
	
	var index = 0
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for saber_tri in lightsaber_history:
		
		
		if not index == 0:
			
			var tri_data = []
			tri_data.append_array([saber_tri.Start, saber_tri.End, lightsaber_history[index-1].End]) # Triangle 1
			tri_data.append_array([saber_tri.Start, lightsaber_history[index-1].End, lightsaber_history[index-1].Start]) # Triangle 2
			
			var x_pos2 = ((index-1)/float(light_steps))
			var x_pos1 = (((index-1)/float(light_steps))+1.0/float(light_steps))
			
			var uv_data = [
				Vector2(x_pos1, 1), Vector2(x_pos1, 0), Vector2(x_pos2, 0),
				Vector2(x_pos1, 1), Vector2(x_pos2, 0), Vector2(x_pos2, 1),
			]
			
			var tri_index = 0
			for tri in tri_data:
				st.set_uv(uv_data[tri_index])
				st.add_vertex(tri)
				tri_index += 1
		
		var m = TrailParent.get_node("SaberSwipe")
		m.mesh = st.commit()
		
		index += 1
	
	lightsaber_history.reverse()
	
	while lightsaber_history.size() > light_steps:
		lightsaber_history.remove_at(0)
