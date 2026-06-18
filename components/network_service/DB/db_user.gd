class_name MariaDBUser
extends Resource
@export var username: String = ""
@export var password: String = ""
@export var privileges: Dictionary[String, Array] = { }


func verify_configuration(runtime_user: MariaDBUser = null) -> Dictionary:
	var runtime_username: Variant = null
	var runtime_password: Variant = null
	var runtime_privileges: Dictionary = {}

	if runtime_user:
		runtime_username = runtime_user.username
		runtime_password = runtime_user.password
		runtime_privileges = runtime_user.privileges

	var res_username = _verify(username, runtime_username)
	var res_password = _verify(password, runtime_password)

	var status: bool = ( res_username.status and res_password.status )
	var res_privileges := {}
	for db_name in privileges:
		var expected_privs = privileges[db_name]
		var runtime_privs = runtime_privileges.get(db_name)
		var priv_status := false
		if runtime_privs != null:
			priv_status = true
			for priv in expected_privs:
				if not runtime_privs.has(priv):
					priv_status = false
					break

		var verification = {
			"value": runtime_privs,
			"correct": expected_privs,
			"status": priv_status,
		}

		res_privileges[db_name] = verification
		status = status and verification.status

	return {
		"status": status,
		"username": res_username,
		"password": res_password,
		"privileges": res_privileges,
	}

func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
