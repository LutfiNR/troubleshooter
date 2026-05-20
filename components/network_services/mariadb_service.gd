extends Resource

class_name MariaDBService

enum ServiceState { OFF, ON }


class MariaDBDatabase extends Resource:
	@export var db_name: String = ""


	func verify_configuration(correct_db: MariaDBDatabase) -> Dictionary:
		if not correct_db:
			return { "status": false }
		var is_correct = db_name == correct_db.db_name
		return { "status": is_correct, "db_name": { "status": is_correct } }


class MariaDBUser extends Resource:
	@export var username: String = ""
	@export var password: String = ""
	@export var privileges: Dictionary = { }


	func verify_configuration(correct_user: MariaDBUser) -> Dictionary:
		if not correct_user:
			return { "status": false, "error": "Invalid DB user" }

		var is_correct = true
		var result = {
			"status": false,
			"username": { "status": username == correct_user.username },
			"password": { "status": password == correct_user.password },
			"privileges": { "status": true, "details": { } },
		}

		if not result.username.status or not result.password.status:
			is_correct = false

		for db_name in correct_user.privileges:
			if not privileges.has(db_name):
				result.privileges.details[db_name] = { "status": false, "error": "Missing access to DB" }
				result.privileges.status = false
				continue

			var c_privs = correct_user.privileges[db_name]
			var p_privs = privileges[db_name]
			var privs_match = true

			for priv in c_privs:
				if not p_privs.has(priv):
					privs_match = false
					break

			result.privileges.details[db_name] = { "status": privs_match }
			if not privs_match:
				result.privileges.status = false

		if not result.privileges.status:
			is_correct = false
		result.status = is_correct
		return result


@export var service_state: ServiceState = ServiceState.OFF
@export var root_password: String = ""
@export var databases: Array[MariaDBDatabase] = []
@export var users: Array[MariaDBUser] = []


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
