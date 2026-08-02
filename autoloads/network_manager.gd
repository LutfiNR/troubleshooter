extends Node

signal device_updated(device_id: String, device_data: DeviceData)
signal devices_initialized()
signal cable_updated(cable_id: String, cable_data: CableData)

signal error_configuration(message: String)

var correct_configs: Dictionary
var runtime_configs: Dictionary
var runtime_cables: Dictionary
var mission_checking_result: Dictionary

func _ready():
	device_updated.connect(_on_device_updated)
	GameManager.mission_loaded.connect(_on_mission_loaded)

func _on_mission_loaded(mission: MissionData)-> void:
	correct_configs.clear()
	runtime_configs.clear()
	runtime_cables.clear()
	for key in mission.correct_configs:
		correct_configs[key] = load(mission.correct_configs[key])
	for key in mission.runtime_configs:
		runtime_configs[key] = load(mission.runtime_configs[key])
	for key in mission.runtime_cables:
		runtime_cables[key] = load(mission.runtime_cables[key])
	setup_all_devices()

func load_default_configuration(default_configs: Dictionary, default_cables: Dictionary)-> void:
	correct_configs.clear()
	runtime_configs.clear()
	runtime_cables.clear()
	for key in default_configs:
		correct_configs[key] = load(default_configs[key])
		runtime_configs[key] = load(default_configs[key])
	for key in default_cables:
		runtime_cables[key] = load(default_cables[key])
	setup_all_devices()
	
func setup_all_devices() -> void:
	for key in correct_configs:
		correct_configs[key].setup_device()
		runtime_configs[key].setup_device()
		device_updated.emit(key, runtime_configs[key])
	devices_initialized.emit()


func update_device_data(device_id: String, device_data: Variant) -> void:
	runtime_configs[device_id] = device_data
	device_updated.emit(device_id, runtime_configs[device_id])


func update_interface_device_data(device_id: String, interface_id: String, interface_data: NetworkInterface) -> void:
	var interfaces = runtime_configs[device_id].interfaces
	for i in interfaces.size():
		if interfaces[i].id == interface_id:
			interfaces[i] = interface_data
			device_updated.emit(device_id, runtime_configs[device_id])
			break


func get_runtime_device_data_by_id(device_id: String) -> DeviceData:
	return runtime_configs.get(device_id)

func get_correct_device_data_by_id(device_id: String) -> DeviceData:
	return correct_configs.get(device_id)


func _on_device_updated(device_id: String, _device_data: DeviceData) -> void:
	verify_configuration(device_id)


func verify_configuration(device_id: String) -> void:
	var correct_device = get_correct_device_data_by_id(device_id)
	var runtime_device = get_runtime_device_data_by_id(device_id)
	var result = correct_device.verify_configuration(runtime_device)
	mission_checking_result.merge(result, true)


## Register or update a cable connection between two devices.
func update_cable_data(cable_id: String, data: CableData) -> void:
	runtime_cables[cable_id] = data
	cable_updated.emit(cable_id, data)


## Remove a cable connection (one end unplugged while the other is free, or both).
func remove_cable_data(cable_id: String) -> void:
	runtime_cables.erase(cable_id)
	cable_updated.emit(cable_id, null)


## Returns all CableData where device_data is one of the two ends.
func get_cables_for_device(device_data: DeviceData) -> Array[CableData]:
	var result: Array[CableData] = []
	for cable: CableData in runtime_cables.values():
		if cable.device_a == device_data or cable.device_b == device_data:
			result.append(cable)
	return result

func get_reachable_devices(
		start: DeviceData,
		_excluded: Array[DeviceData] = [],
		stop_at_layer3: bool = false
) -> Array[Dictionary]:
	var reachable: Array[Dictionary] = []
	_excluded.append(start)
	for cable: CableData in get_cables_for_device(start):
		var peer: DeviceData
		var peer_iface_id: String
		if cable.device_a == start:
			peer = cable.device_b
			peer_iface_id = cable.interface_id_b
		else:
			peer = cable.device_a
			peer_iface_id = cable.interface_id_a
		if not peer or _excluded.has(peer):
			continue
		# Always add the peer to results.
		reachable.append({ "device": peer, "iface_id": peer_iface_id })
		# Routers are Layer-3 boundaries: when stop_at_layer3 is set,
		# include them so the caller can check for relay/routing,
		# but do not recurse through them (broadcasts don't cross routers).
		if stop_at_layer3 and peer is RouterDeviceData:
			_excluded.append(peer)
			continue

		reachable.append_array(get_reachable_devices(peer, _excluded, stop_at_layer3))
	return reachable

