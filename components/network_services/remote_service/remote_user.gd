class_name RemoteUser extends Resource

@export var username: String = ""
@export var password: String = ""


func verify_configuration(runtime_user: RemoteUser = null) -> Dictionary:
	var runtime_username = null
	var runtime_password = null

	if runtime_user:
		runtime_username = runtime_user.username
		runtime_password = runtime_user.password

	var res_username = _verify(username,runtime_username)
	var res_password = _verify(password,runtime_password)
	var status = (res_username.status and res_password.status)

	return {
		"status": status,
		"username": res_username,
		"password": res_password,
	}

func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
