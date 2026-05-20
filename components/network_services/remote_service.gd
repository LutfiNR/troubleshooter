extends Resource

class_name RemoteService

enum ServiceState { OFF, ON }


class RemoteUser extends Resource:
	@export var username: String = ""
	@export var password: String = ""


	func verify_configuration(correct_user: RemoteUser) -> Dictionary:
		if not correct_user:
			return { "status": false, "error": "Invalid Remote user" }
		var user_match = username == correct_user.username
		var pass_match = password == correct_user.password
		return {
			"status": user_match and pass_match,
			"username": { "status": user_match },
			"password": { "status": pass_match },
		}


@export var telnet_state: ServiceState = ServiceState.OFF
@export var ssh_state: ServiceState = ServiceState.OFF
@export var ssh_port: int = 22
@export var permit_root_login: bool = true
@export var users: Array[RemoteUser] = []


func verify_configuration(correct_remote: RemoteService) -> Dictionary:
	if not correct_remote:
		return { "status": false, "error": "Invalid Remote config" }

	var is_correct = true
	var result = {
		"status": false,
		"telnet_state": { "status": telnet_state == correct_remote.telnet_state },
		"ssh_state": { "status": ssh_state == correct_remote.ssh_state },
		"ssh_port": { "status": ssh_port == correct_remote.ssh_port },
		"permit_root_login": { "status": permit_root_login == correct_remote.permit_root_login },
		"users": { "status": true, "details": { } },
	}

	if not result.telnet_state.status or not result.ssh_state.status or not result.ssh_port.status or not result.permit_root_login.status:
		is_correct = false

	for c_user in correct_remote.users:
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
			result.users.details[c_user.username] = { "status": false, "error": "Missing Remote User" }
			result.users.status = false

	if not result.users.status:
		is_correct = false
	result.status = is_correct
	return result
