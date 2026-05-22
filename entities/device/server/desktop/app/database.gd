extends TabBar

@export var db_service : CheckButton
@export var root_password_input : LineEdit
@export var db_list : ItemList
@export var db_name : LineEdit
@export var user_list : ItemList
@export var username : LineEdit
@export var password : LineEdit

@export_category("Grant Privileges")
@export var user_options : OptionButton
@export var db_options : OptionButton
@export var grant_list : ItemList

var package_need: String = "mariadb-server"
var current_users: Array[MariaDBUser] = []
var current_dbs: Array[MariaDBDatabase] = []

var current_db_index: int = -1
var current_user_index: int = -1
var target_device_id: String = ""

const AVAILABLE_PRIVILEGES = ["ALL PRIVILEGES", "SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP"]

func display_data(device: ServerDevice, device_id: String) -> void:
	target_device_id = device_id
	current_db_index = -1
	current_user_index = -1
	_clear_db_inputs()
	_clear_user_inputs()
	
	if device.mariadb_configuration.is_empty() or device.mariadb_configuration[0] == null:
		device.mariadb_configuration = [MariaDBService.new()]
		
	var db_config = device.mariadb_configuration[0] 
	if db_service: db_service.set_pressed_no_signal(device.mariadb_service == ServerDevice.ServiceState.ON)
	if root_password_input: root_password_input.text = db_config.root_password
		
	current_users = db_config.users.duplicate()
	current_dbs = db_config.databases.duplicate()
	
	_refresh_db_list()
	_refresh_user_list()
	_populate_privileges_dropdown()

func _clear_db_inputs() -> void:
	if db_name: db_name.text = ""
func _clear_user_inputs() -> void:
	if username: username.text = ""
	if password: password.text = ""

func _refresh_db_list() -> void:
	db_list.clear()
	for db in current_dbs:
		if db: db_list.add_item(db.db_name if db.db_name != "" else "Unnamed DB")
	_update_dropdowns()

func _refresh_user_list() -> void:
	user_list.clear()
	for user in current_users:
		if user: user_list.add_item(user.username if user.username != "" else "Unnamed User")
	_update_dropdowns()

func _populate_privileges_dropdown() -> void:
	grant_list.clear()
	for priv in AVAILABLE_PRIVILEGES:
		grant_list.add_item(priv)

func _update_dropdowns() -> void:
	user_options.clear()
	db_options.clear()
	for user in current_users: user_options.add_item(user.username)
	for db in current_dbs: db_options.add_item(db.db_name)

func _on_db_list_item_selected(index: int) -> void:
	current_db_index = index
	db_name.text = current_dbs[index].db_name

func _on_user_list_item_selected(index: int) -> void:
	current_user_index = index
	username.text = current_users[index].username
	password.text = current_users[index].password

func _on_add_db_pressed() -> void:
	var new_db = MariaDBDatabase.new()
	new_db.db_name = "new_db_" + str(current_dbs.size() + 1)
	current_dbs.append(new_db)
	_refresh_db_list()
	_apply_to_server()

func _on_add_user_pressed() -> void:
	var new_user = MariaDBUser.new()
	new_user.username = "user_" + str(current_users.size() + 1)
	current_users.append(new_user)
	_refresh_user_list()
	_apply_to_server()

func _on_delete_db_pressed() -> void:
	if current_db_index == -1: return
	current_dbs.remove_at(current_db_index)
	current_db_index = -1
	_clear_db_inputs()
	_refresh_db_list()
	_apply_to_server()

func _on_delete_user_pressed() -> void:
	if current_user_index == -1: return
	current_users.remove_at(current_user_index)
	current_user_index = -1
	_clear_user_inputs()
	_refresh_user_list()
	_apply_to_server()

func _on_save_db_pressed() -> void:
	if current_db_index == -1: return
	current_dbs[current_db_index].db_name = db_name.text.strip_edges()
	_refresh_db_list()
	db_list.select(current_db_index)
	_apply_to_server()

func _on_save_user_pressed() -> void:
	if current_user_index == -1: return
	current_users[current_user_index].username = username.text.strip_edges()
	current_users[current_user_index].password = password.text.strip_edges()
	_refresh_user_list()
	user_list.select(current_user_index)
	_apply_to_server()

func _on_grant_button_pressed() -> void:
	var u_index = user_options.selected
	var db_index = db_options.selected
	if u_index < 0 or db_index < 0: return
	
	var target_user = current_users[u_index]
	var target_db_name = current_dbs[db_index].db_name
	
	var new_privs: Array[String] = []
	for idx in grant_list.get_selected_items():
		new_privs.append(grant_list.get_item_text(idx))
		
	if new_privs.is_empty(): target_user.privileges.erase(target_db_name)
	else: target_user.privileges[target_db_name] = new_privs
		
	_apply_to_server()

func _on_root_password_input_text_changed(_new_text: String) -> void:
	_apply_to_server()

func _on_db_service_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _apply_to_server() -> void:
	if target_device_id == "": return
	var device = NetworkDeviceManager.get_device_data(target_device_id) as ServerDevice
	if not device: return
	
	var master_state = ServerDevice.ServiceState.OFF
	if db_service and db_service.button_pressed: master_state = ServerDevice.ServiceState.ON
		
	var new_db_config = MariaDBService.new()
	if root_password_input: new_db_config.root_password = root_password_input.text.strip_edges()
	new_db_config.databases = current_dbs.duplicate()
	new_db_config.users = current_users.duplicate()
	
	device.mariadb_service = master_state
	device.mariadb_configuration = [new_db_config]
	NetworkDeviceManager.update_device(target_device_id, device)
