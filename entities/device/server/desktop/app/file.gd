extends TabBar

@export var file_service: CheckButton
@export var share_folder_list: ItemList 
@export var share_name: LineEdit
@export var folder_path: LineEdit
@export var valid_users: ItemList 
@export var security: OptionButton
@export var writeable: CheckButton
@export var guest_ok: CheckButton
@export var user_list: ItemList
@export var username: LineEdit
@export var password: LineEdit

const PACKAGE_NEED: String = "samba"
var current_users: Array[SambaUser] = []
var current_shares: Array[SambaShare] = []

var current_user_index: int = -1 
var current_share_index: int = -1
var target_device_id: String = ""

func display_data(device: ServerDeviceData, device_id: String) -> void:
	target_device_id = device_id
	current_user_index = -1
	current_share_index = -1
	_clear_user_inputs()
	_clear_share_inputs()
	
	if device.samba_configuration.is_empty() or device.samba_configuration[0] == null:
		device.samba_configuration = [SambaService.new()]
		
	var samba_config = device.samba_configuration[0] 
	if file_service: file_service.set_pressed_no_signal(device.samba_service == ServerDeviceData.ServiceState.ON)
		
	current_users = samba_config.users.duplicate()
	current_shares = samba_config.shares.duplicate()
	
	if current_user_index >= current_users.size():
		current_user_index = -1
		_clear_user_inputs()
	if current_share_index >= current_shares.size():
		current_share_index = -1
		_clear_share_inputs()
		
	_refresh_user_list()
	_refresh_share_list()

func _clear_user_inputs() -> void:
	if username: username.text = ""
	if password: password.text = ""

func _clear_share_inputs() -> void:
	if share_name: share_name.text = ""
	if folder_path: folder_path.text = ""

func _refresh_user_list() -> void:
	user_list.clear()
	valid_users.clear()
	for user in current_users:
		if user: 
			var name_str = user.username if user.username != "" else "Unnamed User"
			user_list.add_item(name_str)
			valid_users.add_item(name_str)
			
	if current_user_index > -1:
		user_list.select(current_user_index)
	else:
		user_list.deselect_all()

func _refresh_share_list() -> void:
	share_folder_list.clear()
	for share in current_shares:
		if share: 
			share_folder_list.add_item(share.share_name if share.share_name != "" else "Unnamed Share")
			
	if current_share_index > -1:
		share_folder_list.select(current_share_index)
	else:
		share_folder_list.deselect_all()

func _on_user_list_item_selected(index: int) -> void:
	current_user_index = index
	_refresh_user_inputs()

func _refresh_user_inputs() -> void:
	var user = _get_selected_user()
	if user:
		username.text = user.username
		password.text = user.password
	else:
		_clear_user_inputs()

func _get_selected_user() -> SambaUser:
	if current_user_index < 0 or current_user_index >= current_users.size():
		return null
	return current_users[current_user_index]

func _on_share_folder_list_item_selected(index: int) -> void:
	current_share_index = index
	_refresh_share_inputs()

func _refresh_share_inputs() -> void:
	var share = _get_selected_share()
	if share:
		share_name.text = share.share_name
		folder_path.text = share.folder_path
		security.selected = share.security
		writeable.set_pressed_no_signal(share.writeable)
		guest_ok.set_pressed_no_signal(share.guest_ok)
		
		# Select valid users
		valid_users.deselect_all()
		for u in share.valid_users:
			if u != null:
				for i in range(valid_users.item_count):
					if valid_users.get_item_text(i) == u.username:
						valid_users.select(i)
	else:
		_clear_share_inputs()

func _get_selected_share() -> SambaShare:
	if current_share_index < 0 or current_share_index >= current_shares.size():
		return null
	return current_shares[current_share_index]

func _on_add_user_button_pressed() -> void:
	var new_user = SambaUser.new()
	new_user.username = "user_" + str(current_users.size() + 1)
	current_users.append(new_user)
	current_user_index = current_users.size() - 1
	_refresh_user_list()
	_refresh_user_inputs()

func _on_add_share_button_pressed() -> void:
	var new_share = SambaShare.new()
	new_share.share_name = "share_" + str(current_shares.size() + 1)
	current_shares.append(new_share)
	current_share_index = current_shares.size() - 1
	_refresh_share_list()
	_refresh_share_inputs()

