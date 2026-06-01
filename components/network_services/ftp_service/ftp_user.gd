class_name FTPUser
extends Resource

@export var username: String = ""
@export var password: String = ""
@export var home_directory: String = "/home/user"

func verify_configuration(runtime_user: FTPUser = null) -> Dictionary:
	var runtime_username: Variant = null
	var runtime_password: Variant = null
	var runtime_home_directory: Variant = null

	if runtime_user:
		runtime_username = runtime_user.username
		runtime_password = runtime_user.password
		runtime_home_directory = runtime_user.home_directory

	var res_username = _verify(username, runtime_username)
	var res_password = _verify(password, runtime_password)
	var res_home_directory = _verify(home_directory, runtime_home_directory)

	return {
		"status": (res_username.status and res_password.status and res_home_directory.status),
		"username": res_username,
		"password": res_password,
		"home_directory": res_home_directory,
	}

func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
