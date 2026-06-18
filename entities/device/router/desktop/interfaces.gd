extends TabBar

@export var hostname: LineEdit
@export var interface_list: ItemList
@export var interface_status: Label
@export var mac_address: LineEdit
@export var ip_address: LineEdit
@export var subnet_mask: LineEdit

var target_device_id: String = ""
var current_selected_index: int = -1


func display_data(device: DeviceData, device_id: String) -> void:
	if not interface_list:
		push_warning("interface_list empty")
		return

	target_device_id = device_id
	current_selected_index = -1
	_clear_input_fields()
	hostname.text = device.hostname
	_refresh_interface_list(device)


func _refresh_interface_list(device: DeviceData) -> void:
	interface_list.clear()

	var interfaces_array = device.get_interfaces()

	for i in range(interfaces_array.size()):
		var iface = interfaces_array[i]
		if iface != null:
			var display_name = iface.id
			if display_name == "":
				display_name = "Unnamed Interface"

			interface_list.add_item(display_name)
			interface_list.set_item_metadata(i, iface)


func _on_interface_list_item_selected(index: int) -> void:
	current_selected_index = index
	var selected_iface: NetworkInterface = interface_list.get_item_metadata(index)

	if selected_iface:
		interface_status.text = "Plugged" if selected_iface.is_up() else "Unplugged"

		if selected_iface.is_up():
			interface_status.add_theme_color_override("font_color", Color(0.0, 0.541, 0.0, 1.0))
		else:
			interface_status.add_theme_color_override("font_color", Color(0.6, 0.0, 0.0, 1.0))

		mac_address.text = selected_iface.mac_address

		ip_address.text = selected_iface.export_ip_address
		subnet_mask.text = selected_iface.export_subnet_mask


func _on_save_button_pressed() -> void:
	if current_selected_index == -1 or target_device_id == "":
		return

	var device = GameManager.get_runtime_device_data_by_id(target_device_id)
	if not device is RouterDeviceData:
		return

	var interfaces_array = device.get_interfaces()
	var iface: NetworkInterface = interfaces_array[current_selected_index]

	if iface == null:
		return

	var new_ip = ip_address.text.strip_edges()
	var new_mask = subnet_mask.text.strip_edges()
	
	if new_ip != "" and not IPAddress.is_valid_ip(new_ip):
		EventManager.error_configuration.emit("Invalid IP Address format")
		return
	if new_mask != "" and not IPAddress.is_valid_mask(new_mask):
		EventManager.error_configuration.emit("Invalid Subnet Mask format")
		return

	iface.export_ip_address = new_ip
	iface.export_subnet_mask = new_mask
	iface.mac_address = mac_address.text.strip_edges()

	iface.initialize_ip_from_export()

	GameManager.update_device_data(target_device_id, device)


func _clear_input_fields() -> void:
	mac_address.text = ""
	ip_address.text = ""
	subnet_mask.text = ""
	interface_status.text = ""


func _on_hostname_focus_exited() -> void:
	if hostname.text.strip_edges() != "":
		var device = GameManager.get_runtime_device_data_by_id(target_device_id)
		if device:
			device.hostname = hostname.text.strip_edges()
			GameManager.update_device_data(target_device_id, device)
