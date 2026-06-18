extends Control

@export var ssl_icon: TextureRect
@export var secure_texture: Texture2D
@export var unsecure_texture: Texture2D
@export var path: LineEdit
@export var content_list: ItemList
@export var credential_popup: Panel
@export var credential_username: LineEdit 
@export var credential_password: LineEdit
@export var validation_label: Label

@export var file_texture: Texture2D
@export var folder_texture: Texture2D
@export var button_container: HBoxContainer
@export var upload_button: Button
@export var delete_button: Button

@export var local_items: Array[FileExplorerItem] = []
@export var network_items: Array[FileExplorerItem] = []

enum Protocol { LOCAL, FTP, SMB }

var target_device_id: String
var target_ip: String = ""

var is_secure_request: bool = false
var is_logged_in: bool = false
var current_write_enable: bool = false
var current_selected_index: int = -1
var current_protocol: Protocol = Protocol.LOCAL
var current_smb_share_name: String = ""

func setup(device_id: String) -> void:
	target_device_id = device_id
	
	if path and not path.text_submitted.is_connected(_on_path_text_submitted):
		path.text_submitted.connect(_on_path_text_submitted)
		
	_load_local_files()
	refresh_data()

func refresh_data() -> void:
	if target_device_id == "": return
	if upload_button: upload_button.disabled = not current_write_enable
	if delete_button: delete_button.disabled = not current_write_enable

func _load_local_files() -> void:
	var device = GameManager.get_runtime_device_data_by_id(target_device_id)
	if device:
		path.text = "/" + device.device_id
		
	content_list.clear()
	current_selected_index = -1
	if ssl_icon: ssl_icon.texture = null
	if button_container: button_container.visible = false
	
	is_logged_in = false
	current_write_enable = true
	
	for item in local_items:
		var index = content_list.add_item(item.file_or_folder_name)
		var tex = folder_texture if item.type == FileExplorerItem.ItemType.FOLDER else file_texture
		content_list.set_item_icon(index, tex)
		
	refresh_data()

func _on_path_text_submitted(new_text: String) -> void:
	var input_path = new_text.strip_edges()
	
	if not is_path_network(input_path):
		_load_local_files()
		return

	if input_path.begins_with("smb://"):
		_handle_smb_path(input_path)
	else:
		_handle_ftp_path(input_path)


func _handle_ftp_path(input_path: String) -> void:
	current_protocol = Protocol.FTP
	is_secure_request = input_path.begins_with("ftps://")
	var request_url = input_path.replace("ftps://", "").replace("ftp://", "").strip_edges()
	
	if "/" in request_url:
		request_url = request_url.split("/")[0]
		
	target_ip = request_url
	
	if not _is_valid_ip(request_url):
		target_ip = GameManager.request_dns_resolve(target_device_id, request_url)
		if target_ip == "":
			_show_error("DNS Error: Domain '" + request_url + "' not found or server unreachable.")
			return

	var server = GameManager._find_server_by_ip(target_ip)
	if not server or server.ftp_service == ServerDeviceData.ServiceState.OFF:
		_show_error("Error: Connection refused. FTP Service is OFF.")
		return

	# Cegah enkripsi silang jika tidak didukung pengaturan server
	var ftp_obj = server.handle_ftp_request()
	if is_secure_request and ftp_obj.ftps_state == FTPService.ServiceState.OFF:
		_show_error("Error: Server does not support SSL/TLS encryption (FTPS).")
		return

	open_credential_popup()


func _handle_smb_path(input_path: String) -> void:
	current_protocol = Protocol.SMB
	is_secure_request = false
	var request_url = input_path.replace("smb://", "").strip_edges()

	# Parse smb://host/share_name
	var host_part: String = request_url
	current_smb_share_name = ""
	if "/" in request_url:
		var parts = request_url.split("/", true, 1)
		host_part = parts[0]
		if parts.size() > 1:
			current_smb_share_name = parts[1].strip_edges()

	target_ip = host_part

	if not _is_valid_ip(host_part):
		target_ip = GameManager.request_dns_resolve(target_device_id, host_part)
		if target_ip == "":
			_show_error("DNS Error: Domain '" + host_part + "' not found or server unreachable.")
			return

	var server = GameManager._find_server_by_ip(target_ip)
	if not server or server.samba_service == ServerDeviceData.ServiceState.OFF:
		_show_error("Error: Connection refused. Samba Service is OFF.")
		return

	var samba_config = server.handle_samba_request()
	if not samba_config:
		_show_error("Error: Samba service has no configuration.")
		return

	# If a share name is specified, validate it exists
	if current_smb_share_name != "":
		var share = samba_config.get_share(current_smb_share_name)
		if not share:
			_show_error("Error: Share '" + current_smb_share_name + "' not found.")
			return
		# If guest access is allowed and security is NONE, skip login
		if share.guest_ok and share.security == SambaShare.SecurityType.NONE:
			is_logged_in = true
			current_write_enable = share.writeable
			if ssl_icon: ssl_icon.texture = unsecure_texture
			_load_smb_share_files(share)
			refresh_data()
			return

	open_credential_popup()