func check_connectivity(src_device_id: String, dst_device_id: String) -> Dictionary:
	var src: DeviceData = get_runtime_device_data_by_id(src_device_id)
	var dst: DeviceData = get_runtime_device_data_by_id(dst_device_id)

	if not src or not dst:
		return { "reachable": false, "reason": "Unknown device ID." }

	# Grab the primary Layer-3 interface for each device.
	var src_iface: NetworkInterface = _get_l3_interface(src)
	var dst_iface: NetworkInterface = _get_l3_interface(dst)

	if not src_iface or not src_iface.ip or not dst_iface or not dst_iface.ip:
		return { "reachable": false, "reason": "One or both devices have no IP address configured." }

	if not src_iface.is_up():
		return { "reachable": false, "reason": "Source interface is down." }
	if not dst_iface.is_up():
		return { "reachable": false, "reason": "Destination interface is down." }

	var src_ip: IPAddress = src_iface.ip
	var dst_ip: IPAddress = dst_iface.ip

	# Collect every device physically reachable from source (full graph walk).
	var reachable_entries: Array[Dictionary] = get_reachable_devices(src)

	# Helper: is a given DeviceData in the reachable set?
	var reachable_devices: Array[DeviceData] = []
	for entry: Dictionary in reachable_entries:
		reachable_devices.append(entry["device"])

	# ── Rule 1: same subnet ──────────────────────────────────────────────────
	if src_ip.is_same_subnet(dst_ip):
		if reachable_devices.has(dst):
			return { "reachable": true, "reason": "Same subnet, directly connected." }
		else:
			return { "reachable": false, "reason": "Same subnet but no physical path to destination." }
	if src is ComputerDeviceData and src.default_gateway != "":
		var gw_ip: IPAddress = IPAddress.parse(src.default_gateway)
		
		# Find the router reachable from src whose interface matches the gateway IP.
		for entry: Dictionary in reachable_entries:
			var candidate: DeviceData = entry["device"]
			if not candidate is RouterDeviceData:
				continue

			# Does one of the router's interfaces have the gateway IP?
			var gw_iface: NetworkInterface = _find_interface_by_ip(candidate, gw_ip)
			if not gw_iface:
				continue
			# Verify src is actually in the same subnet as the gateway interface.
			if not src_ip.is_same_subnet(gw_iface.ip):
				return {
					"reachable": false,
					"reason": "Source network does not match gateway subnet. Check IP/subnet mask.",
				}
			# Router found. Now check if it also has an interface in dst's subnet.
			var dst_facing_iface: NetworkInterface = _find_interface_in_subnet(candidate, dst_ip)
			if dst_facing_iface:
				return {
					"reachable": true,
					"reason": "Routed via %s (%s)." % [candidate.hostname, src.default_gateway],
				}
			else:
				return {
					"reachable": false,
					"reason": "Gateway %s reachable but has no route to destination subnet." % src.default_gateway,
				}
		return {
			"reachable": false,
			"reason": "Default gateway %s is not reachable." % src.default_gateway,
		}

	return { "reachable": false, "reason": "Different subnet and no default gateway configured." }


## Returns the first Layer-3 (THIRDLAYER) interface of a device that is UP, or null.
func _get_l3_interface(device: DeviceData) -> NetworkInterface:
	for iface: NetworkInterface in device.interfaces:
		if iface.layer == NetworkInterface.InterfaceLayer.THIRDLAYER and iface.is_up():
			return iface
	return null


## Returns the interface on [param device] whose IP matches [param target_ip] and is UP, or null.
func _find_interface_by_ip(device: DeviceData, target_ip: IPAddress) -> NetworkInterface:
	for iface: NetworkInterface in device.interfaces:
		if iface.layer != NetworkInterface.InterfaceLayer.THIRDLAYER:
			continue
		if not iface.is_up():
			continue
		if iface.ip and iface.ip.ip_to_string().split("/")[0] == target_ip.ip_to_string().split("/")[0]:
			return iface
	return null


## Returns the interface on [param device] that is in the same subnet as [param target_ip] and is UP, or null.
func _find_interface_in_subnet(device: DeviceData, target_ip: IPAddress) -> NetworkInterface:
	for iface: NetworkInterface in device.interfaces:
		if iface.layer != NetworkInterface.InterfaceLayer.THIRDLAYER:
			continue
		if not iface.is_up():
			continue
		if iface.ip and iface.ip.is_same_subnet(target_ip):
			return iface
	return null

