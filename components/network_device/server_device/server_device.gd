extends DeviceData

class_name ServerDeviceData

enum ServiceState {
	OFF,
	ON,
}

@export_group("Global Configuration")
@export var default_gateway: String
@export var dns_server: String

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
	super.setup_device()
	if interfaces.is_empty():
		var iface: NetworkInterface = NetworkInterface.new()
		iface.id = "eth0"
		iface.layer = NetworkInterface.InterfaceLayer.THIRDLAYER
		interfaces[0] = iface
	for interface in interfaces:
		interface.initialize_ip_from_export()


func is_package_installed(package_name: String) -> bool:
	return installed_packages.has(package_name)


func get_interface(_interface_id: String) -> NetworkInterface:
	return interfaces[0]


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
			print_debug("DHCP Relay: Found matching pool for IP " + ip_address)
	return null


## Resolves a domain name using the DNS configuration on this server.
func handle_dns_request(domain: String) -> String:
	if dns_service == ServiceState.OFF:
		return ""
	for dns_config in dns_configuration:
		if dns_config != null:
			var result = dns_config.resolve(domain)
			if result != "":
				return result
	return ""


## Resolves an MX record for a domain using the DNS configuration.
func handle_dns_mx_request(domain: String) -> String:
	if dns_service == ServiceState.OFF:
		return ""
	for dns_config in dns_configuration:
		if dns_config != null:
			var result = dns_config.resolve_mx(domain)
			if result != "":
				return result
	return ""


## Handles a web request. Returns { "success": bool, "content"/"error": String }.
func handle_web_request(request_url: String, is_https: bool) -> Dictionary:
	if web_service == ServiceState.OFF:
		return { "success": false, "error": "Web service is OFF." }
	for web_config in web_configuration:
		if web_config != null:
			var content = web_config.handle_request(request_url, is_https)
			if content != "":
				return { "success": true, "content": content }
	return { "success": false, "error": "No matching virtual host found." }


## Returns the first FTPService configuration, or null.
func handle_ftp_request() -> FTPService:
	if ftp_service == ServiceState.OFF:
		return null
	if ftp_configuration.is_empty() or ftp_configuration[0] == null:
		return null
	return ftp_configuration[0]


## Authenticates an FTP user. Returns { "success": bool, "home_dir"/"error": String }.
func handle_ftp_login(username_input: String, password_input: String) -> Dictionary:
	if ftp_service == ServiceState.OFF:
		return { "success": false, "error": "FTP service is OFF." }
	for ftp_config in ftp_configuration:
		if ftp_config != null:
			var user = ftp_config.authenticate(username_input, password_input)
			if user:
				return { "success": true, "home_dir": user.home_directory }
	return { "success": false, "error": "Authentication failed." }


## Returns the first RemoteService configuration, or null.
func handle_remote_request() -> RemoteService:
	if remote_service == ServiceState.OFF:
		return null
	if remote_configuration.is_empty() or remote_configuration[0] == null:
		return null
	return remote_configuration[0]


## Authenticates an SSH user. Returns { "success": bool, "error": String }.
func handle_ssh_login(username_input: String, password_input: String) -> Dictionary:
	if remote_service == ServiceState.OFF:
		return { "success": false, "error": "Remote service is OFF." }
	for remote_config in remote_configuration:
		if remote_config != null:
			if remote_config.authenticate_ssh(username_input, password_input):
				return { "success": true }
	return { "success": false, "error": "Authentication failed." }


## Authenticates a Telnet user. Returns { "success": bool, "error": String }.
func handle_telnet_login(username_input: String, password_input: String) -> Dictionary:
	if remote_service == ServiceState.OFF:
		return { "success": false, "error": "Remote service is OFF." }
	for remote_config in remote_configuration:
		if remote_config != null:
			if remote_config.authenticate_telnet(username_input, password_input):
				return { "success": true }
	return { "success": false, "error": "Authentication failed." }


## Returns the first SambaService configuration, or null.
func handle_samba_request() -> SambaService:
	if samba_service == ServiceState.OFF:
		return null
	if samba_configuration.is_empty() or samba_configuration[0] == null:
		return null
	return samba_configuration[0]


