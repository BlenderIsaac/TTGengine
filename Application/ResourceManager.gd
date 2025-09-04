extends Node
class_name ResourceManagerClass

var loaded_resources : Dictionary = {}
var current_mod : String
var audio_loader : AudioLoader

func _ready():
	audio_loader = AudioLoader.new()

#region Load Dirs

class LoadDir:
	func get_dir():
		return ""

class ModFolderLoadDir extends LoadDir:
	var mod : String = ""
	
	func get_mod():
		if mod != "":
			return mod
		
		return ResourceManager.current_mod
	
	func get_dir():
		return super() + SettingsManager.mod_path + "/" + get_mod() + "/"


class ResLoadDir extends LoadDir:
	func get_dir():
		return "res://"


class LevelsFolderLoadDir extends ModFolderLoadDir:
	func get_dir():
		return super() + "levels/"

class LevelsSharedFolderLoadDir extends LevelsFolderLoadDir:
	func get_dir():
		return super() + "shared/"

class LevelFolderLoadDir extends LevelsFolderLoadDir:
	var level : String
	
	func _init(_level):
		level = _level
	
	func get_dir():
		return super() + "leveldata/" + level + "/"

class SectionFolderLoadDir extends LevelFolderLoadDir:
	var section : String
	
	func _init(_level, _section):
		super(_level)
		section = _section
	
	func get_dir():
		return super() + section + "/"

class CharactersFolderLoadDir extends ModFolderLoadDir:
	func get_dir():
		return super() + "characters/"

class CharFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "chars/"

class CharactersRigFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "rigs/"

class CharactersSoundFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "sounds/"

class CharactersCollisionsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "collisions/"

class CharactersModelsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "models/"

class CharactersGltfsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "gltfs/"

class CharactersTexturesFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "textures/"

class CharactersIconsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "icons/"

class CharactersAnimsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "anims/"

class CharactersMaterialsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "materials/"

class CharactersLogicsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "logics/"

#endregion
#region Textures

class TextureLoadDetails:
	var dir : LoadDir
	var file : String
	
	func _init(_dir : LoadDir, _file : String):
		dir = _dir
		file = _file
	
	func gen():
		return load(dir.get_dir() + file)

class LevelTextureLoadDetails extends TextureLoadDetails:
	func _init(_file, _level):
		dir = LevelFolderLoadDir.new(_level)
		file = _file

#endregion
#region Waveforms (.obj)

var obj_meshes = {}

func load_obj(path : LoadDir, file : String):
	var id = path.get_dir() + file
	if !obj_meshes.has(id):
		var new_obj = load(path.get_dir() + file + ".obj")
		
		obj_meshes[id] = new_obj
	
	return obj_meshes.get(id)

#endregion
#region Materials

class MaterialLoadDetails:
	var base_material := "basic"
	var color : Color = "ffffff"
	var preset_color : String
	var metallic_preset_color : String
	var emissive_color : String
	
	var texture : TextureLoadDetails
	var normal_texture : TextureLoadDetails
	
	# for LOAD materials
	var load_path : LoadDir
	var load_file : String
	
	func get_color():
		if metallic_preset_color:
			return ResourceManager.material_data[metallic_preset_color]
		
		if preset_color:
			return ResourceManager.material_data[preset_color]
		
		return color
	
	func get_common_elements():
		return {"m" : base_material, "c" : get_color()}
	
	func get_unique_id():
		var id = get_common_elements()
		
		if base_material in ["flash overlay"]:
			return base_material
		
		if base_material == "load":
			id["lp"] = load_path.get_dir()
			id["lf"] = load_file
		
		if emissive_color:
			id["ec"] = emissive_color
		
		if texture:
			id["t"] = texture
		
		if normal_texture:
			id["nt"] = texture
		
		return id
	
	func gen():
		if base_material == "load":
			return load(load_path.get_dir() + load_file)
		if base_material == "flash overlay":
			return ResourceManager.material_types[base_material].duplicate()
		
		var matte : StandardMaterial3D = ResourceManager.material_types[base_material].duplicate()
		matte.albedo_color = get_color()
		
		if Color(get_color()).a < 1.0:
			matte.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		if emissive_color:
			matte.emission_enabled = true
			matte.emission = emissive_color
		
		if texture:
			matte.albedo_texture = texture.gen()
		
		if normal_texture:
			matte.normal_enabled = true
			matte.normal_texture = normal_texture.gen()
		
		return matte

