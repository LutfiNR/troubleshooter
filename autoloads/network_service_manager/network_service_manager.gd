extends Node

# ==========================================
# 1. DHCP SERVICE (Request IP Otomatis)
# ==========================================
func request_dhcp(client_device_id: String, client_interface_id: String) -> Dictionary:
	var client_device = NetworkDeviceManager.get_device_data(client_device_id)
	if not client_device:
		return { "success": false, "error": "Device not found." }

	# Cari server yang menjalankan DHCP
	var dhcp_server_info = _find_reachable_dhcp_server()
	if dhcp_server_info.is_empty():
		return { "success": false, "error": "DHCP Request timed out. No DHCP server found." }

	var server: ServerDevice = dhcp_server_info["server"]
	var server_interface_id: String = dhcp_server_info["interface_id"]
	var mock_mac = "MAC-" + client_device_id + "-" + client_interface_id

	# Minta IP ke Server
	var ip_config = server.handle_dhcp_request(mock_mac, server_interface_id)
	if ip_config.is_empty():
		return { "success": false, "error": "DHCP Server exhausted or misconfigured." }

	# Terapkan konfigurasi ke Klien
	var client_iface = client_device.get_interface(client_interface_id)
	if client_iface:
		client_iface.export_ip_address = ip_config["ip_address"]
		client_iface.export_subnet_mask = ip_config["subnet_mask"]
		client_iface.setup_ip()

	if client_device is ComputerDevice:
		client_device.set_gateway(ip_config["default_gateway"])
		client_device.set_dns_server(ip_config["dns_server"])
		client_device.set_ip_allocation_type(ComputerDevice.IPAllocationType.DHCP)

	NetworkDeviceManager.update_device(client_device_id, client_device)
	return { "success": true, "ip": ip_config["ip_address"], "message": "DHCP ACK: " + ip_config["ip_address"] }


# ==========================================
# 2. DNS SERVICE (Resolve Domain -> IP)
# ==========================================
func request_dns_resolve(client_device_id: String, domain: String) -> String:
	var client_device = NetworkDeviceManager.get_device_data(client_device_id)
	if not client_device or not client_device is ComputerDevice:
		return ""

	var dns_ip = client_device.get_dns_server()
	if dns_ip.is_empty():
		return ""

	var server = _find_server_by_ip(dns_ip)
	if server and server.power == NetworkDevice.PowerState.ON and server.dns_service == ServerDevice.ServiceState.ON:
		return server.handle_dns_request(domain)

	return ""


# ==========================================
# 3. WEB SERVICE (HTTP/HTTPS)
# ==========================================
func request_web(client_device_id: String, url: String, is_https: bool) -> Dictionary:
	var target_ip = url

	# Jika URL berupa nama domain (bukan IP murni), coba resolve via DNS
	if not _is_valid_ip(url):
		target_ip = request_dns_resolve(client_device_id, url)
		if target_ip.is_empty():
			return { "success": false, "error": "DNS Resolution Failed: Server not found." }

	var server = _find_server_by_ip(target_ip)
	if not server:
		return { "success": false, "error": "Connection Timed Out (Host Unreachable)." }

	if server.web_service == ServerDevice.ServiceState.OFF:
		return { "success": false, "error": "Connection Refused (Web Service is down)." }

	var web_content = server.handle_web_request(target_ip, url, is_https)
	if not web_content:
		return { "success": false, "error": "404 Not Found (Virtual Host missing or protocol disabled)." }

	return { "success": true, "content": web_content.content }


# ==========================================
# 4. FTP SERVICE
# ==========================================
func request_ftp_login(target_ip: String, username: String, password: String) -> Dictionary:
	var server = _find_server_by_ip(target_ip)
	if not server:
		return { "success": false, "error": "Connection Timed Out." }

	var ftp = server.handle_ftp_request()
	if not ftp:
		return { "success": false, "error": "Connection Refused (FTP is OFF)." }

	var user = ftp.authenticate(username, password)
	if user:
		return { "success": true, "message": "Logged in successfully.", "home_dir": user.home_directory }
	return { "success": false, "error": "530 Login incorrect." }