func is_path_network(check_path: String) -> bool:
	return (check_path.begins_with("ftp://")
		or check_path.begins_with("ftps://")
		or check_path.begins_with("smb://"))

func open_credential_popup() -> void:
	if credential_username: credential_username.text = ""
	if credential_password: credential_password.text = ""
	if validation_label: validation_label.text = ""
	credential_popup.show()

func close_credential_popup() -> void:
	credential_popup.hide()

func _on_credential_login_button_pressed() -> void:
	var input_user = ""
	var input_pass = ""
	if credential_username: input_user = credential_username.text.strip_edges()
	if credential_password: input_pass = credential_password.text.strip_edges()

	if current_protocol == Protocol.SMB:
		_handle_smb_login(input_user, input_pass)
	else:
		_handle_ftp_login(input_user, input_pass)


func _handle_ftp_login(input_user: String, input_pass: String) -> void:
	var response = GameManager.request_ftp_login(target_ip, input_user, input_pass)
	
	if response.success:
		close_credential_popup()
		is_logged_in = true
		
		var server = GameManager._find_server_by_ip(target_ip)
		if server and server.handle_ftp_request():
			current_write_enable = server.handle_ftp_request().write_enable
			
		path.text = path.text + response.home_dir
		
		if ssl_icon:
			ssl_icon.texture = secure_texture if is_secure_request else unsecure_texture
		
		_load_ftp_dummy_files()
		refresh_data()
	else:
		if credential_password: credential_password.text = ""
		validation_label.text = response.error


func _handle_smb_login(input_user: String, input_pass: String) -> void:
	var response = GameManager.request_samba_login(target_ip, input_user, input_pass)

	if response.success:
		close_credential_popup()
		is_logged_in = true

		var server = GameManager._find_server_by_ip(target_ip)
		if not server:
			_show_error("Error: Server not found.")
			return

		var samba_config = server.handle_samba_request()
		if not samba_config:
			_show_error("Error: Samba configuration not found.")
			return

		if ssl_icon: ssl_icon.texture = unsecure_texture

		if current_smb_share_name != "":
			# Access specific share
			var share = samba_config.get_share(current_smb_share_name)
			if not share:
				_show_error("Error: Share '" + current_smb_share_name + "' not found.")
				return
			# Check if user is in valid_users (when security is USER)
			if share.security == SambaShare.SecurityType.USER:
				var user_allowed := false
				for u in share.valid_users:
					if u != null and u.username == input_user:
						user_allowed = true
						break
				if not user_allowed:
					_show_error("Error: Access denied to share '" + current_smb_share_name + "'.")
					return
			current_write_enable = share.writeable
			_load_smb_share_files(share)
		else:
			# No share specified — list all available shares
			_load_smb_share_list(samba_config)

		refresh_data()
	else:
		if credential_password: credential_password.text = ""
		validation_label.text = response.error

func _on_credential_cancel_button_pressed() -> void:
	if validation_label: validation_label.text = "" 
	close_credential_popup()

func _load_ftp_dummy_files() -> void:
	content_list.clear()
	current_selected_index = -1
	if button_container: button_container.visible = true
	
	for item in network_items:
		var index = content_list.add_item(item.file_or_folder_name)
		var tex = folder_texture if item.type == FileExplorerItem.ItemType.FOLDER else file_texture
		content_list.set_item_icon(index, tex)


func _load_smb_share_list(samba_config: SambaService) -> void:
	content_list.clear()
	current_selected_index = -1
	current_write_enable = false
	if button_container: button_container.visible = false

	for share in samba_config.shares:
		if share != null:
			var index = content_list.add_item(share.share_name)
			content_list.set_item_icon(index, folder_texture)


func _load_smb_share_files(share: SambaShare) -> void:
	content_list.clear()
	current_selected_index = -1
	if button_container: button_container.visible = share.writeable

	path.text = "smb://" + target_ip + "/" + share.share_name

	for item in network_items:
		var index = content_list.add_item(item.file_or_folder_name)
		var tex = folder_texture if item.type == FileExplorerItem.ItemType.FOLDER else file_texture
		content_list.set_item_icon(index, tex)

func _on_content_list_item_selected(index: int) -> void:
	current_selected_index = index

func _on_upload_button_pressed() -> void:
	if not current_write_enable: return
	var new_file_name = "uploaded_file_" + str(randi() % 1000) + ".txt"
	var index = content_list.add_item(new_file_name)
	content_list.set_item_icon(index, file_texture)

func _on_delete_button_pressed() -> void:
	if not current_write_enable or current_selected_index == -1: return
	content_list.remove_item(current_selected_index)
	current_selected_index = -1

func _show_error(msg: String) -> void:
	content_list.clear()
	content_list.add_item(msg)
	if ssl_icon: ssl_icon.texture = unsecure_texture

func _is_valid_ip(text: String) -> bool:
	var parts = text.split(".")
	if parts.size() != 4: return false
	for p in parts:
		if not p.is_valid_int(): return false
	return true