var material_loads = {}

var material_types = {
	"basic" : load("res://Materials/BasicTestMaterial.tres"),
	"rough" : load("res://Materials/RoughBasicMaterial.tres"),
	"metallic" : load("res://Materials/MetallicMaterial.tres"),
	"add" : load("res://Materials/UnshadedAddMaterial.tres"),
	"unshaded" : load("res://Materials/UnshadedMaterial.tres"),
	"tag particle" : load("res://Materials/TagParticle.tres"),
	"flash overlay" : load("res://Materials/FlashOverlay.tres"),
	"emission" : load("res://Materials/EmissionMaterial.tres")
}

func load_material(details : MaterialLoadDetails):
	var id = details.get_unique_id()
	if not id in material_loads:
		material_loads[id] = details.gen()
	
	return material_loads[id]

#endregion
#region Sounds

class SoundLoadDetails:
	var path : LoadDir
	var file : String
	
	var mod : String
	
	func _init(_path : LoadDir, _file : String):
		path = _path
		file = _file
	
	func get_unique_id():
		return path.get_dir() + file
	
	func gen():
		return ResourceManager.audio_loader.loadfile(path.get_dir() + file)


var sound_loads = {}
func load_sound(details : SoundLoadDetails):
	var id = details.get_unique_id()
	if not id in sound_loads:
		sound_loads[id] = details.gen()
	
	return sound_loads[id]


#endregion
#region Characters

class CharacterLoadDetails:
	
	var name : String
	
	var identity# : Character.CharacterIdentity
	var alignment# : Character.CharacterAlignment
	
	var health : int
	var ai_health : int
	
	var sounds = {}
	var animations = {}
	var attachments = []
	
	var materials = {}
	var rig_class : String
	var rig : CharacterRigLoadDetails
	
	var logics = {}
	var base_logic : String
	
	var weapons = {}# Dictionary of Character.Weapon
	
	var collision : ColLoadDetails
	
	var icon_details : TextureLoadDetails
	
	func gen():# -> Character:
		# create a new character
		var character = ResourceManager.load_scene("Character/Character").instantiate()
		
		gen_to(character)
		
		return character
	
	func gen_to(character : Character):
		character.emit_signal("pre_switch")
		
		character.details = self
		
		#character.identity = identity
		#character.alignment = alignment
		
		var impact_reciever = ImpactReciever.new()
		impact_reciever.host = character
		character.impact_reciever = impact_reciever
		
		for logic in character.logics:
			logic.queue_free()
		character.logics.clear()
		for logic_name in logics.keys():
			var char_logic = logics[logic_name]
			character.logics[logic_name] = char_logic
			char_logic.C = character
			character.get_node("Logics").add_child(char_logic)
			
			if char_logic.has_method("adapt_sender"):
				impact_reciever.modifiers.append(char_logic)
		character.base_logic = character.logics[base_logic]
		
		for weapon in character.weapons:
			weapon.queue_free()
		character.weapons.clear()
		for weapon_name in weapons.keys():
			var weapon = weapons[weapon_name].gen()
			
			weapon.name = weapon_name
			weapon.C = character
			
			character.weapons[weapon_name] = weapon
			character.get_node("Weapons").add_child(weapon)
			
			if weapon.has_method("adapt_sender"):
				impact_reciever.modifiers.append(weapon)
		
		character.max_hit_points = health
		character.ai_hit_points = ai_health
		
		character.nav_agent = character.get_node("Agent")
		character.modulate_anim = character.get_node("Modulation")
		character.audio = character.get_node("AudioPlayer")
		character.tail = character.get_node("Tail")
		character.tailcast = character.get_node("TailCast")
		character.pushaway_collision = character.get_node("Pushaway")
		
		var library = {}
		for sound_name in sounds.keys():
			library[sound_name] = sounds[sound_name].gen()
		
		character.audio.clear()
		character.audio.add_library(library)
		
		# Give it the flash material as an overlay
		var flash_overlay_details = ResourceManager.MaterialLoadDetails.new()
		flash_overlay_details.base_material = "flash overlay"
		character.flash_material = ResourceManager.load_material(flash_overlay_details).duplicate()
		
		if icon_details:character.icon = icon_details.gen()
		
		assert(rig != null, "There is no rig for this character")
		character.meshes_to_modulate.clear()
		character.bits.clear()
		if character.rig:character.rig.queue_free()
		var rig_gen = rig.gen()
		character.add_child(rig_gen)
		character.set_mesh(rig_gen)
		character.rig_class = rig_class
		
		assert(collision != null, "There is no collision for this character")
		if character.collision:character.collision.queue_free()
		var col_gen = collision.gen()
		character.collision = col_gen
		character.add_child(col_gen)
		character.tailcast.shape = col_gen.shape
		character.tailcast.position = col_gen.position
		
		var p_col_gen = collision.gen_expanded()
		character.get_node("Pushaway").add_child(p_col_gen)
		
		for key in materials.keys():
			var part : MeshInstance3D = character.skeleton.get_node(key)
			for i in range(len(materials[key])):
				part.set_surface_override_material(i, materials[key][i].gen())
		
		character.anim.root_motion_track = "Armature/Skeleton3D:Parent"
		character.anim.remove_animation_library("")
		if animations:
			var anim_library = AnimationLibrary.new()
			for animation : AnimationLoadDetails in animations.values():
				anim_library.add_animation(animation.name, animation.gen())
			
			character.anim.add_animation_library("", anim_library)
		character.anim.set_process_callback(AnimationPlayer.ANIMATION_PROCESS_PHYSICS)
		
		for attachment in character.model_attachments:
			attachment.queue_free()
		character.model_attachments.clear()
		if attachments:
			for attachment in attachments:
				attachment.gen_on_character(character)
		
		character.current_weapon = null
		character.reset_logic()
		
		character.emit_signal("post_switch")

