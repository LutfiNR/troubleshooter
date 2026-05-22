extends TabBar

@export var interface_list: ItemList
@export var neighbor_device_label: Label
@export var neighbor_interface_label: Label
@export var interface_status: Label
@export var mac_address: LineEdit
@export var ip_address: LineEdit
@export var subnet_mask: LineEdit

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
	
	# Kita konversi Dictionary menjadi Array untuk ditampilkan di UI List
	var interfaces_array = device.get_interfaces().values()
	
	for i in range(interfaces_array.size()):
		var iface = interfaces_array[i]
		if iface != null:
			var display_name = iface.id
			if display_name == "":
				display_name = "Unnamed Interface"
			
			interface_list.add_item(display_name)
			interface_list.set_item_metadata(i, iface)

# ==========================================
# AKSI SAAT LIST DIKLIK
# ==========================================
func _on_interface_list_item_selected(index: int) -> void:
	current_selected_index = index
	var selected_iface: NetworkInterface = interface_list.get_item_metadata(index)
	var device: RouterDevice = NetworkDeviceManager.get_device_data(target_device_id)
	var neighbor_device: NetworkDevice = NetworkDeviceManager.get_device_data(device.get_neighbor(selected_iface.id).device_b_id)
	
	if selected_iface:
		neighbor_device_label.text = neighbor_device.hostname
		neighbor_interface_label.text = device.get_neighbor(selected_iface.id).interface_b_id
		interface_status.text = "Plugged" if selected_iface.is_up() else "Unplugged"
		
		if selected_iface.is_up():
			interface_status.add_theme_color_override("font_color", Color(0.0, 0.541, 0.0, 1.0))
		else:
			interface_status.add_theme_color_override("font_color", Color(0.6, 0.0, 0.0, 1.0))
			
		mac_address.text = selected_iface.mac_address
		
		# Properti IP di NetworkInterface kita bernama export_ip_address
		ip_address.text = selected_iface.export_ip_address
		subnet_mask.text = selected_iface.export_subnet_mask

# ==========================================
# SAVE (APPLY TO DEVICE)
# ==========================================
func _on_save_button_pressed() -> void:
	if current_selected_index == -1 or target_device_id == "":
		return
	
	# Ambil data router terbaru dari manager
	var device = NetworkDeviceManager.get_device_data(target_device_id)
	if not device is RouterDevice: return
	
	# Sinkronkan array interface UI dengan dictionary di Router
	var interfaces_array = device.get_interfaces().values()
	var iface: NetworkInterface = interfaces_array[current_selected_index]
	
	if iface == null: return
	
	# Terapkan input dari user ke interface
	iface.export_ip_address = ip_address.text.strip_edges()
	iface.export_subnet_mask = subnet_mask.text.strip_edges()
	iface.mac_address = mac_address.text.strip_edges()
	
	# PENTING: Inisialisasi ulang IPAddress Object di dalam interface
	iface.setup_ip_address()
	
	# Simpan kembali ke manager
	NetworkDeviceManager.update_device(target_device_id, device)
	print("[Router Interface Tab] Konfigurasi IP disimpan untuk ", target_device_id)

# ==========================================
# CLEAR UI
# ==========================================
func _clear_input_fields() -> void:
	mac_address.text = ""
	ip_address.text = ""
	subnet_mask.text = ""
	interface_status.text = ""
