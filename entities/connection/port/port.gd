extends Node2D
class_name Port

const FRAME_DOWN = 0
const FRAME_UP = 1

@onready var sprite: Sprite2D = $Sprite
@onready var area: Area2D = $Area

var device_id: String
var id: String 
var connected_cable: CableNode = null

func _ready() -> void:
	if area:
		area.set_meta("port", self)

func is_occupied() -> bool:
	return connected_cable != null
	
func update_visual(interface: NetworkInterface, device_power_state: DeviceData.PowerState) -> void:
	if sprite == null or interface == null:
		return
	var is_active = interface.is_up() and device_power_state == DeviceData.PowerState.ON
	sprite.frame = FRAME_UP if is_active else FRAME_DOWN
