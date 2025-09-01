extends BoneAttachment3D
class_name WeaponEffect

var weapon : Weapon

var triggering := false

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
