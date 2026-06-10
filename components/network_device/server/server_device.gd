extends NetworkDevice

class_name ServerDevice

enum ServiceState {
	OFF,
	ON,
}

@export_group("Global Configuration")
@export var default_gateway: String
@export var dns_server: String
@export var neighbors: Array[NeighborhoodData] = []

# Tambahan: Manajemen Interface Jaringan
@export var interfaces: Dictionary[String, NetworkInterface] = { }

@export_category("Software Management")
@export var installed_packages: Array[String]

@export_category("DHCP Server Configuration")
@export var dhcp_service: ServiceState = ServiceState.OFF
@export var dhcp_configuration: Array[DHCPService]

@export_category("DNS Server Configuration")
@export var dns_service: ServiceState = ServiceState.OFF
@export var dns_configuration: Array[DNSService]

@export_category("Web Server Configuration")
@export var web_service: ServiceState = ServiceState.OFF
@export var web_configuration: Array[WebService]

@export_category("FTP Server Configuration")
@export var ftp_service: ServiceState = ServiceState.OFF
@export var ftp_configuration: Array[FTPService]

@export_category("Remote Server Configuration")
@export var remote_service: ServiceState = ServiceState.OFF
@export var remote_configuration: Array[RemoteService]

@export_category("Samba Server Configuration")
@export var samba_service: ServiceState = ServiceState.OFF
@export var samba_configuration: Array[SambaService] = []

@export_category("MariaDB Configuration")
@export var mariadb_service: ServiceState = ServiceState.OFF
@export var mariadb_configuration: Array[MariaDBService] = []

@export_category("Mail Configuration")
@export var mail_service: ServiceState = ServiceState.OFF
@export var mail_configuration: Array[MailService] = []


func setup_device() -> void:
	if interfaces.is_empty():
		var iface: NetworkInterface = NetworkInterface.new()
		iface.id = "eth0"
		iface.layer = NetworkInterface.InterfaceLayer.THIRDLAYER
		interfaces[iface.id] = iface
	for iface_id in interfaces:
		interfaces[iface_id].setup_ip()


func add_interface(interface_data: NetworkInterface) -> void:
	if not interface_data:
		return
	interfaces[interface_data.id] = interface_data
	interfaces[interface_data.id].setup_ip()


func remove_interface(interface_id: String) -> void:
	if interfaces.has(interface_id):
		interfaces.erase(interface_id)


func get_interface(interface_id: String) -> NetworkInterface:
	return interfaces.get(interface_id)


func has_interface(interface_id: String) -> bool:
	return interfaces.has(interface_id)


func get_interfaces() -> Dictionary[String, NetworkInterface]:
	return interfaces


func get_main_interface() -> NetworkInterface:
	return get_interface("eth0")


func is_package_installed(package_name: String) -> bool:
	return installed_packages.has(package_name)


func handle_dhcp_request(mac: String, interface_id: String) -> Dictionary:
	if dhcp_service == ServiceState.OFF:
		return { }
	for pool in dhcp_configuration:
		if pool != null and pool.interface_id == interface_id:
			return pool.request_ip(mac)
	return { }


func handle_dhcp_relay_request(ip_address: String) -> DHCPService:
	if ip_address == "":
		return null
	for pool in dhcp_configuration:
		if pool != null and pool.default_gateway == ip_address:
			return pool
	return null


func _is_valid_ip(text: String) -> bool:
	var parts = text.split(".")
	if parts.size() != 4:
		return false
	for p in parts:
		if not p.is_valid_int():
			return false
	return true


func handle_dns_request(domain: String) -> String:
	if dns_service == ServiceState.OFF:
		return ""
	for config in dns_configuration:
		if config != null:
			var resolved_ip = config.resolve(domain)
			if resolved_ip != "":
				return resolved_ip
	return ""


func handle_web_request(_requested_ip: String, _request_url: String, is_https: bool) -> WebContent:
	if web_service == ServiceState.OFF:
		return null

	var is_ip_request = _is_valid_ip(_request_url)
	var expected_protocol = WebVirtualHost.Protocol.HTTPS if is_https else WebVirtualHost.Protocol.HTTP

	for config in web_configuration:
		if config == null:
			continue

		if is_https and config.https_state == ServiceState.OFF:
			continue
		elif not is_https and config.http_state == ServiceState.OFF:
			continue

		for vhost in config.virtual_hosts:
			if vhost == null:
				continue
			if vhost.protocol != expected_protocol:
				continue

			if is_ip_request or vhost.server_name == _request_url:
				return vhost.content
	return null


func handle_ftp_request() -> FTPService:
	if ftp_service == ServiceState.OFF or ftp_configuration.is_empty():
		return null
	return ftp_configuration[0]


func handle_remote_request() -> RemoteService:
	if remote_service == ServiceState.OFF or remote_configuration.is_empty():
		return null
	return remote_configuration[0]


func handle_samba_request() -> SambaService:
	if samba_service == ServiceState.OFF or samba_configuration.is_empty():
		return null
	return samba_configuration[0]


