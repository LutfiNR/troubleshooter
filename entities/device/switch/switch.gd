extends StaticBody2D
class_name SwitchDevice

const FRAME_OFF_IDLE = 0
const FRAME_OFF_HOVER = 1
const FRAME_ON_IDLE = 2
const FRAME_ON_HOVER = 3

@export var device_id: String
@export var sprite: Sprite2D 
@export var action_popup: VBoxContainer
@export var physical_scene: PackedScene
@export var desktop_scene: PackedScene

var player_in_range: bool = false
var device_data: SwitchDeviceData

func _ready() -> void:
	EventManager.device_updated.connect(_on_device_updated)
	device_data = GameManager.get_runtime_device_data_by_id(device_id)

func interact() -> void:
	if not player_in_range: return
		
	if action_popup:
		if action_popup.is_open():
			await action_popup.close()
		else:
			await action_popup.open()

func _update_visual() -> void:
	if device_data == null or sprite == null: return 
	
	var is_on = (device_data.power == DeviceData.PowerState.ON)
	
	if player_in_range:
		sprite.frame = FRAME_ON_HOVER if is_on else FRAME_OFF_HOVER
	else:
		sprite.frame = FRAME_ON_IDLE if is_on else FRAME_OFF_IDLE

func _on_device_updated(updated_device_id: String, _device_data: DeviceData) -> void:
	if updated_device_id == device_id:
		device_data = _device_data
		_update_visual()

func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true
		_update_visual()

func _on_detect_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		_update_visual()
		if action_popup and action_popup.is_open():
			await action_popup.close()

func _on_interact_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if player_in_range and event.is_action_pressed("click_left"):
		interact()

func _on_power_button_toggled(_toggled_on: bool) -> void:
	if device_data.power == DeviceData.PowerState.OFF:
		device_data.power = DeviceData.PowerState.ON
	else:
		device_data.power = DeviceData.PowerState.OFF
	GameManager.update_device_data(device_id, device_data)

func _on_physical_button_pressed() -> void:
	OverlaySystem.open_overlay(physical_scene, device_id)
