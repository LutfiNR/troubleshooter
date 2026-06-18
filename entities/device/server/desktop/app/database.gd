extends TabBar

const PACKAGE_NEED: String = "mariadb-server"

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

var current_users: Array[MariaDBUser] = []
var current_dbs: Array[MariaDBDatabase] = []

var current_db_index: int = -1
var current_user_index: int = -1
var target_device_id: String = ""

const AVAILABLE_PRIVILEGES = ["ALL PRIVILEGES", "SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP"]

func display_data(device: ServerDeviceData, device_id: String) -> void:
	target_device_id = device_id
	current_db_index = -1
	current_user_index = -1
	_clear_db_inputs()
	_clear_user_inputs()
	
	if device.mariadb_configuration.is_empty() or device.mariadb_configuration[0] == null:
		device.mariadb_configuration = [MariaDBService.new()]
		
	var db_config = device.mariadb_configuration[0] 
	
	if db_service:
		db_service.set_pressed_no_signal(device.mariadb_service == ServerDeviceData.ServiceState.ON)
		
	if root_password_input:
		root_password_input.text = db_config.root_password
		
	current_users = db_config.users.duplicate()
	current_dbs = db_config.databases.duplicate()
	
	if current_user_index >= current_users.size():
		current_user_index = -1
		_clear_user_inputs()
	if current_db_index >= current_dbs.size():
		current_db_index = -1
		_clear_db_inputs()
	
	_setup_grant_list()
	
	_refresh_db_list()
	_refresh_user_list()

func _setup_grant_list() -> void:
	if grant_list:
		grant_list.select_mode = ItemList.SELECT_MULTI
		grant_list.clear()
		for priv in AVAILABLE_PRIVILEGES:
			grant_list.add_item(priv)

func _refresh_db_list() -> void:
	if not db_list: return
	db_list.clear()
	for i in range(current_dbs.size()):
		var db = current_dbs[i]
		if db != null:
			var d_name = db.db_name if db.db_name != "" else "Unnamed DB"
			db_list.add_item(d_name)
			db_list.set_item_metadata(i, db)
			
	if current_db_index > -1:
		db_list.select(current_db_index)
	else:
		db_list.deselect_all()
	_refresh_options_and_grants()

func _is_db_duplicate(check_name: String, exclude_idx: int = -1) -> bool:
	for i in range(current_dbs.size()):
		if i == exclude_idx: continue
		if current_dbs[i] != null and current_dbs[i].db_name == check_name:
			return true
	return false

func _on_db_list_item_selected(index: int) -> void:
	current_db_index = index
	_refresh_db_inputs()

func _refresh_db_inputs() -> void:
	var db = _get_selected_db()
	if db:
		db_name.text = db.db_name
	else:
		_clear_db_inputs()

func _get_selected_db() -> MariaDBDatabase:
	if current_db_index < 0 or current_db_index >= current_dbs.size():
		return null
	return current_dbs[current_db_index]

func _on_add_db_button_pressed() -> void:
	var new_db = MariaDBDatabase.new()
	var final_name = "db_test"
	var counter = 1
	while _is_db_duplicate(final_name):
		final_name = "db_test" + str(counter)
		counter += 1
		
	new_db.db_name = final_name
	
	current_dbs.append(new_db)
	current_db_index = current_dbs.size() - 1
	_refresh_db_list()
	_refresh_db_inputs()

func _on_remove_db_button_pressed() -> void:
	if _get_selected_db() == null: return 
	
	var db_to_remove = current_dbs[current_db_index].db_name
	for u in current_users:
		if u != null and u.privileges.has(db_to_remove):
			u.privileges.erase(db_to_remove)
			
	current_dbs.remove_at(current_db_index)
	current_db_index = -1
	_clear_db_inputs()
	_refresh_db_list()
	_apply_to_server()

func _on_save_db_button_pressed() -> void:
	var db = _get_selected_db()
	if not db: return 
	
	var desired_name = db_name.text.strip_edges()
	if desired_name == "":
		EventManager.error_configuration.emit("Database name cannot be empty")
		return
	if _is_db_duplicate(desired_name, current_db_index):
		EventManager.error_configuration.emit("Database already exists")
		return
		
	var old_name = db.db_name
	if old_name != desired_name:
		for u in current_users:
			if u != null and u.privileges.has(old_name):
				var saved_privs = u.privileges[old_name]
				u.privileges.erase(old_name)
				u.privileges[desired_name] = saved_privs
				
	db.db_name = desired_name
	
	_refresh_db_list()
	_apply_to_server()

func _refresh_user_list() -> void:
	if not user_list: return
	user_list.clear()
	for i in range(current_users.size()):
		var user = current_users[i]
		if user != null:
			var d_name = user.username if user.username != "" else "Unnamed User"
			user_list.add_item(d_name)
			user_list.set_item_metadata(i, user)
			
	if current_user_index > -1:
		user_list.select(current_user_index)
	else:
		user_list.deselect_all()
	_refresh_options_and_grants()

func _is_user_duplicate(check_name: String, exclude_idx: int = -1) -> bool:
	for i in range(current_users.size()):
		if i == exclude_idx: continue
		if current_users[i] != null and current_users[i].username == check_name:
			return true
	return false

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

