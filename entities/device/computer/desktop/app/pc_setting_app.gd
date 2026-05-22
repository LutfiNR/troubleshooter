extends Control

@export_group("General Inputs")
@export var host_name_input: LineEdit
@export var network_status_label: Label

@export_group("Network Inputs")
@export var ip_address_input: LineEdit
@export var subnet_mask_input: LineEdit
@export var gateway_input: LineEdit
@export var ip_set_mode_input: CheckButton

@export_group("DNS Inputs")
@export var primary_dns_input: LineEdit

var target_device_id: String

func setup(device_id: String) -> void:
	target_device_id = device_id
	refresh_data()

func refresh_data() -> void:
	if target_device_id == "": return
	_populate_ui()

func _populate_ui() -> void:
	var raw_device = NetworkDeviceManager.get_device_data(target_device_id)
	if not raw_device is ComputerDevice: return
	var device: ComputerDevice = raw_device
	
	host_name_input.text = device.hostname
	gateway_input.text = device.default_gateway
	primary_dns_input.text = device.dns_server
	
	var main_iface = device.get_main_interface()
	if main_iface:
		ip_address_input.text = main_iface.export_ip_address
		subnet_mask_input.text = main_iface.export_subnet_mask
		
		if main_iface.state == NetworkInterface.InterfaceState.UP:
			network_status_label.text = "Plugged"
			network_status_label.add_theme_color_override("font_color", Color(0.0, 0.541, 0.0, 1.0))
		else:
			network_status_label.text = "Unplugged"
			network_status_label.add_theme_color_override("font_color", Color(0.6, 0.0, 0.0, 1.0))

	var is_dhcp = (device.ip_allocation_type == ComputerDevice.IPAllocationType.DHCP)
	ip_set_mode_input.set_pressed_no_signal(is_dhcp)
	
	_update_input_editability()

func _update_input_editability() -> void:
	var is_dynamic := ip_set_mode_input.button_pressed
	ip_address_input.editable = not is_dynamic
	subnet_mask_input.editable = not is_dynamic
	gateway_input.editable = not is_dynamic
	primary_dns_input.editable = not is_dynamic

func _on_ip_dynamic_button_toggled(toggled: bool) -> void:
	if toggled:
		get_ip_from_dhcp()
	_update_input_editability()

func _on_save_button_pressed() -> void:
	var device = NetworkDeviceManager.get_device_data(target_device_id) as ComputerDevice
	if not device: return
	
	device.hostname = host_name_input.text.strip_edges()
	device.default_gateway = gateway_input.text.strip_edges()
	device.dns_server = primary_dns_input.text.strip_edges()
	
	if ip_set_mode_input.button_pressed:
		device.ip_allocation_type = ComputerDevice.IPAllocationType.DHCP
	else:
		device.ip_allocation_type = ComputerDevice.IPAllocationType.STATIC
	
	var main_iface = device.get_main_interface()
	if main_iface:
		main_iface.export_ip_address = ip_address_input.text.strip_edges()
		main_iface.export_subnet_mask = subnet_mask_input.text.strip_edges()
		main_iface.setup_ip_address()
	
	print("[Settings] Konfigurasi disimpan untuk ID: ", target_device_id)
	NetworkDeviceManager.update_device(target_device_id, device)

func get_ip_from_dhcp():
	var device = NetworkDeviceManager.get_device_data(target_device_id) as ComputerDevice
	var main_iface = device.get_main_interface()
	
	if not main_iface.is_up():
		_dhcp_failed_request()
		return

	# Cukup gunakan 1 Baris ini untuk memanggil Autoload Service!
	var response = NetworkServiceManager.request_dhcp(target_device_id, "eth0")
	
	if response.success:
		ip_address_input.text = device.get_main_interface().export_ip_address
		subnet_mask_input.text = device.get_main_interface().export_subnet_mask
		gateway_input.text = device.default_gateway
		primary_dns_input.text = device.dns_server
		network_status_label.text = "DHCP Success"
		network_status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		_dhcp_failed_request()

func _dhcp_failed_request() -> void:
	gateway_input.text = "0.0.0.0"
	primary_dns_input.text = "0.0.0.0"
	ip_address_input.text = "169.254.55.232"
	subnet_mask_input.text = "255.255.0.0"
	network_status_label.text = "DHCP Failed"
	network_status_label.add_theme_color_override("font_color", Color(0.6, 0.0, 0.0, 1.0))
