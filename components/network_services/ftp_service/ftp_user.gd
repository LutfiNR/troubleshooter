class_name FTPUser extends Resource
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