func _get_selected_user() -> MariaDBUser:
	if current_user_index < 0 or current_user_index >= current_users.size():
		return null
	return current_users[current_user_index]

func _on_add_user_button_pressed() -> void:
	var new_user = MariaDBUser.new()
	var final_name = "db_user1"
	var counter = 1
	while _is_user_duplicate(final_name):
		final_name = "db_user" + str(counter)
		counter += 1
		
	new_user.username = final_name
	new_user.password = "password123"
	var priv: Dictionary[String, Array] = {}
	new_user.privileges = priv
	
	current_users.append(new_user)
	current_user_index = current_users.size() - 1
	_refresh_user_list()
	_refresh_user_inputs()

func _on_remove_user_button_pressed() -> void:
	if _get_selected_user() == null: return 
	current_users.remove_at(current_user_index)
	current_user_index = -1
	_clear_user_inputs()
	_refresh_user_list()
	_apply_to_server()

func _on_save_user_button_pressed() -> void:
	var user = _get_selected_user()
	if not user: return 
	
	var desired_name = username.text.strip_edges()
	if desired_name == "":
		EventManager.error_configuration.emit("Username cannot be empty")
		return
	if _is_user_duplicate(desired_name, current_user_index):
		EventManager.error_configuration.emit("Username already exists")
		return
		
	user.username = desired_name
	user.password = password.text.strip_edges()
	
	_refresh_user_list()
	_apply_to_server()

func _refresh_options_and_grants() -> void:
	if user_options:
		var prev_selected_user = user_options.selected
		user_options.clear()
		for u in current_users:
			user_options.add_item(u.username if u.username != "" else "Unnamed User")
		
		if prev_selected_user >= 0 and prev_selected_user < user_options.item_count:
			user_options.select(prev_selected_user)
		elif user_options.item_count > 0:
			user_options.select(0)
			
	if db_options:
		var prev_selected_db = db_options.selected
		db_options.clear()
		for db in current_dbs:
			db_options.add_item(db.db_name if db.db_name != "" else "Unnamed DB")
		
		if prev_selected_db >= 0 and prev_selected_db < db_options.item_count:
			db_options.select(prev_selected_db)
		elif db_options.item_count > 0:
			db_options.select(0)
			
	_load_current_grant_selection()

func _on_user_option_item_selected(_index: int) -> void:
	_load_current_grant_selection()

func _on_db_option_item_selected(_index: int) -> void:
	_load_current_grant_selection()

func _load_current_grant_selection() -> void:
	if current_users.is_empty() or current_dbs.is_empty(): 
		if grant_list: grant_list.deselect_all()
		return
		
	if not user_options or not db_options or not grant_list: return
	
	var u_index = user_options.selected
	var db_index = db_options.selected
	
	if u_index < 0 or db_index < 0: return
	
	var sel_user = current_users[u_index]
	var sel_db_name = current_dbs[db_index].db_name
	
	grant_list.deselect_all()
	
	if sel_user.privileges.has(sel_db_name):
		var active_privs = sel_user.privileges[sel_db_name]
		for i in range(grant_list.item_count):
			var priv_name = grant_list.get_item_text(i)
			if active_privs.has(priv_name):
				grant_list.select(i, false)

func _on_grant_list_multi_selected(_index: int, _selected: bool) -> void:
	pass

func _on_save_grant_button_pressed() -> void:
	if current_users.is_empty() or current_dbs.is_empty(): return
	if not user_options or not db_options or not grant_list: return
	
	var u_index = user_options.selected
	var db_index = db_options.selected
	
	if u_index < 0 or db_index < 0: return
	
	var target_user = current_users[u_index]
	var target_db_name = current_dbs[db_index].db_name
	
	var new_privs: Array[String] = []
	for idx in grant_list.get_selected_items():
		new_privs.append(grant_list.get_item_text(idx))
		
	if new_privs.is_empty():
		target_user.privileges.erase(target_db_name)
	else:
		target_user.privileges[target_db_name] = new_privs
		
	_apply_to_server()


func _on_root_password_focus_exited() -> void:
	_apply_to_server()

func _on_db_service_toggled(_toggled_on: bool) -> void:
	_apply_to_server()

func _apply_to_server() -> void:
	if target_device_id == "": return
	
	var device = GameManager.get_runtime_device_data_by_id(target_device_id) as ServerDeviceData
	if not device: return
	
	var master_state = ServerDeviceData.ServiceState.OFF
	if db_service and db_service.button_pressed:
		master_state = ServerDeviceData.ServiceState.ON
		
	var new_db_config = MariaDBService.new()
	new_db_config.service_state = master_state as MariaDBService.ServiceState
	
	if root_password_input:
		new_db_config.root_password = root_password_input.text.strip_edges()
		
	new_db_config.databases = current_dbs.duplicate()
	new_db_config.users = current_users.duplicate()
	
	device.mariadb_service = master_state
	var configs: Array[MariaDBService] = [new_db_config]
	device.mariadb_configuration = configs
	GameManager.update_device_data(target_device_id, device)

func _clear_db_inputs() -> void:
	if db_name: db_name.text = ""

func _clear_user_inputs() -> void:
	if username: username.text = ""
	if password: password.text = ""
