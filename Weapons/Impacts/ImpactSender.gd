class_name ImpactSender

var creator
var intermidiary

var iframes : float
var damage : float
var simple_knockback : float
var knockback : Vector3
var knockback_local_transform := true
var type : String

func _init(data):
	damage = float(data[0])
	
	if data.size() > 1:
		simple_knockback = float(data[1])


func send_to(reciever : ImpactReciever):
	reciever.recieve_from(self)


func get_origin():
	if intermidiary:
		return intermidiary
	
	if creator:
		return creator
	
	return null


func get_knockback():
	var knockback_relativiser : Node3D = get_origin()
	
	if !knockback_relativiser:
		return knockback
	
	var full_simple_knockback = knockback_relativiser.basis * Vector3(0, 0, -simple_knockback)
	if knockback_local_transform:
		return (knockback_relativiser.basis * knockback) + full_simple_knockback
	else:
		return knockback + full_simple_knockback


func copy():
	var sender = ImpactSender.new([damage])
	
	sender.iframes = iframes
	sender.damage = damage
	sender.knockback = knockback
	sender.simple_knockback = simple_knockback
	sender.knockback_local_transform = knockback_local_transform
	sender.type = type
	
	sender.creator = creator
	sender.intermidiary = intermidiary
	
	return sender
