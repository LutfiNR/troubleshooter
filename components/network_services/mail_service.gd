extends Resource

class_name MailService

enum ServiceState { OFF, ON }


class MailUser extends Resource:
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


@export var service_state: ServiceState = ServiceState.OFF
@export var domain_name: String = "smk.com"
@export var mailbox_format: String = "Maildir"
@export var use_ssl_tls: bool = false
@export var cert_file_path: String = ""
@export var key_file_path: String = ""
@export var users: Array[MailUser] = []


func verify_configuration(correct_mail: MailService) -> Dictionary:
	if not correct_mail:
		return { "status": false, "error": "Invalid Mail config" }

	var is_correct = true
	var result = {
		"status": false,
		"service_state": { "status": service_state == correct_mail.service_state },
		"domain_name": { "status": domain_name == correct_mail.domain_name },
		"mailbox_format": { "status": mailbox_format == correct_mail.mailbox_format },
		"use_ssl_tls": { "status": use_ssl_tls == correct_mail.use_ssl_tls },
		"users": { "status": true, "details": { } },
	}

	if not result.service_state.status or not result.domain_name.status or not result.mailbox_format.status or not result.use_ssl_tls.status:
		is_correct = false

	for c_user in correct_mail.users:
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
			result.users.details[c_user.username] = { "status": false, "error": "Missing Mail User" }
			result.users.status = false

	if not result.users.status:
		is_correct = false
	result.status = is_correct
	return result
