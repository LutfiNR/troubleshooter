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

	var raw_host = request_url.strip_edges().to_lower()
	if raw_host == "":
		return ""
	if raw_host.begins_with("http://"):
		raw_host = raw_host.replace("http://", "")
	if raw_host.begins_with("https://"):
		raw_host = raw_host.replace("https://", "")
	if raw_host.ends_with("/"):
		raw_host = raw_host.rstrip("/")
	if raw_host.contains("/"):
		raw_host = raw_host.split("/", false, 1)[0]
	if raw_host.contains(":"):
		raw_host = raw_host.split(":", false, 1)[0]

	# Check for exact host match first
	for vhost in virtual_hosts:
		if vhost == null:
			continue
		var vhost_name = (vhost.server_name as String).strip_edges().to_lower()
		if vhost_name == raw_host:
			if is_https and vhost.protocol == WebVirtualHost.Protocol.HTTPS:
				return vhost.content
			if not is_https and vhost.protocol == WebVirtualHost.Protocol.HTTP:
				return vhost.content

	# Check for www alias (www.example.com -> example.com)
	if raw_host.begins_with("www."):
		var without_www = raw_host.substr(4)
		for vhost in virtual_hosts:
			if vhost == null:
				continue
			var vhost_name = (vhost.server_name as String).strip_edges().to_lower()
			if vhost_name == without_www:
				if is_https and vhost.protocol == WebVirtualHost.Protocol.HTTPS:
					return vhost.content
				if not is_https and vhost.protocol == WebVirtualHost.Protocol.HTTP:
					return vhost.content

	# Fall back to default (main) vhost only for IP requests or as last resort
	if IPAddress.is_valid_ip(raw_host):
		for vhost in virtual_hosts:
			if vhost == null:
				continue
			var vhost_name = (vhost.server_name as String).strip_edges().to_lower()
			if vhost_name == "kirin.com" or vhost_name == "www.kirin.com":
				if is_https and vhost.protocol == WebVirtualHost.Protocol.HTTPS:
					return vhost.content
				if not is_https and vhost.protocol == WebVirtualHost.Protocol.HTTP:
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
