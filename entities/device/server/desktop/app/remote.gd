extends TabBar

const PACKAGE_NEED: String = "openssh-server"

@export var remote_service: CheckButton
@export var telnet_enable: CheckButton
@export var ssh_enable: CheckButton
@export var ssh_port: LineEdit
@export var permit_root_login: CheckButton
@export var user_list: ItemList 
@export var username: LineEdit
@export var password: LineEdit

var current_users: Array[RemoteUser] = []
var current_selected_index: int = -1 
var target_device_id: String = ""

func display_data(device: ServerDeviceData, device_id: String) -> void:
	if not user_list: return
	target_device_id = device_id
	current_selected_index = -1
	_clear_input_fields()
	
	if device.remote_configuration.is_empty() or device.remote_configuration[0] == null:
		device.remote_configuration = [RemoteService.new()]
		
	var remote_config = device.remote_configuration[0] 
	if remote_service: remote_service.set_pressed_no_signal(device.remote_service == ServerDeviceData.ServiceState.ON)
	if telnet_enable: telnet_enable.set_pressed_no_signal(remote_config.telnet_state == RemoteService.ServiceState.ON)
	if ssh_enable: ssh_enable.set_pressed_no_signal(remote_config.ssh_state == RemoteService.ServiceState.ON)
	if permit_root_login: permit_root_login.set_pressed_no_signal(remote_config.permit_root_login)
	if ssh_port: ssh_port.text = str(remote_config.ssh_port)
		
	current_users = remote_config.users.duplicate()
	if current_selected_index >= current_users.size():
		current_selected_index = -1
		_clear_input_fields()
		
	_refresh_list()

func _refresh_list() -> void:
	user_list.clear()
	for user in current_users:
		if user: user_list.add_item(user.username if user.username != "" else "New User")
		
	if current_selected_index > -1:
		user_list.select(current_selected_index)
	else:
		user_list.deselect_all()

func _on_user_list_item_selected(index: int) -> void:
	current_selected_index = index
	_refresh_input_fields()

func _refresh_input_fields() -> void:
	var user = _get_selected_user()
	if user:
		username.text = user.username
		password.text = user.password
	else:
		_clear_input_fields()

func _get_selected_user() -> RemoteUser:
	if current_selected_index < 0 or current_selected_index >= current_users.size():
		return null
	return current_users[current_selected_index]

func _clear_input_fields() -> void:
	username.text = ""
	password.text = ""

func _on_add_button_pressed() -> void:
	var new_user = RemoteUser.new()
	new_user.username = "user" + str(current_users.size() + 1)
	current_users.append(new_user)
	current_selected_index = current_users.size() - 1
	_refresh_list()
	_refresh_input_fields()

func _on_delete_button_pressed() -> void:
	if _get_selected_user() == null: return
	current_users.remove_at(current_selected_index)
	current_selected_index = -1
	_clear_input_fields()
	_refresh_list()
	_apply_to_server()

func _on_save_button_pressed() -> void:
	var user = _get_selected_user()
	if not user: return
	
	var desired_name = username.text.strip_edges()
	if desired_name == "":
		EventManager.error_configuration.emit("Username cannot be empty")
		return
	if _is_user_duplicate(desired_name, current_selected_index):
		EventManager.error_configuration.emit("Username already exists")
		return
		
	user.username = desired_name
	user.password = password.text.strip_edges()
	
	_refresh_list()
	_apply_to_server()

func _is_user_duplicate(check_name: String, exclude_idx: int = -1) -> bool:
	for i in range(current_users.size()):
		if i == exclude_idx: continue
		if current_users[i] != null and current_users[i].username == check_name:
			return true
	return false

func _on_service_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _apply_to_server() -> void:
	if target_device_id == "": return
	var device = GameManager.get_runtime_device_data_by_id(target_device_id) as ServerDeviceData
	if not device: return
	
	var master_state = ServerDeviceData.ServiceState.OFF
	if remote_service and remote_service.button_pressed: master_state = ServerDeviceData.ServiceState.ON
		
	var new_remote_config = RemoteService.new()
	new_remote_config.telnet_state = RemoteService.ServiceState.ON if (telnet_enable and telnet_enable.button_pressed) else RemoteService.ServiceState.OFF
	new_remote_config.ssh_state = RemoteService.ServiceState.ON if (ssh_enable and ssh_enable.button_pressed) else RemoteService.ServiceState.OFF
		
	if ssh_port:
		var port_val = ssh_port.text.strip_edges().to_int()
		if port_val <= 0 or port_val > 65535:
			EventManager.error_configuration.emit("Invalid SSH Port (must be 1-65535)")
			return
		new_remote_config.ssh_port = port_val
	if permit_root_login:
		new_remote_config.permit_root_login = permit_root_login.button_pressed
		
	new_remote_config.users = current_users.duplicate()
	device.remote_service = master_state
	var configs: Array[RemoteService] = [new_remote_config]
	device.remote_configuration = configs
	GameManager.update_device_data(target_device_id, device)

func _on_ssh_port_text_changed(_new_text: String) -> void:
	_apply_to_server()