# ==========================================
# 5. REMOTE SERVICE (SSH & Telnet)
# ==========================================
func request_remote_login(target_ip: String, protocol: String, username: String, password: String) -> Dictionary:
	var server = _find_server_by_ip(target_ip)
	if not server:
		return { "success": false, "error": "Connection Timed Out." }

	var remote = server.handle_remote_request()
	if not remote:
		return { "success": false, "error": "Connection Refused." }

	var is_auth = false
	if protocol.to_lower() == "ssh":
		is_auth = remote.authenticate_ssh(username, password)
	elif protocol.to_lower() == "telnet":
		is_auth = remote.authenticate_telnet(username, password)

	if is_auth:
		return { "success": true, "message": "Connected to " + server.hostname }
	return { "success": false, "error": "Access Denied / Invalid Credentials." }


# ==========================================
# 6. MAIL SERVICE
# ==========================================
func request_mail_login(target_ip: String, username: String, password: String) -> Dictionary:
	var server = _find_server_by_ip(target_ip)
	if not server:
		return { "success": false, "error": "Connection Timed Out." }

	var mail = server.handle_mail_request()
	if not mail:
		return { "success": false, "error": "Connection Refused (Mail is OFF)." }

	if mail.authenticate(username, password):
		return { "success": true, "message": "Mail server authentication successful." }
	return { "success": false, "error": "Authentication failed." }


# ==========================================
# 7. MARIADB SERVICE
# ==========================================
func request_mariadb_login(target_ip: String, username: String, password: String) -> Dictionary:
	var server = _find_server_by_ip(target_ip)
	if not server:
		return { "success": false, "error": "ERROR 2002 (HY000): Can't connect to server" }

	var mariadb = server.handle_mariadb_request()
	if not mariadb:
		return { "success": false, "error": "ERROR 2002: Connection Refused" }

	var user = mariadb.authenticate(username, password)
	if user:
		return { "success": true, "message": "Welcome to the MariaDB monitor.", "user_data": user }
	return { "success": false, "error": "ERROR 1045 (28000): Access denied for user" }


# ==========================================
# 8. SAMBA SERVICE
# ==========================================
func request_samba_login(target_ip: String, username: String, password: String) -> Dictionary:
	var server = _find_server_by_ip(target_ip)
	if not server:
		return { "success": false, "error": "Network path not found." }

	var samba = server.handle_samba_request()
	if not samba:
		return { "success": false, "error": "Connection Refused." }

	var user = samba.authenticate(username, password)
	if user:
		return { "success": true, "message": "Samba authentication successful.", "user_data": user }
	return { "success": false, "error": "NT_STATUS_LOGON_FAILURE" }

# ==========================================
# INTERNAL HELPERS (Routing Simulation)
# ==========================================


func _find_server_by_ip(ip_address: String) -> ServerDevice:
	for server_id in NetworkDeviceManager.server_devices:
		var server = NetworkDeviceManager.server_devices[server_id]
		if server.power == NetworkDevice.PowerState.OFF:
			continue

		for iface in server.get_interfaces().values():
			if iface.has_ip_address() and iface.ip.address == ip_address:
				return server
	return null


func _find_reachable_dhcp_server() -> Dictionary:
	# Simulasi sederhana: Cari server manapun yang aktif dan layanan DHCP-nya menyala.
	for server_id in NetworkDeviceManager.server_devices:
		var server = NetworkDeviceManager.server_devices[server_id]
		if server.power == NetworkDevice.PowerState.ON and server.dhcp_service == ServerDevice.ServiceState.ON:
			# Asumsi: Melayani DHCP lewat eth0 (bisa Anda sesuaikan jika server punya banyak interface)
			return { "server": server, "interface_id": "eth0" }
	return { }


func _is_valid_ip(text: String) -> bool:
	var parts = text.split(".")
	if parts.size() != 4:
		return false
	for p in parts:
		if not p.is_valid_int():
			return false
	return true