class TTGCCharacterLoadDetails extends CharacterLoadDetails:
	var path : LoadDir
	var file : String
	
	var custom_classes = {
			"anim" : TTGCAnimationLoadDetails,
			"rig" : TTGCCharacterRigLoadDetails,
			"box_col" : BoxColLoadDetails,
			"capsule_col" : CapsuleColLoadDetails,
			"matte" : TTGCMaterialLoadDetails,
			"sound" : TTGCSoundLoadDetails,
			"sounds" : TTGCSoundsLoadDetails,
			"tex" : TTGCTextureLoadDetails,
			"attachment" : TTGCBoneAttachmentLoadDetails,
			"model" : ModelLoadDetails,
			"weapon" : Weapon.LoadDetails,
			"weapon_mesh" : WeaponMesh.LoadDetails,
			"projectile_effect" : ProjectileDamageEffect.LoadDetails,
			"projectile" : Projectile.LoadDetails,
			"sender" : ImpactSender,
			"weapon_collider" : ColliderDamageEffect.LoadDetails,
		}
	enum {
		SELF,
		DICT,
		CLASS_DICT,
		ARRAY,
		STRING,
		INTEGER,
		FLOAT,
		BOOL,
		VECTOR2,
		VECTOR3,
		LOGIC,
		ANIM,
		SOUNDS,
		SOUND,
		MATTE,
		TEXTURE,
		NORMAL_TEXTURE,
		COMMAND,
		RIG,
		BOX_COL,
		CAPSULE_COL,
		PATH,
		ATTACHMENT,
		WEAPON,
		WEAPON_MESH,
		CUSTOM,
		MODEL,
		TIMED_SOUND_EFFECT,
		}
	var var_ids = {
		"d" : DICT,
		"cd" : CLASS_DICT,
		"a" : ARRAY,
		"s" : STRING,
		"i" : INTEGER,
		"f" : FLOAT,
		"b" : BOOL,
		"v2" : VECTOR2,
		"v3" : VECTOR3,
		"logic" : LOGIC,
		"c" : COMMAND,
		"path" : PATH,
		"tsfx" : TIMED_SOUND_EFFECT,
		}
	func id(split):
		if split == null:
			return SELF
		
		var _id = var_ids.get(split[0])
		
		if not _id:
			return CUSTOM
		
		return _id
	
	
	func _init(_path : LoadDir, _file : String):
		path = _path
		file = _file
	
	
	func load_details():
		update(file)
	 
	
	func update(c_name):
		
		var file_access = FileAccess.open(path.get_dir() + c_name + ".ttgc", FileAccess.READ)
		
		var obj_stack = []
		var data_stack = []
		while !file_access.eof_reached():
			var line = file_access.get_line()
			var trimmed = line.strip_edges()
			
			if trimmed.begins_with("#") or trimmed == "":
				continue
			
			var split = trimmed.split(" ")
			var indent = line.count("\t")
			
			while len(obj_stack) > 0 and indent < len(obj_stack):
				# pop last item of stack and apply it
				set_var_on_object(
					data_stack.pop_back(), 
					obj_stack.pop_back(),
					null if data_stack.is_empty() else data_stack.back(),
					self if obj_stack.is_empty() else obj_stack.back()
									)
			
			#debug print("\n", line)
			
			if id(split) == COMMAND:
				#debug printt("apply this command", split)
				apply_command(split)
			else:
				#if is_nester_object(split):
					if split[-1] == ">":
						var parent = self if obj_stack.is_empty() else obj_stack.back()
						var nester = parent.get(split[1])
						obj_stack.append(nester)
					else:
						var has_name = true if data_stack.is_empty() else id(data_stack.back()) not in [ARRAY, CLASS_DICT]
						var data_starts_at = 2 if has_name else 1
						obj_stack.append(get_value(split, data_starts_at))
					#debug print("this is a nester object, indent avaliable")
					data_stack.append(split)
				#else:
				#	var parent = obj_stack.back() if len(obj_stack) > 0 else self
				#	set_var_on_object(split, null, null if data_stack.is_empty() else data_stack.back(), parent)
		
		file_access.close()
		
		#debug print("\nobject stack ", obj_stack)
		while !obj_stack.is_empty():
			#debug print("final deindentation")
			set_var_on_object(
				data_stack.pop_back(), 
				obj_stack.pop_back(),
				null if data_stack.is_empty() else data_stack.back(),
				self if obj_stack.is_empty() else obj_stack.back()
								)
		
		#breakpoint
	
	
	func get_value(split, data_starts_at):
		match id(split):
			STRING:
				return str(" ".join(split.slice(data_starts_at)))
			INTEGER:
				return int(split[data_starts_at])
			FLOAT:
				return float(split[data_starts_at])
			BOOL:
				return str(split[data_starts_at]).to_lower() == "true"
			VECTOR2:
				return Vector2(
					float(split[0 + data_starts_at]),
					float(split[1 + data_starts_at])
					)
			VECTOR3:
				return Vector3(
					float(split[0 + data_starts_at]), 
					float(split[1 + data_starts_at]), 
					float(split[2 + data_starts_at])
					)
			DICT:
				return {}
			CLASS_DICT:
				return {}
			ARRAY:
				return []
			LOGIC:
				return TTGCLogicLoadDetails.new(split.slice(data_starts_at)).gen()
			PATH:
				return translate_path(split.slice(data_starts_at))
			WEAPON:
				return Weapon.LoadDetails.new()
			WEAPON_MESH:
				return WeaponMesh.LoadDetails.new()
			CUSTOM:
				return custom_classes[split[0]].new(split.slice(data_starts_at))
			TIMED_SOUND_EFFECT:
				return [str(split[data_starts_at]), float(split[data_starts_at + 1])]
			_:
				assert(false, "object " + str(split) + " is invalid")
		
		return null
	
	
	var path_translated = {
		"b" : LoadDir,
		"m" : ModFolderLoadDir,
		"s" : CharactersSoundFolderLoadDir,
		"a" : CharactersAnimsFolderLoadDir,
		"models" : CharactersModelsFolderLoadDir,
		"gltfs" : CharactersGltfsFolderLoadDir,
	}
	func translate_path(data):
		var p = path_translated[data[0]].new()
		return p
	
	
	func set_var_on_object(split, obj, parent_line, parent):
		if id(split) in [ARRAY, CLASS_DICT, DICT]:
			update_list(split, obj, parent_line, parent)
			return
		
		var parent_type = id(parent_line)
		
		if obj != null:
			match parent_type:
				ARRAY:
					parent.append(obj)
				CLASS_DICT:
					parent[obj.name] = obj
				_:
					parent[split[1]] = obj
			return
		
		var has_name = parent_type not in [ARRAY, CLASS_DICT]
		var data_starts_at = 2 if has_name else 1
		var value = get_value(split, data_starts_at)
		
		if value != null:
			if parent_type == ARRAY:
				parent.append(value)
			else:
				parent[split[1]] = value
			return
	
	
	func update_list(data, elements, parent_line, parent):
		# generate list if none exist
		if not data[1] in parent:
			var has_name = id(parent_line) not in [ARRAY, CLASS_DICT]
			var data_starts_at = 2 if has_name else 1
			
			parent[data[1]] = get_value(data, data_starts_at)
		
		var current = parent[data[1]]
		
		if len(data) < 3 or data[2] == "=":
			current.assign(elements)
			return
		
		var operation = data[2]
		
		match operation:
			">":
				return # changes have already been made
			"-":
				#debug print("erase elements ", elements, " from list ", current)
				erase_elements_from_list(elements, current)
			"+":
				#debug print("add elements ", elements, " to list ", current)
				add_elements_to_list(elements, current)
	
	
	func erase_elements_from_list(elements, list):
		if list is Dictionary:
			for element_name in elements.keys():
				list.erase(element_name)
		elif list is Array:
			for element_name in elements:
				list.erase(element_name)
	
	
	func add_elements_to_list(elements, list):
		if list is Dictionary:
			for element_name in elements.keys():
				list[element_name] = elements[element_name]
		elif list is Array:
			for element in elements:
				list.append(element)
	
	
	func apply_command(split):
		match split[1]:
			"copy":
				update(split[2])

