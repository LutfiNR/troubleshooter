extends Control

@export_group("General Inputs")
@export var id_input: LineEdit
@export var host_name_input: LineEdit
@export var interface_label: Label
@export var mac_address_label: Label
@export var network_status_label: Label

@export_group("Network Inputs")
@export var ip_address_input: LineEdit
@export var subnet_mask_input: LineEdit
@export var gateway_input: LineEdit

@export_group("DNS Inputs")
@export var primary_dns_input: LineEdit

var device_id: String
var device_data: ServerDeviceData

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	device_data = NetworkManager.get_runtime_device_data_by_id(device_id)
	NetworkManager.device_updated.connect(_on_device_updated)
	populate_ui()

func _on_device_updated(_device_id: String, _device_data: DeviceData) -> void:
	if device_id == _device_id:
		device_data = _device_data
		populate_ui()

func populate_ui() -> void:
	id_input.text = device_data.device_id
	host_name_input.text = device_data.hostname
	gateway_input.text = device_data.default_gateway
	primary_dns_input.text = device_data.dns_server
	var main_iface = device_data.get_interface("")
	if main_iface:
		interface_label.text = main_iface.id
		mac_address_label.text = main_iface.mac_address
		ip_address_input.text = main_iface.export_ip_address
		subnet_mask_input.text = main_iface.export_subnet_mask
		if main_iface.is_up():
			network_status_label.text = "Plugged"
			network_status_label.add_theme_color_override("font_color", Color(0.0, 0.541, 0.0, 1.0)) # Hijau
		else:
			network_status_label.text = "Unplugged"
			network_status_label.add_theme_color_override("font_color", Color(0.6, 0.0, 0.0, 1.0)) # Merah

func validate_inputs() -> bool:
	var ip = ip_address_input.text.strip_edges()
	var subnet = subnet_mask_input.text.strip_edges()
	var gateway = gateway_input.text.strip_edges()
	var dns = primary_dns_input.text.strip_edges()

	if ip != "" and not IPAddress.is_valid_ip(ip):
		return false
	if subnet != "" and not IPAddress.is_valid_mask(subnet):
		return false
	if gateway != "" and not IPAddress.is_valid_ip(gateway):
		return false
	if dns != "" and not IPAddress.is_valid_ip(dns):
		return false
	return true

func _on_save_button_pressed() -> void:
	if not validate_inputs():
		NetworkManager.error_configuration.emit("Please enter a valid IP Address or Subnet Mask")
		return
	device_data.hostname = host_name_input.text.strip_edges()
	device_data.default_gateway = gateway_input.text.strip_edges()
	device_data.dns_server = primary_dns_input.text.strip_edges()
	var main_iface = device_data.get_interface("")
	if main_iface:
		main_iface.export_ip_address = ip_address_input.text.strip_edges()
		main_iface.export_subnet_mask = subnet_mask_input.text.strip_edges()
		main_iface.initialize_ip_from_export()
	NetworkManager.update_interface_device_data(device_id, main_iface.id, main_iface)
