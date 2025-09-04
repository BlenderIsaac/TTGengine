extends BoneAttachment3D
class_name WeaponEffect

var weapon : Weapon
var active : bool = false

var triggering := false

func _ready():
	if not active:
		hide()
	weapon.connect("set_visible", update_visibility)

func update_visibility(value):
	visible = value

func trigger(_target):
	pass

class LoadDetails:
	var bone : int
	
	func gen2():
		return WeaponEffect.new()
	
	func gen():
		var effect = gen2()
		effect.bone_idx = bone
		return effect