class TTGCCharFolderCharacterLoadDetails extends TTGCCharacterLoadDetails:
	func _init(character_name):
		path = CharFolderLoadDir.new()
		file = character_name


class TTGCAnimationLoadDetails extends AnimationLoadDetails:
	func _init(data):
		name = data[0]
		file = data[0] if len(data) == 1 else data[1]
		path = CharactersAnimsFolderLoadDir.new()

class TTGCMaterialLoadDetails extends MaterialLoadDetails:
	func _init(data):
		if data.is_empty():
			return
		
		match data[0]:
			"preset":
				preset_color = data[1]
			"basic":
				color = data[1]
		
		if data.size() > 2:
			match data[2]:
				"emission":
					emissive_color = data[1]
					base_material = "emission"
				"metallic":
					base_material = "metallic"

class TTGCSoundLoadDetails extends SoundLoadDetails:
	func _init(data):
		file = data[0]
		path = CharactersSoundFolderLoadDir.new()

class TTGCSoundsLoadDetails extends SoundsLoadDetails:
	func _init(data):
		name = data[0]
		
		for sound in data.slice(1):
			sounds.append(TTGCSoundLoadDetails.new([sound]))

class TTGCTextureLoadDetails extends TextureLoadDetails:
	func _init(data):
		if len(data) > 1:
			match data[1]:
				"icon_folder":
					dir = CharactersIconsFolderLoadDir.new()
					file = data[0] + ".png"
		else:
			dir = CharactersTexturesFolderLoadDir.new()
			file = data[0]

