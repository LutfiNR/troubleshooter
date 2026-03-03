extends Node2D
class_name Cable

signal plug_state_changed(is_plugged: bool)

@onready var sprite: Sprite2D = $Cable

var initial_position: Vector2
var port_position: Vector2 = Vector2(self.global_position.x, self.global_position.y - 80) 
var drag_offset: Vector2 = Vector2.ZERO

var is_dragging: bool = false
var is_inside_port: bool = false
var is_plugged: DeviceState.NetworkConnection


func _ready() -> void:
	initial_position = global_position


func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset


# ----------------------------
# INPUT
# ----------------------------
func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_stop_drag()


func _start_drag() -> void:
	is_dragging = true
	drag_offset = global_position - get_global_mouse_position()
	scale = Vector2(3.2, 3.2)


func _stop_drag() -> void:
	is_dragging = false
	scale = Vector2(3, 3)

	if is_inside_port:
		plug_in()
	else:
		unplug()


# ----------------------------
# PLUG LOGIC
# ----------------------------
func plug_in() -> void:
	global_position = port_position
	_set_plug_state(DeviceState.NetworkConnection.PLUGGED_IN)


func unplug() -> void:
	global_position = initial_position
	_set_plug_state(DeviceState.NetworkConnection.UNPLUGGED)


func _set_plug_state(value: DeviceState.NetworkConnection) -> void:
	if is_plugged == value:
		return
		
	is_plugged = value
	plug_state_changed.emit(is_plugged)


# ----------------------------
# PORT DETECTION
# ----------------------------
func _on_area_2d_area_entered(_area: Area2D) -> void:
	is_inside_port = true
	sprite.frame = 1


func _on_area_2d_area_exited(_area: Area2D) -> void:
	is_inside_port = false
	sprite.frame = 0
