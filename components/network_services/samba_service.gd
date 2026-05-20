extends Resource

class_name SambaService

enum ServiceState { OFF, ON }


class SambaUser extends Resource:
	@export var username: String = ""
	@export var password: String = ""


	func verify_configuration(correct_user: SambaUser) -> Dictionary:
		if not correct_user:
			return { "status": false, "error": "Invalid user" }
		var user_match = username == correct_user.username
		var pass_match = password == correct_user.password
		return {
			"status": user_match and pass_match,
			"username": { "status": user_match },
			"password": { "status": pass_match },
		}


class SambaShare extends Resource:
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


@export var users: Array[SambaUser] = []
@export var shares: Array[SambaShare] = []


func verify_configuration(correct_samba: SambaService) -> Dictionary:
	if not correct_samba:
		return { "status": false, "error": "Invalid Samba config" }

	var is_correct = true
	var result = {
		"status": false,
		"users": { "status": true, "details": { } },
		"shares": { "status": true, "details": { } },
	}

	# Verify Users
	for c_user in correct_samba.users:
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
			result.users.details[c_user.username] = { "status": false, "error": "Missing User" }
			result.users.status = false

	# Verify Shares
	for c_share in correct_samba.shares:
		var found = false
		for p_share in shares:
			if p_share.share_name == c_share.share_name:
				found = true
				var v = p_share.verify_configuration(c_share)
				result.shares.details[c_share.share_name] = v
				if not v.status:
					result.shares.status = false
				break
		if not found:
			result.shares.details[c_share.share_name] = { "status": false, "error": "Missing Share" }
			result.shares.status = false

	if not result.users.status or not result.shares.status:
		is_correct = false
	result.status = is_correct
	return result
