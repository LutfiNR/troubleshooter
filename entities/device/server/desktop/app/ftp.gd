extends TabBar

const PACKAGE_NEED: String = "vsftpd"

@export var ftp_service: CheckButton
@export var ssl_enable: CheckButton
@export var local_enable: CheckButton
@export var anonymous_enable: CheckButton
@export var write_enable: CheckButton
@export var user_list: ItemList 
@export var username: LineEdit
@export var password: LineEdit
@export var home_dir: LineEdit

var current_users: Array[FTPUser] = []
var current_selected_index: int = -1 
var target_device_id: String = ""

func display_data(device: ServerDeviceData, device_id: String) -> void:
	if not user_list: return
	if target_device_id != device_id:
		target_device_id = device_id
		current_selected_index = -1
		_clear_input_fields()
	
	if device.ftp_configuration.is_empty() or device.ftp_configuration[0] == null:
		var default_config: Array[FTPService] = [FTPService.new()]
		device.ftp_configuration = default_config
		
	var ftp_config = device.ftp_configuration[0] 
	if ftp_service: ftp_service.set_pressed_no_signal(device.ftp_service == ServerDeviceData.ServiceState.ON)
	if ssl_enable: ssl_enable.set_pressed_no_signal(ftp_config.ftps_state == FTPService.ServiceState.ON)
	if local_enable: local_enable.set_pressed_no_signal(ftp_config.local_enable)
	if anonymous_enable: anonymous_enable.set_pressed_no_signal(ftp_config.anonymous_enable)
	if write_enable: write_enable.set_pressed_no_signal(ftp_config.write_enable)
		
	current_users = ftp_config.users.duplicate()
	if current_selected_index >= current_users.size():
		current_selected_index = -1
		_clear_input_fields()
		
	_refresh_list()

func _refresh_list() -> void:
	user_list.clear()
	for user in current_users:
		if user:
			user_list.add_item(user.username if user.username != "" else "New User")
			
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
		home_dir.text = user.home_directory
	else:
		_clear_input_fields()

func _get_selected_user() -> FTPUser:
	if current_selected_index < 0 or current_selected_index >= current_users.size():
		return null
	return current_users[current_selected_index]

func _clear_input_fields() -> void:
	username.text = ""
	password.text = ""
	home_dir.text = ""

func _on_add_button_pressed() -> void:
	var new_user = FTPUser.new()
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
	
	var new_username = username.text.strip_edges()
	if new_username == "":
		NetworkManager.error_configuration.emit("Username cannot be empty")
		return
		
	for i in range(current_users.size()):
		if i != current_selected_index:
			if current_users[i] != null and current_users[i].username == new_username:
				NetworkManager.error_configuration.emit("Username already exists")
				return
				
	var new_home = home_dir.text.strip_edges()
	if new_home != "" and not new_home.begins_with("/"):
		NetworkManager.error_configuration.emit("Home directory must be an absolute path starting with '/'")
		return
		
	user.username = new_username
	user.password = password.text.strip_edges()
	user.home_directory = new_home
	
	_refresh_list()
	_apply_to_server()

func _on_service_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _apply_to_server() -> void:
	if target_device_id == "": return
	var device = NetworkManager.get_runtime_device_data_by_id(target_device_id) as ServerDeviceData
	if not device: return
	
	var master_state = ServerDeviceData.ServiceState.OFF
	if ftp_service and ftp_service.button_pressed: master_state = ServerDeviceData.ServiceState.ON
		
	var new_ftp_config = FTPService.new()
	new_ftp_config.ftps_state = FTPService.ServiceState.ON if (ssl_enable and ssl_enable.button_pressed) else FTPService.ServiceState.OFF
	if local_enable: new_ftp_config.local_enable = local_enable.button_pressed
	if anonymous_enable: new_ftp_config.anonymous_enable = anonymous_enable.button_pressed
	if write_enable: new_ftp_config.write_enable = write_enable.button_pressed
	new_ftp_config.users = current_users.duplicate()
	
	device.ftp_service = master_state
	var configs: Array[FTPService] = [new_ftp_config]
	device.ftp_configuration = configs
	
	NetworkManager.update_device_data(target_device_id, device)

func _on_ftp_service_toggled(toggled_on: bool) -> void:
	_on_service_toggled(toggled_on)

func _on_ssl_enable_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _on_local_enable_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _on_anonymous_enable_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _on_write_enable_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _on_remove_button_pressed() -> void:
	_on_delete_button_pressed()
