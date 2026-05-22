extends TabBar

@export var interface_list: ItemList
@export var ip_dhcp_server: LineEdit

var target_device_id: String = ""
var current_selected_index: int = -1

# ==========================================
# SETUP & DISPLAY
# ==========================================
func display_data(device: NetworkDevice, device_id: String) -> void:
	if not interface_list:
		push_warning("interface_list empty")
		return
	
	target_device_id = device_id
	current_selected_index = -1
	_clear_input_fields()
	
	_refresh_interface_list(device)

func _refresh_interface_list(device: NetworkDevice) -> void:
	interface_list.clear()
	
	if not device is RouterDevice: return
	var interfaces_array = device.get_interfaces().values()
	
	for i in range(interfaces_array.size()):
		var iface = interfaces_array[i]
		if iface == null: continue
		
		var display_name = iface.id if iface.id != "" else "Unnamed Interface"
		interface_list.add_item(display_name)
		
		# Kita hanya menyimpan referensi interface id untuk index ini
		interface_list.set_item_metadata(interface_list.item_count - 1, iface.id)

# ==========================================
# AKSI SAAT LIST DIKLIK
# ==========================================
func _on_interface_list_item_selected(index: int) -> void:
	current_selected_index = index
	
	var device = NetworkDeviceManager.get_device_data(target_device_id) as RouterDevice
	if not device: return
	
	var selected_interface_id: String = interface_list.get_item_metadata(index)
	
	# Cek apakah relay ada menggunakan fungsi bawaan RouterDevice
	if device.has_dhcp_relay(selected_interface_id):
		var relay_ip_obj = device.get_dhcp_relay_ip(selected_interface_id)
		ip_dhcp_server.text = relay_ip_obj.address if relay_ip_obj else ""
	else:
		ip_dhcp_server.text = ""

# ==========================================
# SAVE (APPLY TO DEVICE)
# ==========================================
func _on_save_button_pressed() -> void:
	if current_selected_index == -1 or target_device_id == "":
		return
		
	var device = NetworkDeviceManager.get_device_data(target_device_id) as RouterDevice
	if not device: return
	
	var selected_interface_id: String = interface_list.get_item_metadata(current_selected_index)
	var input_ip = ip_dhcp_server.text.strip_edges()
	
	if input_ip == "":
		device.remove_dhcp_relay(selected_interface_id)
	else:
		# Buat IPAddress object untuk target DHCP Server-nya
		var relay_ip = IPAddress.new(input_ip, "255.255.255.255")
		device.set_dhcp_relay_ip(selected_interface_id, relay_ip)
		
	NetworkDeviceManager.update_device(target_device_id, device)
	print("[DHCP Relay Tab] Relay diperbarui untuk ", selected_interface_id)

# ==========================================
# CLEAR UI
# ==========================================
func _clear_input_fields() -> void:
	ip_dhcp_server.text = ""
