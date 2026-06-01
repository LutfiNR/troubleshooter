extends Resource

class_name FTPService

enum ServiceState { OFF, ON }

@export var ftps_state: ServiceState = ServiceState.OFF
@export var local_enable: bool = false
@export var anonymous_enable: bool = false
@export var write_enable: bool = false
@export var users: Array[FTPUser] = []

func authenticate(username_input: String, password_input: String) -> FTPUser:
	# Cek login anonymous
	if anonymous_enable and username_input == "anonymous":
		var anon_user = FTPUser.new()
		anon_user.username = "anonymous"
		anon_user.home_directory = "/srv/ftp" # Folder default anonymous
		return anon_user
		
	# Cek login user lokal
	if not local_enable: 
		return null
		
	for user in users:
		if user != null and user.username == username_input and user.password == password_input:
			return user
			
	return null

func verify_configuration(runtime_ftp_service: FTPService = null) -> Dictionary:
	var runtime_local_enable: Variant = null
	var runtime_anonymous_enable: Variant= null
	var runtime_write_enable: Variant = null
	var runtime_users: Dictionary = {}

	if runtime_ftp_service:
		runtime_local_enable = runtime_ftp_service.local_enable
		runtime_anonymous_enable = runtime_ftp_service.anonymous_enable
		runtime_write_enable = runtime_ftp_service.write_enable
		for runtime_user in runtime_ftp_service.users:
			runtime_users[runtime_user.username] = runtime_user

	var res_ftps_state = _verify(
		ServiceState.keys()[ftps_state],
		ServiceState.keys()[runtime_ftp_service.ftps_state] if runtime_ftp_service else null
	)

	var res_local_enable = _verify(local_enable,runtime_local_enable)
	var res_anonymous_enable = _verify(anonymous_enable,runtime_anonymous_enable)
	var res_write_enable = _verify(write_enable,runtime_write_enable)

	var status: bool = (
		res_ftps_state.status
		and res_local_enable.status
		and res_anonymous_enable.status
		and res_write_enable.status
	)

	var res_users := {}
	for user in users:
		var verification = user.verify_configuration(runtime_users.get(user.username))
		res_users[user.username] = verification
		status = status and verification.status

	return {
		"status": status,
		"ftps_state": res_ftps_state,
		"local_enable": res_local_enable,
		"anonymous_enable": res_anonymous_enable,
		"write_enable": res_write_enable,
		"users": res_users,
	}
	
func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
