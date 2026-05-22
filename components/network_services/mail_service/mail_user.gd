class_name MailUser extends Resource
@export var username: String = ""
@export var password: String = ""

func verify_configuration(correct_user: MailUser) -> Dictionary:
	if not correct_user:
		return { "status": false, "error": "Invalid Mail user" }
	var user_match = username == correct_user.username
	var pass_match = password == correct_user.password
	return {
		"status": user_match and pass_match,
		"username": { "status": user_match },
		"password": { "status": pass_match },
	}
