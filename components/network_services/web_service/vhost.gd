class_name WebVirtualHost extends Resource
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
