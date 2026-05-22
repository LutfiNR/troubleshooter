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

func verify_configuration(correct_maria: MariaDBService) -> Dictionary:
	if not correct_maria:
		return { "status": false, "error": "Invalid MariaDB config" }

	var is_correct = true
	var result = {
		"status": false,
		"service_state": { "status": service_state == correct_maria.service_state },
		"root_password": { "status": root_password == correct_maria.root_password },
		"databases": { "status": true, "details": { } },
		"users": { "status": true, "details": { } },
	}

	if not result.service_state.status or not result.root_password.status:
		is_correct = false

	# Verify Databases
	for c_db in correct_maria.databases:
		var found = false
		for p_db in databases:
			if p_db.db_name == c_db.db_name:
				found = true
				result.databases.details[c_db.db_name] = { "status": true }
				break
		if not found:
			result.databases.details[c_db.db_name] = { "status": false, "error": "Missing Database" }
			result.databases.status = false

	# Verify Users
	for c_user in correct_maria.users:
		var found = false
		for p_user in users:
			if p_user.username == c_user.username:
				found = true
				var v = p_user.verify_configuration(c_user)
				result.users.details[c_user.username] = v
				if not v.status:
					result.users.status = false
				break
		if not found:
			result.users.details[c_user.username] = { "status": false, "error": "Missing DB User" }
			result.users.status = false

	if not result.databases.status or not result.users.status:
		is_correct = false
	result.status = is_correct
	return result
