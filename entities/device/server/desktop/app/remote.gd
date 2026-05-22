extends TabBar

@export var remote_service: CheckButton
@export var telnet_enable: CheckButton
@export var ssh_enable: CheckButton
@export var ssh_port: LineEdit
@export var permit_root_login: CheckButton
@export var user_list: ItemList 
@export var username: LineEdit
@export var password: LineEdit

var package_need: String = "openssh-server"
var current_users: Array[RemoteUser] = []
var current_selected_index: int = -1 
var target_device_id: String = ""

func display_data(device: ServerDevice, device_id: String) -> void:
	if not user_list: return
	target_device_id = device_id
	current_selected_index = -1
	_clear_input_fields()
	
	if device.remote_configuration.is_empty() or device.remote_configuration[0] == null:
		device.remote_configuration = [RemoteService.new()]
		
	var remote_config = device.remote_configuration[0] 
	if remote_service: remote_service.set_pressed_no_signal(device.remote_service == ServerDevice.ServiceState.ON)
	if telnet_enable: telnet_enable.set_pressed_no_signal(remote_config.telnet_state == RemoteService.ServiceState.ON)
	if ssh_enable: ssh_enable.set_pressed_no_signal(remote_config.ssh_state == RemoteService.ServiceState.ON)
	if permit_root_login: permit_root_login.set_pressed_no_signal(remote_config.permit_root_login)
	if ssh_port: ssh_port.text = str(remote_config.ssh_port)
		
	current_users = remote_config.users.duplicate()
	_refresh_list()

func _refresh_list() -> void:
	user_list.clear()
	for user in current_users:
		if user: user_list.add_item(user.username if user.username != "" else "New User")

func _on_user_list_item_selected(index: int) -> void:
	current_selected_index = index
	var user = current_users[index]
	if user:
		username.text = user.username
		password.text = user.password

func _clear_input_fields() -> void:
	username.text = ""
	password.text = ""

func _on_add_button_pressed() -> void:
	var new_user = RemoteUser.new()
	new_user.username = "user" + str(current_users.size() + 1)
	current_users.append(new_user)
	_refresh_list()
	_apply_to_server()

func _on_delete_button_pressed() -> void:
	if current_selected_index == -1: return
	current_users.remove_at(current_selected_index)
	current_selected_index = -1
	_clear_input_fields()
	_refresh_list()
	_apply_to_server()

func _on_save_button_pressed() -> void:
	if current_selected_index == -1: return
	var user = current_users[current_selected_index]
	user.username = username.text.strip_edges()
	user.password = password.text.strip_edges()
	
	_refresh_list()
	user_list.select(current_selected_index)
	_apply_to_server()

func _on_service_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _apply_to_server() -> void:
	if target_device_id == "": return
	var device = NetworkDeviceManager.get_device_data(target_device_id) as ServerDevice
	if not device: return
	
	var master_state = ServerDevice.ServiceState.OFF
	if remote_service and remote_service.button_pressed: master_state = ServerDevice.ServiceState.ON
		
	var new_remote_config = RemoteService.new()
	new_remote_config.telnet_state = RemoteService.ServiceState.ON if (telnet_enable and telnet_enable.button_pressed) else RemoteService.ServiceState.OFF
	new_remote_config.ssh_state = RemoteService.ServiceState.ON if (ssh_enable and ssh_enable.button_pressed) else RemoteService.ServiceState.OFF
		
	if ssh_port:
		var port_val = ssh_port.text.to_int()
		new_remote_config.ssh_port = port_val if port_val > 0 else 22
	if permit_root_login:
		new_remote_config.permit_root_login = permit_root_login.button_pressed
		
	new_remote_config.users = current_users.duplicate()
	device.remote_service = master_state
	device.remote_configuration = [new_remote_config]
	NetworkDeviceManager.update_device(target_device_id, device)
