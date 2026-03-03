extends Device
class_name PC

@onready var pc_physical_scene: PackedScene = preload("res://Entity/Object/PC/pcphysical.tscn")

var _network_connection_state : DeviceState.NetworkConnection = DeviceState.NetworkConnection.UNPLUGGED

func _ready() -> void:
	physical_scene = pc_physical_scene

func set_network_connection_state(value: DeviceState.NetworkConnection) -> void:
	if _network_connection_state == value:
		return
		
	_network_connection_state = value
	print("PC Network State:", _network_connection_state)

func get_network_connection() -> DeviceState.NetworkConnection:
	return _network_connection_state
