extends Resource

class_name WebService

enum ServiceState {
	OFF,
	ON,
}

@export var http_state: ServiceState = ServiceState.OFF
@export var https_state: ServiceState = ServiceState.OFF
@export var virtual_hosts: Array[WebVirtualHost] = []


func handle_request(request_url: String, is_https: bool) -> String:
	if is_https and https_state == ServiceState.OFF:
		return ""
	if not is_https and http_state == ServiceState.OFF:
		return ""

	var is_ip_request = IPAddress.is_valid_ip(request_url)
	var host_candidates: Array[String] = [request_url]
	if request_url.begins_with("www."):
		host_candidates.append(request_url.substr(4))
	for vhost in virtual_hosts:
		if vhost == null:
			continue
		if is_ip_request:
			return vhost.content
		for host_name in host_candidates:
			if vhost.server_name == host_name:
				return vhost.content
	return ""


func verify_configuration(runtime_web_service: WebService = null) -> Dictionary:
	var runtime_http = null
	var runtime_https = null
	if runtime_web_service:
		runtime_http = ServiceState.keys()[runtime_web_service.http_state]
		runtime_https = ServiceState.keys()[runtime_web_service.https_state]

	var result: Dictionary = {
		"http_state": {
			"value": runtime_http,
			"correct": ServiceState.keys()[http_state],
			"status": runtime_web_service != null and http_state == runtime_web_service.http_state,
		},
		"https_state": {
			"value": runtime_https,
			"correct": ServiceState.keys()[https_state],
			"status": runtime_web_service != null and https_state == runtime_web_service.https_state,
		},
		"virtual_hosts": { },
	}
	for vhost in virtual_hosts:
		var matched_vh: WebVirtualHost = null
		if runtime_web_service:
			for vh in runtime_web_service.virtual_hosts:
				if vhost.name == vh.name:
					matched_vh = vh
					break

		result["virtual_hosts"][vhost.name] = vhost.verify_configuration(matched_vh)
	return result