class TTGCLogicLoadDetails extends LogicLoadDetails:
	func _init(data):
		var sc_name = data[0]
		var logic_name = null
		var has_custom_name = len(data) > 1
		if has_custom_name:
			logic_name = data[1]
		
		super(sc_name, logic_name)

class TTGCBoneAttachmentLoadDetails extends BoneAttachmentLoadDetails:
	func _init(data):
		model = ModelLoadDetails.new()
		
		model.file = data[0]
		model.ext = data[1]
		match data[1]:
			"glb":
				model.dir = CharactersGltfsFolderLoadDir.new()
			"obj":
				model.dir = CharactersModelsFolderLoadDir.new()

class TTGCCharacterRigLoadDetails extends CharacterRigLoadDetails:
	func _init(data):
		super(data[0])


class BoneAttachmentLoadDetails:
	var model : ModelLoadDetails
	var bone_attach : int
	
	func gen() -> BoneAttachment3D:
		var attachment = BoneAttachment3D.new()
		var mesh = model.gen()
		attachment.add_child(mesh)
		
		return attachment
	
	func gen_on_character(character : Character):
		var genned = gen()
		
		character.model_attachments.append(genned)
		character.skeleton.add_child(genned)
		character.bits.append_array(model.meshes.duplicate())
		character.meshes_to_modulate.append_array(model.meshes.duplicate())
		for mesh in model.meshes:
			mesh.material_overlay = character.flash_material
		
		genned.bone_idx = bone_attach

