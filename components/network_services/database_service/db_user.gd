class_name MariaDBUser
extends Resource
@export var username: String = ""
@export var password: String = ""
@export var privileges: Dictionary[String, Array] = { }


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