func handle_mariadb_request() -> MariaDBService:
	if mariadb_service == ServiceState.OFF or mariadb_configuration.is_empty():
		return null
	return mariadb_configuration[0]


func handle_mail_request() -> MailService:
	if mail_service == ServiceState.OFF or mail_configuration.is_empty():
		return null
	return mail_configuration[0]


func verify_configuration(runtime_device_configuration: NetworkDevice) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(runtime_device_configuration)
	var runtime_server: ServerDevice = runtime_device_configuration as ServerDevice

	if not runtime_server:
		push_error("Runtime device configuration is empty")
		return base_result

	var result := base_result.duplicate()
	var is_correct: bool = base_result.status

	# Network verification
	var dns_result = _verify_dns(runtime_server.dns_server)
	var gateway_result = _verify_gateway(runtime_server.default_gateway)
	var interfaces_result = _verify_interfaces(runtime_server.interfaces)
	result["interfaces"] = interfaces_result
	result["dns"] = dns_result
	result["gateway"] = gateway_result
	is_correct = (
			is_correct
			and dns_result.status
			and gateway_result.status
			and interfaces_result.status
	)

	# Service verification
	var services := {
		"dhcp_service": [
			dhcp_service,
			runtime_server.dhcp_service,
			dhcp_configuration,
			runtime_server.dhcp_configuration,
		],
		"dns_service": [
			dns_service,
			runtime_server.dns_service,
			dns_configuration,
			runtime_server.dns_configuration,
		],
		"web_service": [
			web_service,
			runtime_server.web_service,
			web_configuration,
			runtime_server.web_configuration,
		],
		"ftp_service": [
			ftp_service,
			runtime_server.ftp_service,
			ftp_configuration,
			runtime_server.ftp_configuration,
		],
		"remote_service": [
			remote_service,
			runtime_server.remote_service,
			remote_configuration,
			runtime_server.remote_configuration,
		],
		"samba_service": [
			samba_service,
			runtime_server.samba_service,
			samba_configuration,
			runtime_server.samba_configuration,
		],
		"mariadb_service": [
			mariadb_service,
			runtime_server.mariadb_service,
			mariadb_configuration,
			runtime_server.mariadb_configuration,
		],
		"mail_service": [
			mail_service,
			runtime_server.mail_service,
			mail_configuration,
			runtime_server.mail_configuration,
		],
	}
	for service_name in services:
		var data = services[service_name]
		result[service_name] = _verify_service(data[0], data[1], data[2], data[3])
		is_correct = is_correct and result[service_name].status
	result["status"] = is_correct
	return result


# Verify gateway
func _verify_gateway(runtime_ip_gateway: String) -> Dictionary:
	var result: bool = (
			default_gateway == runtime_ip_gateway
	)
	return {
		"correct": default_gateway,
		"value": runtime_ip_gateway,
		"status": result,
	}


# Verify DNS server
func _verify_dns(runtime_ip_dns: String) -> Dictionary:
	var result: bool = (
			dns_server == runtime_ip_dns
	)
	return {
		"correct": dns_server,
		"value": runtime_ip_dns,
		"status": result,
	}


func _verify_interfaces(runtime_interfaces: Dictionary) -> Dictionary:
	if interfaces.size() != runtime_interfaces.size():
		push_error("Jumlah interface tidak sesuai")
	var results: Dictionary = { }
	var is_correct: bool = true
	for interface_id in interfaces:
		if not runtime_interfaces.has(interface_id):
			results[interface_id] = {
				"status": false,
				"error": "Missing interface",
			}
			is_correct = false
			continue
		var verify_result: Dictionary = interfaces[interface_id].verify_configuration(runtime_interfaces[interface_id])
		results[interface_id] = verify_result
		if not verify_result.status:
			is_correct = false
	return {
		"status": is_correct,
		"results": results,
	}


func _verify_service(c_state: ServiceState, p_state: ServiceState, c_configs: Array, p_configs: Array) -> Dictionary:
	var result := {
		"status": c_state == p_state,
		"service_state": {
			"status": c_state == p_state,
			"value": ServiceState.keys()[p_state],
			"correct": ServiceState.keys()[c_state],
		},
		"details": { },
	}

	if c_state != ServiceState.ON:
		return result

	for c_service in c_configs:
		var matched_service = p_configs[0] if p_configs.size() > 0 else null
		if c_service is DHCPService:
			for p_config in p_configs:
				print(c_service.pool_name, p_config.pool_name, c_service.pool_name == p_config.pool_name)
				if c_service.pool_name == p_config.pool_name:
					matched_service = p_config
				else:
					matched_service = null

		var verification = (
				c_service.verify_configuration(matched_service)
				if matched_service
				else c_service.verify_configuration()
		)
		result["details"].merge(verification, true)
		if c_service is DHCPService or c_service is DNSService:
			result["status"] = result["status"] and verification[verification.keys()[0]]["status"]
			if c_service is DHCPService:
				print(verification[verification.keys()[0]]["pool_name"]["value"], verification[verification.keys()[0]]["status"])
		else:
			result["status"] = result["status"] and verification["status"]
	return result
