extends Node2D
class_name CableNode

@onready var sprite: Sprite2D = $Sprite

const FRAME_PLUGGED: int = 1
const FRAME_UNPLUG: int = 0

var hovered_port: Port = null
var plugged_port: Port = null

var dragged_sprite_scale: float = 2.2
var initial_position: Vector2
var drag_offset: Vector2 = Vector2.ZERO

var _is_dragging: bool = false
var _is_plugged_in: bool = false

var is_dragging: bool:
	set(value):
		_is_dragging = value
		_on_drag_state_changed()
	get:
		return _is_dragging

var is_plugged_in: bool:
	set(value):
		_is_plugged_in = value
		_update_visual()
	get:
		return _is_plugged_in

func _ready() -> void:
	if is_plugged_in:
		initial_position = global_position + Vector2(0, 46)
	else:
		initial_position = global_position
	_update_visual()

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset

# --- DRAG LOGIC ---
func _start_drag() -> void:
	if plugged_port and plugged_port.connected_cable == self:
		plugged_port.connected_cable = null
		NetworkDeviceManager.set_interface_state(plugged_port.device_id, plugged_port.id, false)
	
	plugged_port = null
	is_plugged_in = false
	is_dragging = true
	drag_offset = global_position - get_global_mouse_position()

func _stop_drag() -> void:
	is_dragging = false
	modulate = Color(1, 1, 1)

	if hovered_port:
		_plug_into(hovered_port)
	else:
		_unplug()

func _on_drag_state_changed() -> void:
	scale = Vector2(dragged_sprite_scale, dragged_sprite_scale) if _is_dragging else Vector2(2, 2)

# --- LOGIC COLOK/CABUT ---
func _plug_into(target_port: Port) -> void:
	if target_port.is_occupied():
		print_debug("Port sudah terisi!")
		_unplug()
		return
	
	plugged_port = target_port
	is_plugged_in = true
	target_port.connected_cable = self
	global_position = target_port.global_position
	
	NetworkDeviceManager.set_interface_state(target_port.device_id, target_port.id, true)

func _unplug() -> void:
	if plugged_port and plugged_port.connected_cable == self:
		plugged_port.connected_cable = null
		NetworkDeviceManager.set_interface_state(plugged_port.device_id, plugged_port.id, false)
	
	plugged_port = null
	is_plugged_in = false
	global_position = initial_position

# --- FUNGSI UNTUK INIT UI DARI MANAGER ---
func force_state_from_data(target_port: Port, is_up: bool) -> void:
	if is_up and target_port:
		plugged_port = target_port
		target_port.connected_cable = self
		is_plugged_in = true
		global_position = target_port.global_position
	else:
		plugged_port = null
		if target_port and target_port.connected_cable == self:
			target_port.connected_cable = null
		is_plugged_in = false
		global_position = initial_position

# --- VISUAL ---
func _update_visual() -> void:
	if sprite:
		sprite.frame = FRAME_PLUGGED if _is_plugged_in else FRAME_UNPLUG

# --- INPUT HANDLING ---
func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()

# Ini yang bikin kabel ngga nempel terus!
func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			get_viewport().set_input_as_handled() 
			_stop_drag()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.has_meta("port"):
		hovered_port = area.get_meta("port")

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.has_meta("port") and hovered_port == area.get_meta("port"):
		hovered_port = null
