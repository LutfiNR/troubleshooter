extends TabBar

@export var mail_service : CheckButton
@export_category("Global Settings")
@export var domain_name : LineEdit
@export var mailbox_format : OptionButton 
@export_category("Security")
@export var use_ssl_tls : CheckButton
@export var cert_file_path : LineEdit
@export var key_file_path : LineEdit
@export_category("User Management")
@export var user_list : ItemList
@export var username : LineEdit
@export var password : LineEdit

const PACKAGE_NEED: String = "postfix" 
var current_users: Array[MailUser] = []
var current_selected_index: int = -1 
var target_device_id: String = ""

func display_data(device: ServerDeviceData, device_id: String) -> void:
	if not user_list: return
	target_device_id = device_id
	current_selected_index = -1
	_clear_input_fields()
	
	if device.mail_configuration.is_empty() or device.mail_configuration[0] == null:
		device.mail_configuration = [MailService.new()]
		
	var mail_config = device.mail_configuration[0] 
	
	if mail_service:
		mail_service.set_pressed_no_signal(device.mail_service == ServerDeviceData.ServiceState.ON)
		
	if domain_name: domain_name.text = mail_config.domain_name
	
	if mailbox_format:
		var format_idx = 0 if mail_config.mailbox_format == "mbox" else 1
		mailbox_format.select(format_idx)
		
	if use_ssl_tls:
		use_ssl_tls.set_pressed_no_signal(mail_config.use_ssl_tls)
	if cert_file_path: cert_file_path.text = mail_config.cert_file_path
	if key_file_path: key_file_path.text = mail_config.key_file_path
		
	current_users = mail_config.users.duplicate()
	if current_selected_index >= current_users.size():
		current_selected_index = -1
		_clear_input_fields()
		
	_refresh_user_list()

func _clear_input_fields() -> void:
	if username: username.text = ""
	if password: password.text = ""

func _refresh_user_list() -> void:
	user_list.clear()
	for i in range(current_users.size()):
		var user = current_users[i]
		if user != null:
			var domain = domain_name.text if domain_name and domain_name.text != "" else "domain.com"
			var display_text = user.username + "@" + domain
			user_list.add_item(display_text)
			
	if current_selected_index > -1:
		user_list.select(current_selected_index)
	else:
		user_list.deselect_all()

func _is_user_duplicate(check_name: String, exclude_idx: int = -1) -> bool:
	for i in range(current_users.size()):
		if i == exclude_idx: continue
		if current_users[i] != null and current_users[i].username == check_name:
			return true
	return false

func _on_user_list_item_selected(index: int) -> void:
	current_selected_index = index
	_refresh_user_inputs()

func _refresh_user_inputs() -> void:
	var user = _get_selected_user()
	if user:
		username.text = user.username
		password.text = user.password
	else:
		_clear_input_fields()

func _get_selected_user() -> MailUser:
	if current_selected_index < 0 or current_selected_index >= current_users.size():
		return null
	return current_users[current_selected_index]

func _on_add_user_button_pressed() -> void:
	var new_user = MailUser.new()
	var final_name = "mailuser"
	var counter = 1
	while _is_user_duplicate(final_name):
		final_name = "mailuser" + str(counter)
		counter += 1
		
	new_user.username = final_name
	new_user.password = "password123"
	
	current_users.append(new_user)
	current_selected_index = current_users.size() - 1
	_refresh_user_list()
	_refresh_user_inputs()

func _on_remove_user_button_pressed() -> void:
	if _get_selected_user() == null: return 
	current_users.remove_at(current_selected_index)
	current_selected_index = -1
	_clear_input_fields()
	_refresh_user_list()
	_apply_to_server()

func _on_save_user_button_pressed() -> void:
	var user = _get_selected_user()
	if not user: return 
	var desired_username = username.text.strip_edges()
	
	if desired_username == "":
		EventManager.error_configuration.emit("Username cannot be empty")
		return
	if _is_user_duplicate(desired_username, current_selected_index):
		EventManager.error_configuration.emit("Username already exists")
		return
	
	user.username = desired_username
	user.password = password.text.strip_edges()
	
	_refresh_user_list()
	_apply_to_server()

func _on_mail_service_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _on_domain_name_focus_exited() -> void:
	_refresh_user_list()
	_apply_to_server()

func _apply_to_server() -> void:
	if target_device_id == "": return
	
	var device = GameManager.get_runtime_device_data_by_id(target_device_id) as ServerDeviceData
	if not device: return
	
	var master_state = ServerDeviceData.ServiceState.OFF
	if mail_service and mail_service.button_pressed:
		master_state = ServerDeviceData.ServiceState.ON
		
	var domain = domain_name.text.strip_edges() if domain_name else ""
	if domain != "" and not _validate_domain(domain):
		EventManager.error_configuration.emit("Invalid domain format")
		return
		
	var new_mail_config = MailService.new()
	new_mail_config.service_state = master_state as MailService.ServiceState
	
	if domain_name: new_mail_config.domain_name = domain
	if mailbox_format: new_mail_config.mailbox_format = "Maildir" if mailbox_format.selected == 1 else "mbox"
	if use_ssl_tls: new_mail_config.use_ssl_tls = use_ssl_tls.button_pressed
	if cert_file_path: new_mail_config.cert_file_path = cert_file_path.text.strip_edges()
	if key_file_path: new_mail_config.key_file_path = key_file_path.text.strip_edges()
	
	new_mail_config.users = current_users.duplicate()
	
	device.mail_service = master_state
	var configs: Array[MailService] = [new_mail_config]
	device.mail_configuration = configs
	GameManager.update_device_data(target_device_id, device)

func _validate_domain(domain: String) -> bool:
	var trimmed = domain.strip_edges()
	if trimmed == "":
		return true
	
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9][-a-zA-Z0-9]*(\\.[a-zA-Z0-9][-a-zA-Z0-9]*)+$")
	var result = regex.search(trimmed)
	return result != null

func _on_use_ssl_tls_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if cert_file_path and cert_file_path.text.strip_edges() == "":
			cert_file_path.text = "/etc/ssl/certs/server.crt"
		if key_file_path and key_file_path.text.strip_edges() == "":
			key_file_path.text = "/etc/ssl/private/server.key"
	else:
		if cert_file_path: cert_file_path.text = ""
		if key_file_path: key_file_path.text = ""
		
	_apply_to_server()
