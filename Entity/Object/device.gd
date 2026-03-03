class_name Device
extends Node2D

@export var detection_area: Area2D
@export var interaction_area: Area2D
@export var sprite: Sprite2D 
@export var action_popup: VBoxContainer
@onready var physical_scene: PackedScene

var player_in_range: bool = false
var _power_state: DeviceState.Power = DeviceState.Power.OFF
var _opacity_tween: Tween

# ========================
# Public API
# ========================

func interact() -> void:
	if not player_in_range:
		return
	
	if action_popup:
		if action_popup.is_open():
			await action_popup.close()
		else:
			await action_popup.open()


# ========================
# State Handling
# ========================

func _update_visual_state() -> void:
	if sprite:
		sprite.frame = _get_frame_for_state()


func _get_frame_for_state() -> int:
	var is_on := _power_state == DeviceState.Power.ON
	
	if player_in_range:
		return 3 if is_on else 1
	else:
		return 2 if is_on else 0


func turn_on_device() -> void:
	_power_state = DeviceState.Power.ON
	_update_visual_state()
	

func turn_off_device() -> void:
	_power_state = DeviceState.Power.OFF
	_update_visual_state()


func _on_power_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		turn_on_device()
	else:
		turn_off_device()


# ========================
# Detection Logic
# ========================

func _on_detect_area_body_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	
	player_in_range = true
	_update_visual_state()


func _on_detect_area_body_exited(body: Node2D) -> void:
	if not _is_player(body):
		return
	
	player_in_range = false
	_update_visual_state()

	if action_popup and action_popup.is_open():
		await action_popup.close()


func _is_player(body: Node) -> bool:
	return body.name == "Player"


# ========================
# Interaction Input
# ========================

func _on_interact_area_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if not _can_interact(event):
		return

	if ClickResolver.is_topmost(interaction_area):
		interact()


func _can_interact(event: InputEvent) -> bool:
	return player_in_range and event.is_action_pressed("click_left")


# ========================
# Utility
# ========================

func tween_opacity(object: CanvasItem, to: float) -> Tween:
	if _opacity_tween:
		_opacity_tween.kill()

	_opacity_tween = get_tree().create_tween()
	_opacity_tween.tween_property(object, "modulate:a", to, 0.2)
	return _opacity_tween


func _on_desktop_button_pressed() -> void:
	pass # Replace with function body.


func _on_network_button_pressed() -> void:
	if physical_scene:
		OverlayManager.open_overlay(physical_scene, self)