func _on_delete_user_button_pressed() -> void:
	var user = _get_selected_user()
	if user == null: return
	
	# Clean up user from valid_users in shares
	var deleted_username = user.username
	for s in current_shares:
		if s != null:
			var filtered_users: Array[SambaUser] = []
			for u in s.valid_users:
				if u != null and u.username != deleted_username:
					filtered_users.append(u)
			s.valid_users = filtered_users
			
	current_users.remove_at(current_user_index)
	current_user_index = -1
	_clear_user_inputs()
	_refresh_user_list()
	_refresh_share_inputs()
	_apply_to_server()

func _on_delete_share_button_pressed() -> void:
	if _get_selected_share() == null: return
	current_shares.remove_at(current_share_index)
	current_share_index = -1
	_clear_share_inputs()
	_refresh_share_list()
	_apply_to_server()

func _on_save_user_button_pressed() -> void:
	var user = _get_selected_user()
	if not user: return
	
	var desired_name = username.text.strip_edges()
	if desired_name == "":
		NetworkManager.error_configuration.emit("Username cannot be empty")
		return
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_-]+$")
	if not regex.search(desired_name):
		NetworkManager.error_configuration.emit("Username can only contain alphanumeric characters, dashes, and underscores")
		return
	if _is_user_duplicate(desired_name, current_user_index):
		NetworkManager.error_configuration.emit("Username already exists")
		return
		
	# Update key username in share.valid_users if changed
	var old_username = user.username
	if old_username != desired_name:
		for s in current_shares:
			if s != null:
				for u in s.valid_users:
					if u != null and u.username == old_username:
						u.username = desired_name
						
	user.username = desired_name
	user.password = password.text.strip_edges()
	_refresh_user_list()
	_refresh_share_inputs()
	_apply_to_server()

func _is_user_duplicate(check_name: String, exclude_idx: int = -1) -> bool:
	for i in range(current_users.size()):
		if i == exclude_idx: continue
		if current_users[i] != null and current_users[i].username == check_name:
			return true
	return false

func _on_save_share_button_pressed() -> void:
	var share = _get_selected_share()
	if not share: return
	
	var desired_name = share_name.text.strip_edges()
	var desired_path = folder_path.text.strip_edges()
	if desired_name == "":
		NetworkManager.error_configuration.emit("Share name cannot be empty")
		return
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_-]+$")
	if not regex.search(desired_name):
		NetworkManager.error_configuration.emit("Share name can only contain alphanumeric characters, dashes, and underscores")
		return
	if desired_path == "":
		NetworkManager.error_configuration.emit("Folder path cannot be empty")
		return
	if not desired_path.begins_with("/"):
		NetworkManager.error_configuration.emit("Folder path must be an absolute path starting with '/'")
		return
	var path_regex = RegEx.new()
	path_regex.compile("^/[a-zA-Z0-9_.-]*(/[a-zA-Z0-9_.-]*)*$")
	if not path_regex.search(desired_path):
		NetworkManager.error_configuration.emit("Folder path contains invalid characters")
		return
	if _is_share_duplicate(desired_name, current_share_index):
		NetworkManager.error_configuration.emit("Share name already exists")
		return
		
	share.share_name = desired_name
	share.folder_path = desired_path
	share.security = security.selected as SambaShare.SecurityType
	share.writeable = writeable.button_pressed
	share.guest_ok = guest_ok.button_pressed
	
	var selected_user_objects: Array[SambaUser] = []
	for idx in valid_users.get_selected_items():
		var selected_name = valid_users.get_item_text(idx)
		for u in current_users:
			if u != null and u.username == selected_name:
				selected_user_objects.append(u)
				break
	share.valid_users = selected_user_objects
	
	_refresh_share_list()
	_apply_to_server()

func _is_share_duplicate(check_name: String, exclude_idx: int = -1) -> bool:
	for i in range(current_shares.size()):
		if i == exclude_idx: continue
		if current_shares[i] != null and current_shares[i].share_name == check_name:
			return true
	return false

func _on_file_service_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _apply_to_server() -> void:
	if target_device_id == "": return
	var device = NetworkManager.get_runtime_device_data_by_id(target_device_id) as ServerDeviceData
	if not device: return
	
	var master_state = ServerDeviceData.ServiceState.OFF
	if file_service and file_service.button_pressed: master_state = ServerDeviceData.ServiceState.ON
		
	var new_samba_config = SambaService.new()
	new_samba_config.users = current_users.duplicate()
	new_samba_config.shares = current_shares.duplicate()
	device.samba_service = master_state
	var configs: Array[SambaService] = [new_samba_config]
	device.samba_configuration = configs
	NetworkManager.update_device_data(target_device_id, device)
