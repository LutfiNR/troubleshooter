extends Node2D

@export_group("Visuals")
@export var sprite_on: Texture2D  # Agar layar PC Klien bisa nyala kembali
@export var sprite_off: Texture2D

@export_group("Apps")
@export var setting_app: Control
@export var browser_app: Control
@export var file_app: Control
@export var cmd_app: Control
@export var email_app: Control

@onready var camera: Camera2D = $Camera2D
@onready var app_container: Panel = $UIContainer/AppContainer
@onready var panel_desktop: HBoxContainer = $UIContainer/PanelDesktop
@onready var sprite: Sprite2D = $Desktop

var device_id: String

func _ready() -> void:
	camera.make_current()
	
	if setting_app and setting_app.has_method("setup"): setting_app.setup(device_id)
	if cmd_app and cmd_app.has_method("setup"): cmd_app.setup(device_id)
	if browser_app and browser_app.has_method("setup"): browser_app.setup(device_id)
	if file_app and file_app.has_method("setup"): file_app.setup(device_id)
	if email_app and email_app.has_method("setup"): email_app.setup(device_id)

	EventManager.device_updated.connect(_on_device_updated)
	_close_all_apps()
	_update_visual()

func _on_device_updated(updated_device_id: String, _device_data: DeviceData) -> void:
	if updated_device_id == device_id:
		_update_visual()

func _update_visual() -> void:
	var device: ComputerDeviceData = GameManager.get_runtime_device_data_by_id(device_id)
	if device == null: return
	
	if device.power == DeviceData.PowerState.OFF:
		if sprite_off: sprite.texture = sprite_off
		panel_desktop.hide()
		_close_all_apps()
	else:
		panel_desktop.show()
		if sprite_on: sprite.texture = sprite_on

func open_app(target_app: Control) -> void:
	if target_app == null: return
	_close_all_apps()
	app_container.show()
	target_app.show()
	if target_app.has_method("refresh_data"):
		target_app.refresh_data()

func _close_all_apps() -> void:
	app_container.hide()
	if setting_app: setting_app.hide()
	if browser_app: browser_app.hide()
	if file_app: file_app.hide()
	if cmd_app: cmd_app.hide()
	if email_app: email_app.hide()

func _on_setting_button_pressed() -> void: open_app(setting_app)
func _on_cmd_button_pressed() -> void: open_app(cmd_app)
func _on_file_button_pressed() -> void: open_app(file_app)
func _on_browser_button_pressed() -> void: open_app(browser_app)
func _on_email_button_pressed() -> void: open_app(email_app)
func _on_app_exit_button_pressed() -> void: _close_all_apps()
func _on_exit_button_pressed() -> void: queue_free()
