class_name WebVirtualHost extends Resource
enum Protocol { HTTP, HTTPS }

@export var name: String = "www.example.com"
@export var protocol: Protocol = Protocol.HTTP
@export var server_name: String = "www.example.com"
@export var document_root: String = "/var/www"
@export var content: WebContent


func verify_configuration(runtime_vhost: WebVirtualHost = null) -> Dictionary:
	var runtime_name = null
	var runtime_protocol = null
	var runtime_server_name = null
	var runtime_document_root = null

	if runtime_vhost:
		runtime_name = runtime_vhost.name
		runtime_protocol = Protocol.keys()[runtime_vhost.protocol]
		runtime_server_name = runtime_vhost.server_name
		runtime_document_root = runtime_vhost.document_root

	var res_name = _verify(name, runtime_name)
	var res_protocol = _verify(Protocol.keys()[protocol],runtime_protocol)
	var res_server_name = _verify(server_name,runtime_server_name)
	var res_document_root = _verify(document_root,runtime_document_root)

	var status = (
		res_name.status
		and res_protocol.status
		and res_server_name.status
		and res_document_root.status
	)

	return {
		"status": status,
		"name": res_name,
		"protocol": res_protocol,
		"server_name": res_server_name,
		"document_root": res_document_root,
	}
	
func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
