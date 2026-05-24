extends NetworkDevice

class_name ServerDevice

enum ServiceState {
	OFF,
	ON,
}

@export_group("Global Configuration")
@export var default_gateway: String
@export var dns_server: String

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

# ==========================================
# HANDLING REQUESTS (SIMULASI LAYANAN)
# ==========================================


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

# ==========================================
# VERIFIKASI KONFIGURASI (SISTEM PENILAIAN)
# ==========================================


func verify_configuration(correct_config: NetworkDevice) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(correct_config)
	var correct_server: ServerDevice = correct_config as ServerDevice

	if not correct_server:
		return {
			"device_id": device_id,
			"status": false,
			"error": "Invalid comparison device",
		}

	var is_correct = base_result.status
	var result = base_result.duplicate()

	# 1. Package Verification
	var pkg_result = { "status": true, "missing": [] }
	for g_pkg in correct_server.installed_packages:
		if not installed_packages.has(g_pkg):
			pkg_result.status = false
			pkg_result.missing.append(g_pkg)
	if not pkg_result.status:
		is_correct = false
	result["packages"] = pkg_result

	# 2. Interface Verification (IP Address & Subnet Mask Server)
	var interface_result = _verify_interfaces(correct_server.interfaces)
	if not interface_result.status:
		is_correct = false
	result["interfaces"] = interface_result

	# 3. Evaluasi Layanan Jaringan
	result["dhcp_service"] = _verify_service_array(dhcp_service, correct_server.dhcp_service, dhcp_configuration, correct_server.dhcp_configuration)
	result["dns_service"] = _verify_service_array(dns_service, correct_server.dns_service, dns_configuration, correct_server.dns_configuration)
	result["web_service"] = _verify_service_array(web_service, correct_server.web_service, web_configuration, correct_server.web_configuration)
	result["ftp_service"] = _verify_service_array(ftp_service, correct_server.ftp_service, ftp_configuration, correct_server.ftp_configuration)
	result["remote_service"] = _verify_service_array(remote_service, correct_server.remote_service, remote_configuration, correct_server.remote_configuration)
	result["samba_service"] = _verify_service_array(samba_service, correct_server.samba_service, samba_configuration, correct_server.samba_configuration)
	result["mariadb_service"] = _verify_service_array(mariadb_service, correct_server.mariadb_service, mariadb_configuration, correct_server.mariadb_configuration)
	result["mail_service"] = _verify_service_array(mail_service, correct_server.mail_service, mail_configuration, correct_server.mail_configuration)

	# Jika ada satu saja layanan yang gagal verifikasi, set status server ke false
	var services = ["dhcp_service", "dns_service", "web_service", "ftp_service", "remote_service", "samba_service", "mariadb_service", "mail_service"]
	for srv in services:
		if not result[srv].status:
			is_correct = false

	result["status"] = is_correct
	return result

# ==========================================
# HELPER FUNGSI GRADING
# ==========================================


func _verify_interfaces(correct_interfaces: Dictionary) -> Dictionary:
	if interfaces.size() != correct_interfaces.size():
		return {
			"status": false,
			"error": "Interface count mismatch",
		}

	var results: Dictionary = { }
	var is_correct: bool = true

	for interface_id in correct_interfaces:
		if not interfaces.has(interface_id):
			results[interface_id] = {
				"status": false,
				"error": "Missing interface",
			}
			is_correct = false
			continue

		var verify_result: Dictionary = interfaces[interface_id].verify_configuration(correct_interfaces[interface_id])
		results[interface_id] = verify_result

		if not verify_result.status:
			is_correct = false

	return {
		"status": is_correct,
		"results": results,
	}


func _verify_service_array(p_state: ServiceState, c_state: ServiceState, p_configs: Array, c_configs: Array) -> Dictionary:
	var eval = {
		"status": true,
		"service_state": { "status": p_state == c_state, "value": p_state, "correct": c_state },
		"details": [],
	}

	if not eval.service_state.status:
		eval.status = false
		return eval

	if c_state == ServiceState.ON:
		if p_configs.size() < c_configs.size():
			eval.status = false
			eval.error = "Konfigurasi kurang (Diharapkan %d, Ditemukan %d)" % [c_configs.size(), p_configs.size()]

		for c_conf in c_configs:
			if c_conf == null:
				continue
			var found_match = false
			var best_eval = null

			for p_conf in p_configs:
				if p_conf == null:
					continue

				var v = p_conf.verify_configuration(c_conf)
				best_eval = v

				if v.status:
					found_match = true
					eval.details.append(v)
					break

			if not found_match:
				eval.status = false
				if best_eval:
					eval.details.append(best_eval)
				else:
					eval.details.append({ "status": false, "error": "Konfigurasi tidak ditemukan atau tidak cocok" })

	return eval