## Authenticates a Samba user. Returns { "success": bool, "error": String }.
func handle_samba_login(username_input: String, password_input: String) -> Dictionary:
	if samba_service == ServiceState.OFF:
		return { "success": false, "error": "Samba service is OFF." }
	for samba_config in samba_configuration:
		if samba_config != null:
			var user = samba_config.authenticate(username_input, password_input)
			if user:
				return { "success": true }
	return { "success": false, "error": "Authentication failed." }


## Returns the first MariaDBService configuration, or null.
func handle_mariadb_request() -> MariaDBService:
	if mariadb_service == ServiceState.OFF:
		return null
	if mariadb_configuration.is_empty() or mariadb_configuration[0] == null:
		return null
	return mariadb_configuration[0]


## Authenticates a MariaDB user. Returns { "success": bool, "user": MariaDBUser / "error": String }.
func handle_mariadb_login(username_input: String, password_input: String) -> Dictionary:
	if mariadb_service == ServiceState.OFF:
		return { "success": false, "error": "MariaDB service is OFF." }
	for db_config in mariadb_configuration:
		if db_config != null:
			var user = db_config.authenticate(username_input, password_input)
			if user:
				return { "success": true, "user": user }
	return { "success": false, "error": "Authentication failed." }


## Returns the first MailService configuration, or null.
func handle_mail_request() -> MailService:
	if mail_service == ServiceState.OFF:
		return null
	if mail_configuration.is_empty() or mail_configuration[0] == null:
		return null
	return mail_configuration[0]


## Authenticates a mail user. Returns { "success": bool, "error": String }.
func handle_mail_login(username_input: String, password_input: String) -> Dictionary:
	if mail_service == ServiceState.OFF:
		return { "success": false, "error": "Mail service is OFF." }
	for mail_config in mail_configuration:
		if mail_config != null:
			if mail_config.authenticate(username_input, password_input):
				return { "success": true }
	return { "success": false, "error": "Authentication failed." }


func verify_configuration(runtime_device_configuration: DeviceData) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(runtime_device_configuration)
	var runtime_server: ServerDeviceData = runtime_device_configuration as ServerDeviceData

	if not runtime_server:
		push_error("Runtime device configuration is empty")
		return base_result

	var result: Dictionary = base_result[device_id].duplicate()
	var is_correct: bool = result["status"]

	var dns_result = _verify_dns(runtime_server.dns_server)
	var gateway_result = _verify_gateway(runtime_server.default_gateway)
	result["dns"] = dns_result
	result["gateway"] = gateway_result
	is_correct = (is_correct and dns_result.status and gateway_result.status)

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
	return { device_id: result }


# Verify gateway
func _verify_gateway(runtime_ip_gateway: String) -> Dictionary:
	var result: bool = (default_gateway == runtime_ip_gateway)
	return { "correct": default_gateway, "value": runtime_ip_gateway, "status": result }


# Verify DNS server
func _verify_dns(runtime_ip_dns: String) -> Dictionary:
	var result: bool = (dns_server == runtime_ip_dns)
	return { "correct": dns_server, "value": runtime_ip_dns, "status": result }


func _verify_service(
	c_state: ServiceState,
	p_state: ServiceState,
	c_configs: Array,
	p_configs: Array,
) -> Dictionary:
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
			matched_service = null
			for p_config in p_configs:
				if c_service.pool_name == p_config.pool_name:
					matched_service = p_config
					break

		var verification = (
			c_service.verify_configuration(matched_service)
			if matched_service
			else c_service.verify_configuration()
		)
		result["details"].merge(verification, true)
		if c_service is DHCPService:
			result["status"] = result["status"] and verification[verification.keys()[0]]["status"]
		elif c_service is WebService:
			result["status"] = (
				result["status"] and verification["http_state"]["status"]
				and verification["https_state"]["status"]
			)
			for vh_name in verification["virtual_hosts"]:
				result["status"] = (
					result["status"] and verification["virtual_hosts"][vh_name]["status"]
				)
		elif (
			c_service is FTPService or c_service is RemoteService or c_service is SambaService
			or c_service is MariaDBService or c_service is MailService
		):
			result["status"] = result["status"] and verification["status"]
		else:
			for key in verification:
				result["status"] = result["status"] and verification[key]["status"]
	return result
