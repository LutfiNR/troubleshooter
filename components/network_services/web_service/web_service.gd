extends Resource

class_name WebService

enum ServiceState { OFF, ON }

@export var http_state: ServiceState = ServiceState.OFF
@export var https_state: ServiceState = ServiceState.OFF
@export var virtual_hosts: Array[WebVirtualHost] = []

func handle_request(request_url: String, is_https: bool) -> WebContent:
	# Cek apakah layanan aktif berdasarkan protokol
	if is_https and https_state == ServiceState.OFF: return null
	if not is_https and http_state == ServiceState.OFF: return null

	var expected_protocol = WebVirtualHost.Protocol.HTTPS if is_https else WebVirtualHost.Protocol.HTTP
	var is_ip_request = _is_valid_ip(request_url)

	for vhost in virtual_hosts:
		if vhost == null: continue
		if vhost.protocol != expected_protocol: continue
		
		# Jika request menggunakan IP murni atau URL cocok dengan server_name
		if is_ip_request or vhost.server_name == request_url:
			return vhost.content
			
	return null

func _is_valid_ip(text: String) -> bool:
	var parts = text.split(".")
	if parts.size() != 4: return false
	for p in parts:
		if not p.is_valid_int(): return false
	return true
	
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