class SoundsLoadDetails:
	var sounds = []
	var name : String
	
	func gen():
		return sounds

class LogicLoadDetails:
	var name : String
	var script_name : String
	
	func _init(_script_name, _name = null):
		script_name = _script_name
		if _name != null:
			name = _name
		else:
			name = script_name
	
	func gen():
		var dir = ResLoadDir.new()
		var path = dir.get_dir() + "Logic/" + script_name + ".gd"
		var l = load(path).new()
		l.name = name
		return l

class AnimationLoadDetails:
	var speed : float = 1.0
	var key_frames := {}
	var sfx := []
	var path : LoadDir
	var file : String
	var name : String
	
	
	func sort_sfx(a, b):
		return a[1] < b[1]
	
	func gen():
		var anim : Animation = load(path.get_dir() + file + ".res")
		
		anim.set_meta("speed", speed)
		anim.set_meta("has_sfx", !sfx.is_empty())
		var sorted_sfx = sfx.duplicate()
		sorted_sfx.sort_custom(sort_sfx)
		if !sfx.is_empty():
			anim.set_meta("sfx", sorted_sfx)
		anim.set_meta("key_frames", key_frames)
		
		var track_idx = anim.add_track(Animation.TYPE_METHOD)
		anim.track_set_path(track_idx, NodePath(".."))
		anim.track_insert_key(track_idx, 0.0, {"method" : "anim_started", "args" : []})
		
		return anim



#endregion
#region GLTFs

var gltf_meshes = {}

func load_gltf(load_details : GltfLoadDetails):
	var id = load_details.dir.get_dir() + load_details.file + ".glb"
	if !gltf_meshes.has(id):
		var new_gltf = load_details.gen()
		
		gltf_meshes[id] = new_gltf
	
	return gltf_meshes.get(id)

class GltfLoadDetails:
	var dir : LoadDir
	var file : String
	
	func _init(_dir : LoadDir, _file : String):
		dir = _dir
		file = _file
	
	func get_path():
		return dir.get_dir() + file + ".glb"
	
	func gen():
		var gltf = GLTFDocument.new()
		var gltf_state = GLTFState.new()
		var path = get_path()
		var snd_file = FileAccess.open(path, FileAccess.READ)
		var fileBytes = PackedByteArray()
		fileBytes = snd_file.get_buffer(snd_file.get_length())
		
		gltf.append_from_buffer(fileBytes, "base_path?", gltf_state)
		var node = gltf.generate_scene(gltf_state)
		
		return node

class LevelGltfLoadDetails extends GltfLoadDetails:
	func _init(_level, _section):
		dir = SectionFolderLoadDir.new(_level, _section)
		file = _section

class CharacterRigLoadDetails extends GltfLoadDetails:
	func _init(rig_name : String):
		dir = CharactersRigFolderLoadDir.new()
		file = rig_name
	
	func gen():
		var rig = super()
		rig.name = "Mesh"
		return rig

#endregion
#region TTGLs

class TtglLoadDetails:
	var dir : SectionFolderLoadDir
	var path : String
	
	func _init(_level, _section):
		dir = SectionFolderLoadDir.new(_level, _section)
	
	func get_path():
		return dir.get_dir() + dir.section + ".ttgl"
	
	func gen():
		var file = FileAccess.get_file_as_string(get_path())
		return file.split("\n")

#endregion
#region RES:// loads
func load_file(path, extension):
	return load("res://" + path + "." + extension)

func load_scene(path):
	return load_file(path, "tscn")

func create_scene(path, position, parent):
	var scene = load_scene(path).instantiate()
	scene.position = position
	parent.add_child(scene)
	return scene

func load_script(path):
	return load_file(path, "gd")

func load_tres(path):
	return load_file(path, "tres")

#endregion
#region JSONs

