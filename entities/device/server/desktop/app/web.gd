extends TabBar

const PACKAGE_NEED: String = "apache2"

@export var name_server_list: ItemList
@export var web_service: CheckButton
@export var http_service_state: CheckButton
@export var https_service_state: CheckButton
@export var vhost_name: LineEdit
@export var server_name: LineEdit
@export var document_root: LineEdit
@export var protocol: OptionButton
@export var web_content: TextEdit

var current_vhosts: Array[WebVirtualHost] = []
var current_selected_index: int = -1 
var target_device_id: String = ""

func display_data(device: ServerDeviceData, device_id: String) -> void:
	if not name_server_list: return
	if target_device_id != device_id:
		target_device_id = device_id
		current_selected_index = -1
		_clear_input_fields()
	
	if device.web_configuration.is_empty() or device.web_configuration[0] == null:
		device.web_configuration = [WebService.new()]
		
	var web_config = device.web_configuration[0] 
	if web_service: web_service.set_pressed_no_signal(device.web_service == ServerDeviceData.ServiceState.ON)
	if http_service_state: http_service_state.set_pressed_no_signal(web_config.http_state == WebService.ServiceState.ON)
	if https_service_state: https_service_state.set_pressed_no_signal(web_config.https_state == WebService.ServiceState.ON)
		
	current_vhosts = web_config.virtual_hosts.duplicate()
	if current_selected_index >= current_vhosts.size():
		current_selected_index = -1
		_clear_input_fields()

	_refresh_list()

func _refresh_list() -> void:
	name_server_list.clear()
	for vhost in current_vhosts:
		if vhost: name_server_list.add_item(vhost.server_name if vhost.server_name != "" else "Unnamed Host")

	if current_selected_index > -1:
		name_server_list.select(current_selected_index)
	else:
		name_server_list.deselect_all()

func _on_name_server_list_item_selected(index: int) -> void:
	current_selected_index = index
	_refresh_input_fields()

func _refresh_input_fields() -> void:
	var vhost = _get_selected_vhost()
	if not vhost:
		_clear_input_fields()
		return
	vhost_name.text = vhost.name
	server_name.text = vhost.server_name
	document_root.text = vhost.document_root
	protocol.selected = vhost.protocol
	web_content.text = vhost.content if vhost.content else ""

func _get_selected_vhost() -> WebVirtualHost:
	if current_selected_index < 0 or current_selected_index >= current_vhosts.size():
		return null
	return current_vhosts[current_selected_index]

func _clear_input_fields() -> void:
	server_name.text = ""
	document_root.text = ""
	web_content.text = ""

func _on_add_button_pressed() -> void:
	var new_vhost = WebVirtualHost.new()
	new_vhost.name = "www.example.com"
	new_vhost.server_name = "www.example.com"
	new_vhost.content = "Web Content"
	current_vhosts.append(new_vhost)
	current_selected_index = current_vhosts.size() - 1
	_refresh_list()
	_refresh_input_fields()
	_apply_to_server()

func _on_delete_button_pressed() -> void:
	if _get_selected_vhost() == null: return
	current_vhosts.remove_at(current_selected_index)
	current_selected_index = -1
	_clear_input_fields()
	_refresh_list()
	_apply_to_server()

func _validate_domain(domain: String) -> bool:
	var trimmed = domain.strip_edges()
	if trimmed == "":
		return true
	
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9][-a-zA-Z0-9]*(\\.[a-zA-Z0-9][-a-zA-Z0-9]*)+$")
	var result = regex.search(trimmed)
	return result != null


func _on_save_button_pressed() -> void:
	var vhost = _get_selected_vhost()
	if not vhost: return
	
	var new_server_name = server_name.text.strip_edges()
	if not _validate_domain(new_server_name):
		NetworkManager.error_configuration.emit("Invalid domain format")
		return
		
	if new_server_name != "":
		for i in range(current_vhosts.size()):
			if i != current_selected_index:
				if current_vhosts[i] != null and current_vhosts[i].server_name == new_server_name:
					NetworkManager.error_configuration.emit("Virtual host already exists")
					return
					
	vhost.server_name = new_server_name
	vhost.name = vhost_name.text.strip_edges()
	vhost.document_root = document_root.text.strip_edges()
	vhost.protocol = protocol.selected as WebVirtualHost.Protocol
	vhost.content = web_content.text
	
	_refresh_list()
	_apply_to_server()

func _on_service_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _apply_to_server() -> void:
	if target_device_id == "": return
	var device: ServerDeviceData = NetworkManager.get_runtime_device_data_by_id(target_device_id)
	if not device: return
	
	var master_state = ServerDeviceData.ServiceState.OFF
	if web_service and web_service.button_pressed: master_state = ServerDeviceData.ServiceState.ON
	
	var current_http_state = WebService.ServiceState.OFF
	if http_service_state and http_service_state.button_pressed: current_http_state = WebService.ServiceState.ON
		
	var current_https_state = WebService.ServiceState.OFF
	if https_service_state and https_service_state.button_pressed: current_https_state = WebService.ServiceState.ON
		
	var new_web_config = WebService.new()
	new_web_config.http_state = current_http_state
	new_web_config.https_state = current_https_state
	new_web_config.virtual_hosts = current_vhosts.duplicate()
	
	device.web_service = master_state
	device.web_configuration = [new_web_config]
	NetworkManager.update_device_data(target_device_id, device)
