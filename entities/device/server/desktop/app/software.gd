extends TabBar

signal packages_changed(installed_packages: Array[String])

@export var package_list: ItemList
@export var status_label: Label
@export var install_button: Button
@export var uninstall_button: Button
@export var available_packages: Array[String] = []

var target_device_id: String = ""
var current_installed_packages: Array[String] = []
var package_need: String = "Software"
var current_selected_index: int = -1

func display_data(device: ServerDevice, device_id: String) -> void:
	if not package_list: return
	target_device_id = device_id
	current_installed_packages = device.installed_packages.duplicate()
	
	_refresh_list()
	if current_selected_index == -1: _update_ui_state(-1)

func _refresh_list() -> void:
	package_list.clear()
	for pkg in available_packages:
		var display_name = pkg
		if current_installed_packages.has(pkg): display_name += " [Installed]"
		package_list.add_item(display_name)
		
	if current_selected_index != -1 and current_selected_index < package_list.get_item_count():
		package_list.select(current_selected_index)
		_update_ui_state(current_selected_index)

func _on_package_list_item_selected(index: int) -> void:
	current_selected_index = index
	_update_ui_state(index)

func _update_ui_state(index: int) -> void:
	if index == -1:
		if status_label: status_label.text = "Pilih paket untuk melihat status."
		if install_button: install_button.disabled = true
		if uninstall_button: uninstall_button.disabled = true
		return
		
	var selected_pkg = available_packages[index]
	var is_installed = current_installed_packages.has(selected_pkg)
	
	if status_label:
		status_label.text = "Status: " + ("Terinstal" if is_installed else "Belum Terinstal")
		status_label.modulate = Color(0, 1, 0) if is_installed else Color(1, 0, 0)
		
	if install_button: install_button.disabled = is_installed
	if uninstall_button: uninstall_button.disabled = not is_installed

func _on_install_button_pressed() -> void:
	if current_selected_index == -1: return
	var selected_pkg = available_packages[current_selected_index]
	if not current_installed_packages.has(selected_pkg):
		current_installed_packages.append(selected_pkg)
		_refresh_list()
		_apply_to_server()
		packages_changed.emit(current_installed_packages)

func _on_uninstall_button_pressed() -> void:
	if current_selected_index == -1: return
	var selected_pkg = available_packages[current_selected_index]
	if current_installed_packages.has(selected_pkg):
		current_installed_packages.erase(selected_pkg)
		_refresh_list()
		_apply_to_server()
		packages_changed.emit(current_installed_packages)

func _apply_to_server() -> void:
	if target_device_id == "": return
	var device = NetworkDeviceManager.get_device_data(target_device_id) as ServerDevice
	if not device: return
	
	device.installed_packages = current_installed_packages.duplicate()
	NetworkDeviceManager.update_device(target_device_id, device)