func request_dhcp(client_device_id: String, interface_id: String) -> Dictionary:
	var client_device: DeviceData = get_runtime_device_data_by_id(client_device_id)
	if not client_device:
		push_error("GameManager.request_dhcp(): unknown device '%s'" % client_device_id)
		return { "success": false }

	var client_iface: NetworkInterface = client_device.get_interface(interface_id)
	if not client_iface:
		push_error("GameManager.request_dhcp(): interface '%s' not found on '%s'" % [interface_id, client_device_id])
		return { "success": false }

	var mac: String = client_iface.mac_address

	# Walk only the local broadcast domain (stop_at_layer3=true so we don't
	# cross routers). Routers still appear in the list for relay checking.
	for entry: Dictionary in get_reachable_devices(client_device, [], true):
		var peer_device: DeviceData = entry["device"]
		var peer_iface_id: String   = entry["iface_id"]

		var dhcp_response: Dictionary = {}

		if peer_device is ServerDeviceData:
			dhcp_response = peer_device.handle_dhcp_request(mac, peer_iface_id)

		elif peer_device is RouterDeviceData:
			# Check if the router has a DHCP relay on the interface facing the client.
			if peer_device.has_dhcp_relay(peer_iface_id):
				var relay_ip: IPAddress = peer_device.get_dhcp_relay_ip(peer_iface_id)
				if relay_ip:
					# relay_ip is the DHCP server address — use it to find the server.
					var server: ServerDeviceData = _find_server_by_ip(relay_ip.ip_to_string().split("/")[0])
					if server:
						# The router's own IP on this interface is the client's default gateway.
						var router_iface: NetworkInterface = peer_device.get_interface(peer_iface_id)
						if router_iface and router_iface.ip:
							var gateway_ip: String = router_iface.ip.ip_to_string().split("/")[0]
							var pool: DHCPService = server.handle_dhcp_relay_request(gateway_ip)
							if pool:
								dhcp_response = pool.request_ip(mac)
		# SwitchDeviceData / ComputerDeviceData: nothing to do, continue walking.
		if dhcp_response.get("success", false):
			return _apply_dhcp_response(client_device, client_iface, dhcp_response)
	return { "success": false }


## Applies a successful DHCP response to the client device's runtime state.
func _apply_dhcp_response(device: DeviceData, iface: NetworkInterface, cfg: Dictionary) -> Dictionary:
	iface.export_ip_address = cfg.get("ip_address", "")
	iface.export_subnet_mask = cfg.get("subnet_mask", "")
	iface.initialize_ip_from_export()

	if device is ComputerDeviceData:
		device.default_gateway = cfg.get("default_gateway", "")
		device.dns_server = cfg.get("dns_server", "")
	device_updated.emit(device.device_id, device)
	return cfg


## Finds a ServerDeviceData in the runtime config whose interface IP matches [param target_ip].
## Returns the ServerDeviceData, or null if not found.
func _find_server_by_ip(target_ip: String) -> ServerDeviceData:
	if target_ip == "":
		return null
	for key in runtime_configs:
		var device: DeviceData = runtime_configs[key]
		if not device is ServerDeviceData:
			continue
		for iface: NetworkInterface in device.interfaces:
			if iface.ip and iface.ip.ip_to_string().split("/")[0] == target_ip:
				return device
	return null

func request_dns_resolve(client_device_id: String, domain: String) -> String:
	var client_device: DeviceData = get_runtime_device_data_by_id(client_device_id)
	if not client_device:
		return ""
	var dns_server_ip: String = ""
	if client_device is ComputerDeviceData:
		dns_server_ip = client_device.dns_server
	elif client_device is ServerDeviceData:
		dns_server_ip = client_device.dns_server
	if dns_server_ip == "" or dns_server_ip == "0.0.0.0":
		return ""
	var dns_server: ServerDeviceData = _find_server_by_ip(dns_server_ip)
	if not dns_server:
		return ""
	return dns_server.handle_dns_request(domain)

func request_web(client_device_id: String, target_ip: String, is_https: bool) -> Dictionary:
	var _client_device: DeviceData = get_runtime_device_data_by_id(client_device_id)
	if not _client_device:
		return { "success": false, "error": "Unknown client device." }

	var server: ServerDeviceData = _find_server_by_ip(target_ip)
	if not server:
		return { "success": false, "error": "Server not found at " + target_ip + "." }

	return server.handle_web_request(target_ip, is_https)

func request_ftp_login(target_ip: String, username: String, password: String) -> Dictionary:
	var server: ServerDeviceData = _find_server_by_ip(target_ip)
	if not server:
		return { "success": false, "error": "Server not found at " + target_ip + "." }
	return server.handle_ftp_login(username, password)

func request_samba_login(target_ip: String, username: String, password: String) -> Dictionary:
	var server: ServerDeviceData = _find_server_by_ip(target_ip)
	if not server:
		return { "success": false, "error": "Server not found at " + target_ip + "." }
	return server.handle_samba_login(username, password)

func request_mail_login(target_ip: String, username: String, password: String) -> Dictionary:
	var server: ServerDeviceData = _find_server_by_ip(target_ip)
	if not server:
		return { "success": false, "error": "Server not found at " + target_ip + "." }
	return server.handle_mail_login(username, password)
