extends TabBar

const DEFAULT_POOL_NAME: String = "Unnamed Pool"
const NEW_POOL_PREFIX: String = "New Pool "
const PACKAGE_NEED: String = "isc-dhcp-server"

@export var pool_list: ItemList
@export var dhcp_service_state: CheckButton
@export var pool_name: LineEdit
@export var interface_id: OptionButton
@export var default_gateway: LineEdit
@export var dns_server: LineEdit
@export var start_ip_address: LineEdit
@export var subnet_mask: LineEdit
@export var pool_size: LineEdit

var current_pools: Array[DHCPService] = []
var current_selected_index: int = -1
var target_device_id: String = ""


func display_data(device: ServerDeviceData, device_id: String) -> void:
	if target_device_id != device_id:
		target_device_id = device_id
		current_selected_index = -1
		_clear_input_fields()

	if dhcp_service_state:
		var is_dhcp_enabled := device.dhcp_service == ServerDeviceData.ServiceState.ON
		dhcp_service_state.set_pressed_no_signal(is_dhcp_enabled)

	current_pools = device.dhcp_configuration.duplicate(true)
	if current_selected_index >= current_pools.size():
		current_selected_index = -1
		_clear_input_fields()

	if interface_id:
		interface_id.clear()
		for i in range(device.interfaces.size()):
			var iface := device.interfaces[i]
			interface_id.add_item(iface.id)

	_refresh_pool_list()


func _refresh_pool_list() -> void:
	if not pool_list:
		return

	pool_list.clear()
	for pool in current_pools:
		if pool:
			pool_list.add_item(pool.pool_name if pool.pool_name != "" else DEFAULT_POOL_NAME)

	if current_selected_index > -1:
		pool_list.select(current_selected_index)
	else:
		pool_list.deselect_all()


func _on_pool_list_item_selected(index: int) -> void:
	current_selected_index = index
	_refresh_input_fields()


func _refresh_input_fields() -> void:
	var pool = _get_selected_pool()
	if not pool:
		_clear_input_fields()
		return

	pool_name.text = pool.pool_name
	if interface_id:
		for i in range(interface_id.item_count):
			if interface_id.get_item_text(i) == pool.interface_id:
				interface_id.select(i)
				break
	default_gateway.text = pool.default_gateway
	dns_server.text = pool.dns_server
	start_ip_address.text = pool.start_ip_address
	subnet_mask.text = pool.subnet_mask
	pool_size.text = str(pool.pool_size)


func _clear_input_fields() -> void:
	pool_name.text = ""
	if interface_id:
		interface_id.select(-1)
	default_gateway.text = ""
	dns_server.text = ""
	start_ip_address.text = ""
	subnet_mask.text = ""
	pool_size.text = ""


func _get_selected_pool() -> DHCPService:
	if current_selected_index < 0 or current_selected_index >= current_pools.size():
		return null
	return current_pools[current_selected_index]


func _on_add_button_pressed() -> void:
	var new_pool = DHCPService.new()
	new_pool.pool_name = NEW_POOL_PREFIX + str(current_pools.size() + 1)
	current_pools.append(new_pool)
	current_selected_index = current_pools.size() - 1
	_refresh_pool_list()
	_refresh_input_fields()


func _on_delete_button_pressed() -> void:
	if _get_selected_pool() == null:
		return

	current_pools.remove_at(current_selected_index)
	current_selected_index = -1
	_clear_input_fields()
	_refresh_pool_list()
	_apply_to_server()


func validate_inputs() -> bool:
	var gateway = default_gateway.text.strip_edges()
	var dns = dns_server.text.strip_edges()
	var start_ip = start_ip_address.text.strip_edges()
	var subnet = subnet_mask.text.strip_edges()

	if gateway != "" and not IPAddress.is_valid_ip(gateway):
		return false
	if dns != "" and not IPAddress.is_valid_ip(dns):
		return false
	if start_ip != "" and not IPAddress.is_valid_ip(start_ip):
		return false
	if start_ip != "" and subnet != "" and not IPAddress.is_valid_host_ip(start_ip, subnet):
		return false
	if subnet != "" and not IPAddress.is_valid_mask(subnet):
		return false

	return true


func _on_save_button_pressed() -> void:
	var pool = _get_selected_pool()
	if not pool:
		return

	if not validate_inputs():
		NetworkManager.error_configuration.emit("Please enter a valid IP Address or Subnet Mask")
		return

	var new_pool_name = pool_name.text.strip_edges()
	for i in range(current_pools.size()):
		if i != current_selected_index:
			if current_pools[i] != null and current_pools[i].pool_name == new_pool_name:
				NetworkManager.error_configuration.emit("Pool name already exists")
				return

	pool.pool_name = new_pool_name
	if interface_id and interface_id.selected >= 0:
		pool.interface_id = interface_id.get_item_text(interface_id.selected)
	pool.default_gateway = default_gateway.text.strip_edges()
	pool.dns_server = dns_server.text.strip_edges()
	pool.start_ip_address = start_ip_address.text.strip_edges()
	pool.subnet_mask = subnet_mask.text.strip_edges()
	pool.pool_size = _to_int(pool_size.text)

	_refresh_pool_list()
	_apply_to_server()


func _on_dhcp_service_state_toggled(_toggled_on: bool) -> void:
	_apply_to_server()


func _apply_to_server() -> void:
	if target_device_id == "":
		return

	var device_data: ServerDeviceData = NetworkManager.get_runtime_device_data_by_id(
		target_device_id
	)
	if not device_data:
		return

	var service_state := ServerDeviceData.ServiceState.OFF
	if dhcp_service_state and dhcp_service_state.button_pressed:
		service_state = ServerDeviceData.ServiceState.ON

	device_data.dhcp_service = service_state
	device_data.dhcp_configuration = current_pools.duplicate(true)
	NetworkManager.device_updated.emit(target_device_id, device_data)


func _to_int(value: String) -> int:
	return value.strip_edges().to_int()
