extends Line2D

@export var device_a: StaticBody2D
@export var device_b: StaticBody2D

var cable_data: CableData

func _ready()-> void:
	EventManager.cable_updated.connect(_on_cable_updated)
	var cables_data = GameManager.get_cables_for_device(device_a.device_data) 
	for cable in cables_data:
		if cable.device_a == device_a.device_id and cable.device_b == device_b.device_id:
			cable_data = cable
	_update_visual()

func _on_cable_updated(_cable_id: String, _cable_data: CableData) -> void:
	cable_data = _cable_data
	_update_visual()

func _update_visual()-> void:
	if not device_a or not device_b:
		return
	points = [device_a.global_position, device_b.global_position]
