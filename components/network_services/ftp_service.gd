extends Resource

class_name FTPService

enum ServiceState { OFF, ON }


class FTPUser extends Resource:
	@export var username: String = ""
	@export var password: String = ""
	@export var home_directory: String = "/home/user"


	func verify_configuration(correct_user: FTPUser) -> Dictionary:
		if not correct_user:
			return { "status": false, "error": "Invalid FTP user" }

		var user_match = username == correct_user.username
		var pass_match = password == correct_user.password
		var dir_match = home_directory == correct_user.home_directory

		return {
			"status": user_match and pass_match and dir_match,
			"username": { "status": user_match },
			"password": { "status": pass_match },
			"home_directory": { "status": dir_match },
		}


@export var ftps_state: ServiceState = ServiceState.OFF
@export var local_enable: bool = false
@export var anonymous_enable: bool = false
@export var write_enable: bool = false
@export var users: Array[FTPUser] = []


func verify_configuration(correct_ftp: FTPService) -> Dictionary:
	if not correct_ftp:
		return { "status": false, "error": "Invalid FTP config" }

	var is_correct = true
	var result = {
		"status": false,
		"ftps_state": { "status": ftps_state == correct_ftp.ftps_state },
		"local_enable": { "status": local_enable == correct_ftp.local_enable },
		"anonymous_enable": { "status": anonymous_enable == correct_ftp.anonymous_enable },
		"write_enable": { "status": write_enable == correct_ftp.write_enable },
		"users": { "status": true, "details": { } },
	}

	if not result.ftps_state.status or not result.local_enable.status or not result.anonymous_enable.status or not result.write_enable.status:
		is_correct = false

	for c_user in correct_ftp.users:
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
			result.users.details[c_user.username] = { "status": false, "error": "Missing FTP User" }
			result.users.status = false

	if not result.users.status:
		is_correct = false
	result.status = is_correct
	return result
