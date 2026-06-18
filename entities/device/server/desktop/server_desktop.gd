extends Node2D

@export_group("Visuals")
@export var sprite_on: Texture2D
@export var sprite_off: Texture2D

@export_group("Apps")
@export var service_app: Control
@export var setting_app: Control

@onready var camera: Camera2D = $Camera2D
@onready var app_container: Panel = $UIContainer/AppContainer
@onready var desktop_panel: HBoxContainer = $UIContainer/PanelDesktop
@onready var sprite: Sprite2D = $Desktop

var device_id: String

func _ready() -> void:
	camera.make_current()
	EventManager.device_updated.connect(_on_device_updated)
	if setting_app:
		setting_app.device_id = device_id
	if service_app:
		service_app.device_id = device_id
	_close_all_apps()
	_update_visual()

func _on_device_updated(_device_id: String, _device_data: DeviceData)-> void:
	if device_id == _device_id:
		_update_visual()

func _update_visual() -> void:
	var device: ServerDeviceData = GameManager.get_runtime_device_data_by_id(device_id)
	if device == null: return
	
	if device.power == DeviceData.PowerState.OFF:
		if sprite_off: sprite.texture = sprite_off
		_close_all_apps()
		desktop_panel.hide()
	else:
		desktop_panel.show()
		if sprite_on: sprite.texture = sprite_on

func open_app(target_app: Control) -> void:
	_close_all_apps()
	app_container.show()
	target_app.show()

func _close_all_apps() -> void:
	app_container.hide()
	if service_app: service_app.hide()
	if setting_app: setting_app.hide()

func _on_service_button_pressed() -> void: open_app(service_app)
func _on_app_exit_button_pressed() -> void: _close_all_apps()
func _on_setting_button_pressed() -> void: open_app(setting_app)
func _on_exit_button_pressed() -> void: queue_free()
