extends Control

@export var tabs: Array[TabBar]
@export var tab_container: TabContainer

var device_id: String = ""

func _ready() -> void:
	if tabs.size() > 0 and tabs[0] != null:
		if tabs[0].has_signal("packages_changed"):
			tabs[0].packages_changed.connect(_on_packages_changed)
	call_deferred("setup")

func _on_packages_changed(_current_installed_packages: Array[String]) -> void:
	refresh_data()

func setup() -> void:
	EventManager.device_updated.connect(_on_device_updated)
	refresh_data()

func _on_device_updated(_device_id: String, _device_data: DeviceData)-> void:
	if device_id == _device_id:
		refresh_data()

func refresh_data() -> void:
	if device_id == "":
		return
		
	var device = GameManager.get_runtime_device_data_by_id(device_id)
	if device == null or not (device is ServerDeviceData):
		return

	for i in range(tabs.size()):
		var tab = tabs[i]
		if tab == null:
			continue

		if i == 0:
			tab_container.set_tab_disabled(i, false)
			continue
		
		var needed_package: String = tab.get("PACKAGE_NEED")
		var is_installed = false
		
		if needed_package != null and needed_package != "":
			is_installed = device.is_package_installed(needed_package)
		else:
			is_installed = true
		tab_container.set_tab_disabled(i, not is_installed)

	for tab in tabs:
		if tab and tab.has_method("display_data"):
			tab.display_data(device, device_id)
