extends StaticBody2D

const FRAME_OFF_IDLE = 0
const FRAME_OFF_HOVER = 1
const FRAME_ON_IDLE = 2
const FRAME_ON_HOVER = 3

@export var device_id: String
@export var sprite: Sprite2D 
@export var action_popup: VBoxContainer
#@export var physical_scene: PackedScene
#@export var desktop_scene: PackedScene

var player_in_range: bool = false
var device: ComputerDevice

func _ready() -> void:
	NetworkManager.device_updated.connect(_on_device_updated)

func load_device_data() -> void:
	if device_id == "":
		push_error("[" + name + "] ID is empty!")
		return
	device = NetworkManager.get_device(device_id)
	if device:
		_update_visual()
	else:
		push_error("[" + name + "] Failed to load device with id: " + device_id)

func interact() -> void:
	if not player_in_range: return
		
	if action_popup:
		if action_popup.is_open():
			await action_popup.close()
		else:
			await action_popup.open()

func _update_visual() -> void:
	if device == null or sprite == null: return 
	
	var is_on = (device.power == NetworkDevice.PowerState.ON)
	if player_in_range:
		sprite.frame = FRAME_ON_HOVER if is_on else FRAME_OFF_HOVER
	else:
		sprite.frame = FRAME_ON_IDLE if is_on else FRAME_OFF_IDLE

func _on_device_updated(updated_device_id: String) -> void:
	if updated_device_id == device_id:
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
	if event.is_action_pressed("click_left"):
		if ItemPlacementSystem.selected_item:
			if ItemPlacementSystem.selected_item.name == "delete_item":
				ItemPlacementSystem.remove_device(self)
				return
			if ItemPlacementSystem.selected_item.name == "cable_item":
				return
		if player_in_range:
			interact()

func _on_power_button_pressed() -> void:
	NetworkManager.set_device_power(device_id)
