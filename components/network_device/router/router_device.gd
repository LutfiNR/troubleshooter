extends NetworkDevice
class_name RouterDevice

@export var interfaces: Dictionary[String, NetworkInterface] = {}
@export var neighbors: Array[NeighborhoodData] = []
@export var dhcp_relays: Dictionary[String, DHCPRelay] = {}

func setup_device() -> void:
	if interfaces.is_empty():
		for i: int in range(4):
			var iface: NetworkInterface = NetworkInterface.new()
			iface.id = "fa0/%d" % i
			iface.layer = NetworkInterface.InterfaceLayer.THIRDLAYER
			# Restore connection state from neighbors
			for neighbor: NeighborhoodData in neighbors:
				if neighbor.interface == iface.id:
					iface.has_connection = true
					break
			interfaces[iface.id] = iface
			
	for iface_id in interfaces:
		interfaces[iface_id].setup_ip()

	# Initialize DHCP Relays
	for relay_id in dhcp_relays:
		dhcp_relays[relay_id].setup_relay()

func set_interface(interface_id: String, interface_data: NetworkInterface) -> void:
	if interface_id.is_empty() or not interface_data:
		return
	interface_data.id = interface_id
	interfaces[interface_id] = interface_data

func get_interface(interface_id: String) -> NetworkInterface:
	return interfaces.get(interface_id)

func has_interface(interface_id: String) -> bool:
	return interfaces.has(interface_id)

func get_interfaces() -> Dictionary[String, NetworkInterface]:
	return interfaces

func add_neighbor(neighbor: NeighborhoodData) -> void:
	if not neighbor:
		return
	neighbors.append(neighbor)

func remove_neighbor(interface_id: String) -> void:
	for i: int in range(neighbors.size()):
		if neighbors[i].interface == interface_id:
			neighbors.remove_at(i)
			return

func get_neighbor(interface_id: String) -> NeighborhoodData:
	for neighbor in neighbors:
		if neighbor.interface == interface_id:
			return neighbor
	return null

func add_dhcp_relay(interface_id: String, relay: DHCPRelay) -> void:
	if interface_id.is_empty() or not relay:
		return
	dhcp_relays[interface_id] = relay

func remove_dhcp_relay(interface_id: String) -> void:
	if dhcp_relays.has(interface_id):
		dhcp_relays.erase(interface_id)

func set_dhcp_relay_ip(interface_id: String, ip_address: IPAddress) -> void:
	if not dhcp_relays.has(interface_id):
		dhcp_relays[interface_id] = DHCPRelay.new()
	dhcp_relays[interface_id].ip_address = ip_address
	dhcp_relays[interface_id].interface_id = interface_id

func get_dhcp_relay(interface_id: String) -> DHCPRelay:
	return dhcp_relays.get(interface_id)

func get_dhcp_relay_ip(interface_id: String) -> IPAddress:
	var relay: DHCPRelay = get_dhcp_relay(interface_id)
	if not relay:
		return null
	return relay.ip_address

func has_dhcp_relay(interface_id: String) -> bool:
	return dhcp_relays.has(interface_id)

func get_all_dhcp_relays() -> Dictionary[String, DHCPRelay]:
	return dhcp_relays

func clear_dhcp_relays() -> void:
	dhcp_relays.clear()

# Verify router configuration
func verify_configuration(runtime_device_configuration: NetworkDevice) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(runtime_device_configuration)
	var runtime_router: RouterDevice = runtime_device_configuration as RouterDevice
	
	if not runtime_router:
		push_error("Runtime device configuration is empty or invalid")
		return base_result

	var result: Dictionary = base_result.duplicate()
	var is_correct: bool = base_result.status

	# Network verification
	var interface_result: Dictionary = _verify_interfaces(runtime_router.interfaces)
	var relay_result: Dictionary = _verify_dhcp_relays(runtime_router.dhcp_relays)
	
	# Attach to result
	result["interfaces"] = interface_result
	result["dhcp_relays"] = relay_result

	# Final status evaluation
	is_correct = (is_correct and interface_result.status and relay_result.status)
	result["status"] = is_correct
	
	return result

# Verify interfaces
func _verify_interfaces(runtime_interfaces: Dictionary) -> Dictionary:
	if interfaces.size() != runtime_interfaces.size():
		push_error("Jumlah interface tidak sesuai / Interface count mismatch")
		return {
			"status": false,
			"error": "Interface count mismatch",
		}

	var results: Dictionary = {}
	var is_correct: bool = true

	for interface_id: String in interfaces:
		if not runtime_interfaces.has(interface_id):
			results[interface_id] = {
				"status": false,
				"error": "Missing interface",
			}
			is_correct = false
			continue

		var verify_result: Dictionary = interfaces[interface_id].verify_configuration(
			runtime_interfaces[interface_id]
		)
		results[interface_id] = verify_result
		if not verify_result.status:
			is_correct = false
			
	return {
		"status": is_correct,
		"results": results,
	}

# Verify DHCP relays
func _verify_dhcp_relays(runtime_relays: Dictionary) -> Dictionary:
	var results: Dictionary = {}
	var is_correct: bool = true
	
	if dhcp_relays.size() != runtime_relays.size():
		push_warning("Jumlah DHCP relay tidak sesuai / DHCP relay count mismatch")
		is_correct = false
	
	for interface_id: String in dhcp_relays:
		var runtime_relay: DHCPRelay = runtime_relays.get(interface_id)
		var verify_result: Dictionary = dhcp_relays[interface_id].verify_configuration(
			runtime_relay
		)
		results[interface_id] = verify_result
		if not verify_result.status:
			is_correct = false
	return {
		"status": is_correct,
		"results": results,
	}
