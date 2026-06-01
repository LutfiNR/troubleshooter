extends Resource

class_name RemoteService

enum ServiceState { OFF, ON }

@export var telnet_state: ServiceState = ServiceState.OFF
@export var ssh_state: ServiceState = ServiceState.OFF
@export var ssh_port: int = 22
@export var permit_root_login: bool = true
@export var users: Array[RemoteUser] = []

func authenticate_ssh(username_input: String, password_input: String) -> bool:
	if ssh_state == ServiceState.OFF: return false
	
	# Proteksi root login
	if username_input == "root" and not permit_root_login:
		return false
		
	for user in users:
		if user != null and user.username == username_input and user.password == password_input:
			return true
	return false

func authenticate_telnet(username_input: String, password_input: String) -> bool:
	if telnet_state == ServiceState.OFF: return false
	
	for user in users:
		if user != null and user.username == username_input and user.password == password_input:
			return true
	return false

func verify_configuration(runtime_remote_service: RemoteService = null) -> Dictionary:
	var runtime_ssh_port: Variant = null
	var runtime_permit_root_login: Variant = null
	var runtime_users: Dictionary = {}

	if runtime_remote_service:
		runtime_ssh_port = runtime_remote_service.ssh_port
		runtime_permit_root_login = runtime_remote_service.permit_root_login
		for runtime_user in runtime_remote_service.users:
			runtime_users[runtime_user.username] = runtime_user

	var res_telnet_state = _verify(
		ServiceState.keys()[telnet_state],
		ServiceState.keys()[runtime_remote_service.telnet_state] if runtime_remote_service else null
	)

	var res_ssh_state = _verify(
		ServiceState.keys()[ssh_state],
		ServiceState.keys()[runtime_remote_service.ssh_state] if runtime_remote_service else null
	)
	var res_ssh_port = _verify(ssh_port,runtime_ssh_port)
	var res_permit_root_login = _verify(permit_root_login,runtime_permit_root_login)

	var status: bool = (
		res_telnet_state.status
		and res_telnet_state.status
		and res_ssh_port.status
		and res_permit_root_login.status
	)

	var res_users := {}
	for user in users:
		var verification = user.verify_configuration(runtime_users.get(user.username))
		res_users[user.username] = verification
		status = status and verification.status

	return {
		"status": status,
		"telnet_state": res_telnet_state,
		"ssh_state": res_ssh_state,
		"ssh_port": res_ssh_port,
		"permit_root_login": res_permit_root_login,
		"users": res_users,
	}

func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