func load_level_json(level):
	var path = LevelFolderLoadDir.new(level).get_dir() + level + ".json"
	var string = FileAccess.get_file_as_string(path)
	var json = JSON.parse_string(string)
	return json

#endregion
#region Collision

class ColLoadDetails:
	var offset := Vector3()
	var push_margin = 0.1
	
	func gen():
		var col = CollisionShape3D.new()
		col.name = "Collision"
		col.position = offset
		return col
	
	func gen_expanded():
		var col = CollisionShape3D.new()
		col.name = "PushawayCollision"
		col.position = offset
		return col

class BoxColLoadDetails extends ColLoadDetails:
	var size : Vector3
	
	func gen():
		var col = super()
		var shape = BoxShape3D.new()
		shape.size = size
		col.shape = shape
		return col
	
	func gen_expanded():
		var col = super()
		var shape = BoxShape3D.new()
		shape.size = size + push_margin
		col.shape = shape
		return col

class CapsuleColLoadDetails extends ColLoadDetails:
	var radius : float
	var height : float
	
	func gen():
		var col = super()
		var shape = CapsuleShape3D.new()
		shape.height = height
		shape.radius = radius
		col.shape = shape
		return col
	
	func gen_expanded():
		var col = super()
		var shape = CapsuleShape3D.new()
		shape.height = height + (push_margin * 2)
		shape.radius = radius + push_margin
		col.shape = shape
		return col

#endregion
#region Models

class ModelLoadDetails:
	var dir : LoadDir
	var file : String
	var ext : String
	var material_array := []
	var material_dict := {}
	var meshes = []
	
	func gen():
		var mesh : Node3D
		
		match ext:
			"obj":
				mesh = MeshInstance3D.new()
				var obj = ResourceManager.load_obj(dir, file)
				mesh.mesh = obj
				meshes.append(mesh)
				for i in range(len(material_array)):
					mesh.set_surface_override_material(i, material_array[i].gen())
			"glb":
				mesh = ResourceManager.load_gltf(ResourceManager.GltfLoadDetails.new(dir, file))
				for m in f.get_all_children(mesh):
					if m is MeshInstance3D:
						meshes.append(m)
						if str(mesh.name) in material_dict:
							for i in range(len(material_dict.get(str(mesh.name)))):
								mesh.set_surface_override_material(i, material_dict[mesh.name][i])
			_:
				assert(false, "support for a mesh of extension " + ext + " is not supported.")
		
		return mesh

#endregion

