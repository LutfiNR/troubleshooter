extends Resource

class_name MailService

enum ServiceState { OFF, ON }

@export var service_state: ServiceState = ServiceState.OFF
@export var domain_name: String = "smk.com"
@export var mailbox_format: String = "Maildir"
@export var use_ssl_tls: bool = false
@export var cert_file_path: String = ""
@export var key_file_path: String = ""
@export var users: Array[MailUser] = []

func authenticate(username_input: String, password_input: String) -> bool:
	if service_state == ServiceState.OFF: return false
	
	for user in users:
		if user != null and user.username == username_input and user.password == password_input:
			return true
	return false

func verify_configuration(runtime_mail: MailService = null) -> Dictionary:
	var runtime_domain_name: Variant = null
	var runtime_mailbox_format: Variant = null
	var runtime_use_ssl_tls: Variant = null
	var runtime_users: Dictionary = {}

	if runtime_mail:
		runtime_domain_name = runtime_mail.domain_name
		runtime_mailbox_format = runtime_mail.mailbox_format
		runtime_use_ssl_tls = runtime_mail.use_ssl_tls
		for user in runtime_mail.users:
			runtime_users[user.username] = user

	var res_service_state = _verify(
		ServiceState.keys()[service_state],
		ServiceState.keys()[runtime_mail.service_state] if runtime_mail else null
	)
	var res_domain_name = _verify( domain_name, runtime_domain_name )
	var res_mailbox_format = _verify( mailbox_format, runtime_mailbox_format )
	var res_use_ssl_tls = _verify( use_ssl_tls, runtime_use_ssl_tls )

	var status: bool = (
		res_service_state.status
		and res_domain_name.status
		and res_mailbox_format.status
		and res_use_ssl_tls.status
	)

	var res_users := {}
	for user in users:
		var verification = user.verify_configuration(runtime_users.get(user.username))
		res_users[user.username] = verification
		status = status and verification.status

	return {
		"status": status,
		"service_state": res_service_state,
		"domain_name": res_domain_name,
		"mailbox_format": res_mailbox_format,
		"use_ssl_tls": res_use_ssl_tls,
		"users": res_users,
	}
	
func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
