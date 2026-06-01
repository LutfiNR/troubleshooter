extends Resource

class_name MariaDBService

enum ServiceState { OFF, ON }

@export var service_state: ServiceState = ServiceState.OFF
@export var root_password: String = ""
@export var databases: Array[MariaDBDatabase] = []
@export var users: Array[MariaDBUser] = []

func authenticate(username_input: String, password_input: String) -> MariaDBUser:
	if service_state == ServiceState.OFF: return null
	
	# Cek login sebagai root
	if username_input == "root" and password_input == root_password:
		var root_user = MariaDBUser.new()
		root_user.username = "root"
		# (Di backend logika game nanti, root diasumsikan punya hak akses ke semua database)
		return root_user
		
	# Cek login user biasa
	for user in users:
		if user != null and user.username == username_input and user.password == password_input:
			return user
			
	return null

func verify_configuration(runtime_maria: MariaDBService = null) -> Dictionary:
	var runtime_root_password: Variant = null
	var runtime_databases: Dictionary = {}
	var runtime_users: Dictionary = {}

	if runtime_maria:
		runtime_root_password = runtime_maria.root_password
		for db in runtime_maria.databases:
			runtime_databases[db.db_name] = db
		for user in runtime_maria.users:
			runtime_users[user.username] = user

	var res_service_state = _verify(
		ServiceState.keys()[service_state],
		ServiceState.keys()[runtime_maria.service_state] if runtime_maria else null
	)
	var res_root_password = _verify( root_password, runtime_root_password )
	var status: bool = ( res_service_state.status and res_root_password.status )

	var res_databases := {}
	for db in databases:
		var verification = db.verify_configuration( runtime_databases.get(db.db_name) )
		res_databases[db.db_name] = verification
		status = status and verification.status

	var res_users := {}
	for user in users:
		var verification = user.verify_configuration( runtime_users.get(user.username) )
		res_users[user.username] = verification
		status = status and verification.status

	return {
		"status": status,
		"service_state": res_service_state,
		"root_password": res_root_password,
		"databases": res_databases,
		"users": res_users,
	}

func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