var material_data = {
	#basic colors
	"White":"F4F4F4",
	"VeryLightGray":"E8E8E8",
	"VeryLightGrey":"E8E8E8",
	"VeryLightBluishGray":"E4E5D9",
	"VeryLightBluishGrey":"E4E5D9",
	"LightBluishGray":"A3A2A4",
	"LightBluishGrey":"A3A2A4",
	"LightGray":"A1A5A2",
	"LightGrey":"A1A5A2",
	"DarkGray":"545955",
	"DarkGrey":"545955",
	"DarkBluishGray":"4D5156",
	"DarkBluishGrey":"4D5156",
	"Black":"101010",
	"DarkRed":"7C021F",
	"Red":"D6001E",
	"Coral":"FF6666",
	"Salmon":"F06D61",
	"LightSalmon":"F9B7A5",
	"SandRed":"88605E",
	"DarkBrown":"2E0F06",
	"Brown":"543324",
	"LightBrown":"7C503A",
	"MediumBrown":"755945",
	"ReddishBrown":"5B2D0E",
	"FabulandBrown":"B3694E",
	"DarkTan":"8A7553",
	"MediumTan":"CCA373",
	"Tan":"D5BC7C",
	"LightNougat":"FAD1B1",
	"Nougat":"D09168",
	"MediumNougat":"B17A49",
	"EarthOrange":"D86D2C",
	"DarkOrange":"91501C",
	"Rust":"B52C20",
	"Orange":"F57D23",
	"MediumOrange":"F58624",
	"BrightLightOrange":"FCB100",
	"LightOrange":"F9A777",
	"Yellow":"F8C718",
	"LightYellow":"FFE383",
	"BrightLightYellow":"FDF683",
	"NeonYellow":"E6FF00",
	"LightLime":"DEEA92",
	"YellowishGreen":"E0FC9A",
	"MediumLime":"B7D425",
	"Lime":"94BC0E",
	"OliveGreen":"808452",
	"DarkGreen":"053515",
	"Green":"157D26",
	"BrightGreen":"1B9822",
	"MediumGreen":"73DCA1",
	"LightGreen":"A5DBB5",
	"SandGreen":"618365",
	"DarkTurquoise":"069D9F",
	"LightTurquoise":"31B5CA",
	"Aqua":"9CD6CC",
	"LightAqua":"D5F2EA",
	"DarkBlue":"0A2441",
	"Blue":"2653A7",
	"DarkAzure":"078BC9",
	"MaerskBlue":"6BADD6",
	"MediumAzure":"2ACDE8",
	"SkyBlue":"77C9D8",
	"MediumBlue":"558AC5",
	"BrightLightBlue":"8FBFE9",
	"LightBlue":"7ED9F2",
	"SandBlue":"61738C",
	"DarkBlue-Violet":"0E3E9A",
	"Violet":"675BBF",
	"Blue-Violet":"506CEF",
	"MediumViolet":"9391E4",
	"LightViolet":"C1CADE",
	"DarkPurple":"491D8E",
	"Purple":"A5499C",
	"LightPurple":"B4348C",
	"MediumLavender":"A06AB9",
	"Lavender":"CDA1DE",
	"SandPurple":"845E84",
	"Magenta":"98006C",
	"DarkPink":"D82E8D",
	"MediumDarkPink":"F785B1",
	"BrightPink":"EA9BC4",
	"Pink":"FFC0CB",
	
	#not reall yreal ones
	"Flesh":"d09168",
	"LightFlesh":"fad1b1",
	"MediumFlesh":"CCA373",
	
	#metallic
	"ChromeGold":"DFC176",
	"ChromeSilver":"CECECE",
	"ChromeAntiqueBrass":"B8925C",
	"ChromeBlack":"1B2A34",
	"ChromeBlue":"6C96BF",
	"ChromeGreen":"3CB371",
	"ChromePink":"AA4D8E",
	"PearlWhite":"F6F3EC",
	"PearlVeryLightGray":"D4D2CD",
	"PearlVeryLightGrey":"D4D2CD",
	"PearlLightGray":"A0A0A0",
	"PearlLightGrey":"A0A0A0",
	"FlatSilver":"8E9496",
	"BionicleSilver":"A59287",
	"PearlDarkGray":"3E3C39",
	"PearlDarkGrey":"3E3C39",
	"PearlBlack":"282725",
	"PearlLightGold":"DEAC66",
	"PearlGold":"A68031",
	"ReddishGold":"E7891B",
	"BionicleGold":"B9752F",
	"FlatDarkGold":"83724F",
	"ReddishCopper":"D57036",
	"Copper":"AC6C53",
	"BionicleCopper":"985750",
	"PearlSandBlue":"5686AE",
	"PearlSandPurple":"B5A1BA",
	"MetallicSilver":"C0C0C0",
	"MetallicGreen":"899B5F",
	"MetallicGold":"BB9442",
	"MetallicCopper":"A77768",
	"MilkyWhite":"F4F4F4",
}

# idk what this is
var material_data2 = {
	"Light Flesh" : "fad1b1",
	"Medium Flesh" : "CCA373",
	"Medium Nougat" : "b17a49",
	"Bright Light Blue" : "8fbfe9",
	"Flesh" : "d09168",
	"White" : "f4f4f4",
	"Red" : "d6001e",
	"Dark Purple" : "5e2980",
	"Black" : "101010",
	"Dark Bluish Grey" : "4d5156",
	"Dark Red" : "7c021f",
	"Reddish Brown" : "581b0f",
	"Tan" : "d5bc7c",
	"Medium Blue" : "558ac5",
	"Light Bluish Grey" : "a3a2a4",
	"Sand Blue" : "61738c",
	"Sand Green" : "618365",
	"Orange" : "f57d23",
	"Blue" : "2653a7",
	"Dark Blue": "0a2441",
	"Yellow" : "f8c718",
	"Green" : "157D26",
	"Pink" : "ffc0cb",
	"Dark Tan" : "8A7553",
	"Dark Brown" : "2e0f06",
}
