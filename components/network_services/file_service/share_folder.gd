class_name SambaShare extends Resource
enum SecurityType { NONE, USER }

@export var share_name: String = "PublicShare"
@export var folder_path: String = "/home/public"
@export var writeable: bool = true
@export var guest_ok: bool = true
@export var security: SecurityType = SecurityType.NONE
@export var valid_users: Array[SambaUser] = []


func verify_configuration(runtime_share: SambaShare = null) -> Dictionary:
	var runtime_share_name = null
	var runtime_folder_path = null
	var runtime_writeable = null
	var runtime_guest_ok = null
	var runtime_security = null
	var runtime_users: Dictionary = {}

	if runtime_share:
		runtime_share_name = runtime_share.share_name
		runtime_folder_path = runtime_share.folder_path
		runtime_writeable = runtime_share.writeable
		runtime_guest_ok = runtime_share.guest_ok
		runtime_security = SecurityType.keys()[runtime_share.security]
		for runtime_user in runtime_share.valid_users:
			runtime_users[runtime_user.username] = runtime_user

	var res_share_name = _verify(share_name,runtime_share_name)
	var res_folder_path = _verify(folder_path,runtime_folder_path)
	var res_writeable = _verify(writeable,runtime_writeable)
	var res_guest_ok = _verify(guest_ok,runtime_guest_ok)
	var res_security = _verify(SecurityType.keys()[security],runtime_security)
	var status: bool = (
		res_share_name.status
		and res_folder_path.status
		and res_writeable.status
		and res_guest_ok.status
		and res_security.status
	)

	var res_users := {}
	for user in valid_users:
		var verification = user.verify_configuration(runtime_users.get(user.username))
		res_users[user.username] = verification
		status = status and verification.status

	return {
		"status": status,
		"share_name": res_share_name,
		"folder_path": res_folder_path,
		"writeable": res_writeable,
		"guest_ok": res_guest_ok,
		"security": res_security,
		"valid_users": res_users,
	}
	
func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
