extends Resource

class_name WebService

enum ServiceState { OFF, ON }


class WebContent extends Resource:
	@export_multiline var content: String = ""


class WebVirtualHost extends Resource:
	enum Protocol { HTTP, HTTPS }

	@export var name: String = "www.example.com"
	@export var protocol: Protocol = Protocol.HTTP
	@export var server_name: String = "www.example.com"
	@export var document_root: String = "/var/www"
	@export var content: WebContent


	func verify_configuration(correct_vhost: WebVirtualHost) -> Dictionary:
		if not correct_vhost:
			return { "status": false, "error": "Invalid vhost" }

		var checks = {
			"protocol": protocol == correct_vhost.protocol,
			"server_name": server_name == correct_vhost.server_name,
			"document_root": document_root == correct_vhost.document_root,
		}

		var is_correct = true
		var result = { "status": false }
		for key in checks:
			if not checks[key]:
				is_correct = false
			result[key] = { "status": checks[key] }

		result.status = is_correct
		return result


@export var http_state: ServiceState = ServiceState.OFF
@export var https_state: ServiceState = ServiceState.OFF
@export var virtual_hosts: Array[WebVirtualHost] = []


func verify_configuration(correct_web: WebService) -> Dictionary:
	if not correct_web:
		return { "status": false, "error": "Invalid Web config" }

	var is_correct = true
	var result = {
		"status": false,
		"http_state": { "status": http_state == correct_web.http_state },
		"https_state": { "status": https_state == correct_web.https_state },
		"virtual_hosts": { "status": true, "details": { } },
	}

	if not result.http_state.status or not result.https_state.status:
		is_correct = false

	for c_vhost in correct_web.virtual_hosts:
		var found = false
		for p_vhost in virtual_hosts:
			if p_vhost.server_name == c_vhost.server_name and p_vhost.protocol == c_vhost.protocol:
				found = true
				var v = p_vhost.verify_configuration(c_vhost)
				result.virtual_hosts.details[c_vhost.server_name] = v
				if not v.status:
					result.virtual_hosts.status = false
				break
		if not found:
			result.virtual_hosts.details[c_vhost.server_name] = { "status": false, "error": "Missing Virtual Host" }
			result.virtual_hosts.status = false

	if not result.virtual_hosts.status:
		is_correct = false
	result.status = is_correct
	return result
