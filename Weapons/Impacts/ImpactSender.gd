class_name ImpactSender

var creator
var intermidiary

var iframes : float
var damage : float
var simple_knockback := Vector3()
var knockback := Vector3()
var explosion_knockback := 0.0
var type : String

func _init(data):
	damage = float(data[0])


func send_to(reciever : ImpactReciever):
	reciever.recieve_from(self)


func get_origin():
	if intermidiary:
		return intermidiary
	
	if creator:
		return creator
	
	return null


func get_knockback(obj_pos):
	var accum := Vector3()
	
	var knockback_relativiser : Node3D = get_origin()
	if knockback_relativiser:
		accum += knockback_relativiser.basis * simple_knockback
		
		accum += (obj_pos - knockback_relativiser.global_position).normalized() * explosion_knockback
	
	return accum


func copy():
	var sender = ImpactSender.new([damage])
	
	sender.iframes = iframes
	sender.damage = damage
	sender.knockback = knockback
	sender.simple_knockback = simple_knockback
	sender.explosion_knockback = explosion_knockback
	sender.type = type
	
	sender.creator = creator
	sender.intermidiary = intermidiary
	
	return sender
