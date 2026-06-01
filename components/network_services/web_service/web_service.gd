extends Resource

class_name WebService

enum ServiceState { OFF, ON }

@export var http_state: ServiceState = ServiceState.OFF
@export var https_state: ServiceState = ServiceState.OFF
@export var virtual_hosts: Array[WebVirtualHost] = []


func handle_request(request_url: String, is_https: bool) -> WebContent:
	# Cek apakah layanan aktif berdasarkan protokol
	if is_https and https_state == ServiceState.OFF:
		return null
	if not is_https and http_state == ServiceState.OFF:
		return null

	var expected_protocol = WebVirtualHost.Protocol.HTTPS if is_https else WebVirtualHost.Protocol.HTTP
	var is_ip_request = _is_valid_ip(request_url)

	for vhost in virtual_hosts:
		if vhost == null:
			continue
		if vhost.protocol != expected_protocol:
			continue

		# Jika request menggunakan IP murni atau URL cocok dengan server_name
		if is_ip_request or vhost.server_name == request_url:
			return vhost.content

	return null


func _is_valid_ip(text: String) -> bool:
	var parts = text.split(".")
	if parts.size() != 4:
		return false
	for p in parts:
		if not p.is_valid_int():
			return false
	return true


func verify_configuration(runtime_web_service: WebService = null) -> Dictionary:
	var result: Dictionary = {}
	if not runtime_web_service:
		for vhost in virtual_hosts:
			var res = vhost.verify_configuration()
			result[vhost.name] = res
		return result

	for vhost in virtual_hosts:
		for vh in runtime_web_service.virtual_hosts:
			if vhost.name == vh.name:
				var res = vhost.verify_configuration(vh)
				result[vhost.name] = res
			else:
				var res = vhost.verify_configuration()
				result[vhost.name] = res
	return result
