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

var package_need: String = "postfix" 
var current_users: Array[MailUser] = []
var current_selected_index: int = -1 
var target_device_id: String = ""

func display_data(device: ServerDevice, device_id: String) -> void:
	if not user_list: return
	target_device_id = device_id
	current_selected_index = -1
	_clear_input_fields()
	
	if device.mail_configuration.is_empty() or device.mail_configuration[0] == null:
		device.mail_configuration = [MailService.new()]
		
	var mail_config = device.mail_configuration[0] 
	if mail_service: mail_service.set_pressed_no_signal(device.mail_service == ServerDevice.ServiceState.ON)
	if domain_name: domain_name.text = mail_config.domain_name
	if mailbox_format: mailbox_format.selected = 1 if mail_config.mailbox_format == "Maildir" else 0
	if use_ssl_tls: use_ssl_tls.set_pressed_no_signal(mail_config.use_ssl_tls)
	if cert_file_path: cert_file_path.text = mail_config.cert_file_path
	if key_file_path: key_file_path.text = mail_config.key_file_path
		
	current_users = mail_config.users.duplicate()
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
	var new_user = MailUser.new()
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
	if mail_service and mail_service.button_pressed: master_state = ServerDevice.ServiceState.ON
		
	var new_mail_config = MailService.new()
	if domain_name: new_mail_config.domain_name = domain_name.text.strip_edges()
	if mailbox_format: new_mail_config.mailbox_format = "Maildir" if mailbox_format.selected == 1 else "mbox"
	if use_ssl_tls: new_mail_config.use_ssl_tls = use_ssl_tls.button_pressed
	if cert_file_path: new_mail_config.cert_file_path = cert_file_path.text.strip_edges()
	if key_file_path: new_mail_config.key_file_path = key_file_path.text.strip_edges()
	
	new_mail_config.users = current_users.duplicate()
	device.mail_service = master_state
	device.mail_configuration = [new_mail_config]
	NetworkDeviceManager.update_device(target_device_id, device)
