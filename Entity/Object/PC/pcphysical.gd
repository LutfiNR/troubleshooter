extends Node2D

@onready var port: Port = $Port
@onready var cable: Cable = $Cable
@onready var camera: Camera2D = $Camera2D

var _network_connection: DeviceState.NetworkConnection
var device

func _ready() -> void:
	cable.plug_state_changed.connect(_on_cable_changed)

	set_network_connection(device.get_network_connection())

	camera.make_current()

	if _network_connection == DeviceState.NetworkConnection.UNPLUGGED:
		cable.unplug()
	elif _network_connection == DeviceState.NetworkConnection.PLUGGED_IN:
		cable.plug_in()

func _on_cable_changed(is_plugged: bool):
	# Update port visual
	port.set_plugged(is_plugged)

	# Update network state
	_network_connection = (
		DeviceState.NetworkConnection.PLUGGED_IN
		if is_plugged
		else DeviceState.NetworkConnection.UNPLUGGED
	)

	# Save back to device if needed
	device.set_network_connection_state(_network_connection)

func _on_texture_button_pressed() -> void:
	queue_free()

func set_network_connection(state: DeviceState.NetworkConnection):
	_network_connection = state
