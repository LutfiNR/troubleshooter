extends Resource

class_name SambaService

enum ServiceState { OFF, ON }


@export var users: Array[SambaUser] = []
@export var shares: Array[SambaShare] = []


func authenticate(username_input: String, password_input: String) -> SambaUser:
	for user in users:
		if user != null and user.username == username_input and user.password == password_input:
			return user
	return null

func get_share(requested_share_name: String) -> SambaShare:
	for share in shares:
		if share != null and share.share_name == requested_share_name:
			return share
	return null
	
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
