extends TabBar

const DEFAULT_POOL_NAME: String = "Unnamed Pool"
const NEW_POOL_PREFIX: String = "New Pool "
const PACKAGE_NEED: String = "isc-dhcp-server"

@export var pool_list: ItemList
@export var dhcp_service_state: CheckButton
@export var pool_name: LineEdit
@export var default_gateway: LineEdit
@export var dns_server: LineEdit
@export var start_ip_address: LineEdit
@export var subnet_mask: LineEdit
@export var pool_size: LineEdit

var current_pools: Array[DHCPService] = []
var current_selected_index: int = -1
var target_device_id: String = ""


func display_data(device: ServerDevice, device_id: String) -> void:
	target_device_id = device_id
	current_selected_index = -1
	_clear_input_fields()

	if dhcp_service_state:
		var is_dhcp_enabled := device.dhcp_service == ServerDevice.ServiceState.ON
		dhcp_service_state.set_pressed_no_signal(is_dhcp_enabled)

	current_pools = device.dhcp_configuration.duplicate(true)
	_refresh_pool_list()


func _refresh_pool_list() -> void:
	if not pool_list:
		return

	pool_list.clear()
	for pool in current_pools:
		if pool:
			pool_list.add_item(pool.pool_name if pool.pool_name != "" else DEFAULT_POOL_NAME)
			pool_list.select(current_selected_index)


func _on_pool_list_item_selected(index: int) -> void:
	current_selected_index = index
	_refresh_input_fields()


func _refresh_input_fields() -> void:
	var pool = _get_selected_pool()
	if not pool:
		_clear_input_fields()
		return

	pool_name.text = pool.pool_name
	default_gateway.text = pool.default_gateway
	dns_server.text = pool.dns_server
	start_ip_address.text = pool.start_ip_address
	subnet_mask.text = pool.subnet_mask
	pool_size.text = str(pool.pool_size)


func _clear_input_fields() -> void:
	pool_name.text = ""
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
	_apply_to_server()


func _on_delete_button_pressed() -> void:
	if _get_selected_pool() == null:
		return

	current_pools.remove_at(current_selected_index)
	current_selected_index = -1
	_clear_input_fields()
	_refresh_pool_list()
	_apply_to_server()


func _on_save_button_pressed() -> void:
	var pool = _get_selected_pool()
	if not pool:
		return

	pool.pool_name = pool_name.text.strip_edges()
	pool.default_gateway = default_gateway.text.strip_edges()
	pool.dns_server = dns_server.text.strip_edges()
	pool.start_ip_address = start_ip_address.text.strip_edges()
	pool.subnet_mask = subnet_mask.text.strip_edges()
	pool.pool_size = _to_int(pool_size.text)

	_refresh_pool_list()
	if pool_list:
		pool_list.select(current_selected_index)
	_apply_to_server()


func _on_dhcp_service_state_toggled(_toggled_on: bool) -> void:
	_apply_to_server()


func _apply_to_server() -> void:
	if target_device_id == "":
		return

	var device = NetworkDeviceManager.get_device_data(target_device_id) as ServerDevice
	if not device:
		return

	var service_state := ServerDevice.ServiceState.OFF
	if dhcp_service_state and dhcp_service_state.button_pressed:
		service_state = ServerDevice.ServiceState.ON

	device.dhcp_service = service_state
	device.dhcp_configuration = current_pools.duplicate(true)
	for pool in current_pools:
		print(pool.pool_name)
	NetworkDeviceManager.update_device(target_device_id, device)


func _to_int(value: String) -> int:
	return value.strip_edges().to_int()
