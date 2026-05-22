extends Control

@export_group("General Inputs")
@export var host_name_input: LineEdit
@export var network_status_label: Label

@export_group("Network Inputs")
@export var ip_address_input: LineEdit
@export var subnet_mask_input: LineEdit
@export var gateway_input: LineEdit

@export_group("DNS Inputs")
@export var primary_dns_input: LineEdit

var target_device_id: String

# =========================
# INITIALIZATION
# =========================

func setup(device_id: String) -> void:
	target_device_id = device_id
	refresh_data()

func refresh_data() -> void:
	if target_device_id == "": return
	_populate_ui()

# =========================
# DATA TO UI MAPPING
# =========================
func _populate_ui() -> void:
	# Panggil dari Autoload yang baru
	var raw_device = NetworkDeviceManager.get_device_data(target_device_id)
	if not raw_device is ServerDevice:
		return
		
	var device: ServerDevice = raw_device
	
	# 1. General Setup
	host_name_input.text = device.hostname
	gateway_input.text = device.default_gateway
	primary_dns_input.text = device.dns_server
	
	var main_iface = device.get_main_interface()
	
	if main_iface:
		# Gunakan export_ip_address sesuai struktur NetworkInterface kita
		ip_address_input.text = main_iface.export_ip_address
		subnet_mask_input.text = main_iface.export_subnet_mask
		
		# Gunakan fungsi is_up() bawaan
		if main_iface.is_up():
			network_status_label.text = "Plugged"
			network_status_label.add_theme_color_override("font_color", Color(0.0, 0.541, 0.0, 1.0)) # Hijau
		else:
			network_status_label.text = "Unplugged"
			network_status_label.add_theme_color_override("font_color", Color(0.6, 0.0, 0.0, 1.0)) # Merah


# =========================
# SAVE LOGIC (Kirim ke Sistem!)
# =========================
func _on_save_button_pressed() -> void:
	var raw_device = NetworkDeviceManager.get_device_data(target_device_id)
	if not raw_device is ServerDevice: return
	var device: ServerDevice = raw_device
	
	# 1. Simpan data spesifik PC
	device.hostname = host_name_input.text.strip_edges()
	device.default_gateway = gateway_input.text.strip_edges()
	device.dns_server = primary_dns_input.text.strip_edges()

	# 2. Simpan IP ke Interface
	var main_iface = device.get_main_interface()
	if main_iface:
		main_iface.export_ip_address = ip_address_input.text.strip_edges()
		main_iface.export_subnet_mask = subnet_mask_input.text.strip_edges()
		# Wajib dipanggil untuk mengkalkulasi ulang objek IPAddress-nya!
		main_iface.setup_ip_address()
		
	# 3. Update ke NetworkDeviceManager
	NetworkDeviceManager.update_device(target_device_id, device)
	print("[Server Setting] Konfigurasi jaringan disimpan untuk: ", target_device_id)
