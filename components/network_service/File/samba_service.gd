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
	
func verify_configuration(runtime_samba: SambaService = null) -> Dictionary:
	var runtime_users: Dictionary = {}
	var runtime_shares: Dictionary = {}

	if runtime_samba:
		for runtime_user in runtime_samba.users:
			if runtime_user != null:
				runtime_users[runtime_user.username] = runtime_user
		for runtime_share in runtime_samba.shares:
			if runtime_share != null:
				runtime_shares[runtime_share.share_name] = runtime_share

	var status := true
	var res_users := {}
	for user in users:
		if user == null: continue
		var verification = user.verify_configuration(runtime_users.get(user.username))
		res_users[user.username] = verification
		status = status and verification.status

	var res_shares := {}
	for share in shares:
		if share == null: continue
		var verification = share.verify_configuration(runtime_shares.get(share.share_name))
		res_shares[share.share_name] = verification
		status = status and verification.status

	return {
		"status": status,
		"users": res_users,
		"shares": res_shares,
	}
