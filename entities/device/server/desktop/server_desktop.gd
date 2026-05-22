extends Node2D

@export_group("Visuals")
@export var sprite_on: Texture2D
@export var sprite_off: Texture2D

@export_group("Apps")
@export var service_app: Control
@export var setting_app: Control

@onready var camera: Camera2D = $Camera2D
@onready var app_container: Panel = $UIContainer/AppContainer
@onready var panel_desktop: HBoxContainer = $UIContainer/PanelDesktop
@onready var sprite: Sprite2D = $Desktop

var device_id: String

func _ready() -> void:
	camera.make_current()
	if service_app and service_app.has_method("setup"): service_app.setup(device_id)
	if setting_app and setting_app.has_method("setup"): setting_app.setup(device_id)

	NetworkDeviceManager.device_updated.connect(_on_device_updated)
	_close_all_apps()
	_update_visual()

func _on_device_updated(updated_device_id: String) -> void:
	if updated_device_id == device_id:
		_update_visual()

func _update_visual() -> void:
	var device: ServerDevice = NetworkDeviceManager.get_device_data(device_id)
	if device == null: return
	
	# Menggunakan device.power (Bukan power_state)
	if device.power == NetworkDevice.PowerState.OFF:
		if sprite_off: sprite.texture = sprite_off
		_close_all_apps()
		panel_desktop.hide()
	else:
		panel_desktop.show()
		if sprite_on: sprite.texture = sprite_on

func open_app(target_app: Control) -> void:
	_close_all_apps()
	app_container.show()
	target_app.show()
	if target_app.has_method("refresh_data"):
		target_app.refresh_data()

func _close_all_apps() -> void:
	app_container.hide()
	if service_app: service_app.hide()
	if setting_app: setting_app.hide()

func _on_service_button_pressed() -> void: open_app(service_app)
func _on_app_exit_button_pressed() -> void: _close_all_apps()
func _on_setting_button_pressed() -> void: open_app(setting_app)
func _on_exit_button_pressed() -> void: queue_free()
