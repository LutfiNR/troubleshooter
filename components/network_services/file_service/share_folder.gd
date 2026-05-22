class_name SambaShare extends Resource
enum SecurityType { NONE, USER }

@export var share_name: String = "PublicShare"
@export var folder_path: String = "/home/public"
@export var writeable: bool = true
@export var guest_ok: bool = true
@export var security: SecurityType = SecurityType.NONE
@export var valid_users: Array[SambaUser] = []


func verify_configuration(correct_share: SambaShare) -> Dictionary:
	if not correct_share:
		return { "status": false, "error": "Invalid share" }
	var is_correct = true
	var result = {
		"status": false,
		"share_name": { "status": share_name == correct_share.share_name },
		"folder_path": { "status": folder_path == correct_share.folder_path },
		"writeable": { "status": writeable == correct_share.writeable },
		"guest_ok": { "status": guest_ok == correct_share.guest_ok },
		"security": { "status": security == correct_share.security },
		"valid_users": { "status": true, "details": { } },
	}

	if not result.share_name.status or not result.folder_path.status or not result.writeable.status or not result.guest_ok.status or not result.security.status:
		is_correct = false

	# Verifikasi akses User di dalam Share
	for c_user in correct_share.valid_users:
		var found = false
		for p_user in valid_users:
			if p_user.username == c_user.username:
				found = true
				var v = p_user.verify_configuration(c_user)
				result.valid_users.details[c_user.username] = v
				if not v.status:
					result.valid_users.status = false
				break
		if not found:
			result.valid_users.details[c_user.username] = { "status": false, "error": "Missing User in Share" }
			result.valid_users.status = false

	if not result.valid_users.status:
		is_correct = false
	result.status = is_correct
	return result
