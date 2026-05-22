extends TabBar

@export var ftp_service: CheckButton
@export var ssl_enable: CheckButton
@export var local_enable: CheckButton
@export var anonymous_enable: CheckButton
@export var write_enable: CheckButton
@export var user_list: ItemList 
@export var username: LineEdit
@export var password: LineEdit
@export var home_dir: LineEdit

var package_need: String = "vsftpd"
var current_users: Array[FTPUser] = []
var current_selected_index: int = -1 
var target_device_id: String = ""

func display_data(device: ServerDevice, device_id: String) -> void:
	if not user_list: return
	target_device_id = device_id
	current_selected_index = -1
	_clear_input_fields()
	
	if device.ftp_configuration.is_empty() or device.ftp_configuration[0] == null:
		device.ftp_configuration = [FTPService.new()]
		
	var ftp_config = device.ftp_configuration[0] 
	if ftp_service: ftp_service.set_pressed_no_signal(device.ftp_service == ServerDevice.ServiceState.ON)
	if ssl_enable: ssl_enable.set_pressed_no_signal(ftp_config.ftps_state == FTPService.ServiceState.ON)
	if local_enable: local_enable.set_pressed_no_signal(ftp_config.local_enable)
	if anonymous_enable: anonymous_enable.set_pressed_no_signal(ftp_config.anonymous_enable)
	if write_enable: write_enable.set_pressed_no_signal(ftp_config.write_enable)
		
	current_users = ftp_config.users.duplicate()
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
		home_dir.text = user.home_directory

func _clear_input_fields() -> void:
	username.text = ""
	password.text = ""
	home_dir.text = ""

func _on_add_button_pressed() -> void:
	var new_user = FTPUser.new()
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
	user.home_directory = home_dir.text.strip_edges()
	
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
	if ftp_service and ftp_service.button_pressed: master_state = ServerDevice.ServiceState.ON
		
	var new_ftp_config = FTPService.new()
	new_ftp_config.ftps_state = FTPService.ServiceState.ON if (ssl_enable and ssl_enable.button_pressed) else FTPService.ServiceState.OFF
	if local_enable: new_ftp_config.local_enable = local_enable.button_pressed
	if anonymous_enable: new_ftp_config.anonymous_enable = anonymous_enable.button_pressed
	if write_enable: new_ftp_config.write_enable = write_enable.button_pressed
	new_ftp_config.users = current_users.duplicate()
	
	device.ftp_service = master_state
	device.ftp_configuration = [new_ftp_config]
	NetworkDeviceManager.update_device(target_device_id, device)
