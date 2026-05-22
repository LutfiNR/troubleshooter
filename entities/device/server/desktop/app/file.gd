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

var package_need: String = "samba"
var current_users: Array[SambaUser] = []
var current_shares: Array[SambaShare] = []

var current_user_index: int = -1 
var current_share_index: int = -1
var target_device_id: String = ""

func display_data(device: ServerDevice, device_id: String) -> void:
	target_device_id = device_id
	current_user_index = -1
	current_share_index = -1
	_clear_user_inputs()
	_clear_share_inputs()
	
	if device.samba_configuration.is_empty() or device.samba_configuration[0] == null:
		device.samba_configuration = [SambaService.new()]
		
	var samba_config = device.samba_configuration[0] 
	if file_service: file_service.set_pressed_no_signal(device.samba_service == ServerDevice.ServiceState.ON)
		
	current_users = samba_config.users.duplicate()
	current_shares = samba_config.shares.duplicate()
	
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
			user_list.add_item(user.username if user.username != "" else "Unnamed User")
			valid_users.add_item(user.username if user.username != "" else "Unnamed User")

func _refresh_share_list() -> void:
	share_folder_list.clear()
	for share in current_shares:
		if share: share_folder_list.add_item(share.share_name if share.share_name != "" else "Unnamed Share")

func _on_user_list_item_selected(index: int) -> void:
	current_user_index = index
	username.text = current_users[index].username
	password.text = current_users[index].password

func _on_share_folder_list_item_selected(index: int) -> void:
	current_share_index = index
	var share = current_shares[index]
	share_name.text = share.share_name
	folder_path.text = share.folder_path
	security.selected = share.security
	writeable.set_pressed_no_signal(share.writeable)
	guest_ok.set_pressed_no_signal(share.guest_ok)

func _on_add_user_button_pressed() -> void:
	var new_user = SambaUser.new()
	new_user.username = "user_" + str(current_users.size() + 1)
	current_users.append(new_user)
	_refresh_user_list()
	_apply_to_server()

func _on_add_share_button_pressed() -> void:
	var new_share = SambaShare.new()
	new_share.share_name = "share_" + str(current_shares.size() + 1)
	current_shares.append(new_share)
	_refresh_share_list()
	_apply_to_server()

func _on_delete_user_button_pressed() -> void:
	if current_user_index == -1: return
	current_users.remove_at(current_user_index)
	current_user_index = -1
	_clear_user_inputs()
	_refresh_user_list()
	_apply_to_server()

func _on_delete_share_button_pressed() -> void:
	if current_share_index == -1: return
	current_shares.remove_at(current_share_index)
	current_share_index = -1
	_clear_share_inputs()
	_refresh_share_list()
	_apply_to_server()

func _on_save_user_button_pressed() -> void:
	if current_user_index == -1: return
	current_users[current_user_index].username = username.text.strip_edges()
	current_users[current_user_index].password = password.text.strip_edges()
	_refresh_user_list()
	user_list.select(current_user_index)
	_apply_to_server()

func _on_save_share_button_pressed() -> void:
	if current_share_index == -1: return
	var share = current_shares[current_share_index]
	share.share_name = share_name.text.strip_edges()
	share.folder_path = folder_path.text.strip_edges()
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
	share_folder_list.select(current_share_index)
	_apply_to_server()

func _on_file_service_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _apply_to_server() -> void:
	if target_device_id == "": return
	var device = NetworkDeviceManager.get_device_data(target_device_id) as ServerDevice
	if not device: return
	
	var master_state = ServerDevice.ServiceState.OFF
	if file_service and file_service.button_pressed: master_state = ServerDevice.ServiceState.ON
		
	var new_samba_config = SambaService.new()
	new_samba_config.users = current_users.duplicate()
	new_samba_config.shares = current_shares.duplicate()
	
	device.samba_service = master_state
	device.samba_configuration = [new_samba_config]
	NetworkDeviceManager.update_device(target_device_id, device)
