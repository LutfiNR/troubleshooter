extends NetworkDevice

class_name RouterDevice

class DHCPRelay:
	var ip_address: IPAddress
	var interface_id: String


@export var interfaces: Dictionary[String, NetworkInterface] = { }
@export var neighbors: Array[NeighborhoodData] = []

var dhcp_relays: Dictionary[String, DHCPRelay] = { }


func _init() -> void:
	# Default router interface
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

# Set interface
func set_interface(
		interface_id: String,
		interface_data: NetworkInterface,
) -> void:
	if interface_id.is_empty() or not interface_data:
		return

	interface_data.id = interface_id
	interfaces[interface_id] = interface_data


# Get interface
func get_interface(interface_id: String) -> NetworkInterface:
	return interfaces.get(interface_id)


# Check interface exists
func has_interface(interface_id: String) -> bool:
	return interfaces.has(interface_id)


# Get all interfaces
func get_interfaces() -> Dictionary[String, NetworkInterface]:
	return interfaces

# Add neighbor
func add_neighbor(neighbor: NeighborhoodData) -> void:
	if not neighbor:
		return

	neighbors.append(neighbor)


# Remove neighbor by interface
func remove_neighbor(interface_id: String) -> void:
	for i: int in range(neighbors.size()):
		if neighbors[i].interface == interface_id:
			neighbors.remove_at(i)
			return


# Get neighbors
func get_neighbor(interface_id: String) -> NeighborhoodData:
	for neighbor in neighbors:
		if neighbor.interface == interface_id:
			return neighbor
	return null


# Add DHCP relay
func add_dhcp_relay(interface_id: String, relay: DHCPRelay) -> void:
	if interface_id.is_empty() or not relay:
		return

	dhcp_relays[interface_id] = relay


# Remove DHCP relay
func remove_dhcp_relay(interface_id: String) -> void:
	if dhcp_relays.has(interface_id):
		dhcp_relays.erase(interface_id)


# Set DHCP relay IP
func set_dhcp_relay_ip(
		interface_id: String,
		ip_address: IPAddress,
) -> void:
	if not dhcp_relays.has(interface_id):
		dhcp_relays[interface_id] = DHCPRelay.new()

	dhcp_relays[interface_id].ip_address = ip_address
	dhcp_relays[interface_id].interface_id = interface_id


# Get DHCP relay
func get_dhcp_relay(interface_id: String) -> DHCPRelay:
	return dhcp_relays.get(interface_id)


# Get DHCP relay IP
func get_dhcp_relay_ip(interface_id: String) -> IPAddress:
	var relay: DHCPRelay = get_dhcp_relay(interface_id)

	if not relay:
		return null

	return relay.ip_address


# Check DHCP relay exists
func has_dhcp_relay(interface_id: String) -> bool:
	return dhcp_relays.has(interface_id)


# Get all DHCP relays
func get_all_dhcp_relays() -> Dictionary[String, DHCPRelay]:
	return dhcp_relays


# Clear all DHCP relays
func clear_dhcp_relays() -> void:
	dhcp_relays.clear()


# Verify router configuration
func verify_configuration(correct_config: NetworkDevice) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(correct_config)

	var correct_router: RouterDevice = correct_config as RouterDevice

	if not correct_router:
		return {
			"device_id": device_id,
			"status": false,
			"error": "Invalid comparison device",
		}

	var interface_result: Dictionary = _verify_interfaces(
		correct_router.interfaces,
	)

	var relay_result: Dictionary = _verify_dhcp_relays(
		correct_router.dhcp_relays,
	)

	var is_correct: bool = (
			base_result.status
			and interface_result.status
			and relay_result.status
	)

	var result: Dictionary = base_result.duplicate()

	result.merge(
		{
			"status": is_correct,
			"interfaces": interface_result,
			"dhcp_relays": relay_result,
		},
		true,
	)

	return result


# Verify interfaces
func _verify_interfaces(
		correct_interfaces: Dictionary[String, NetworkInterface],
) -> Dictionary:
	if interfaces.size() != correct_interfaces.size():
		return {
			"status": false,
			"error": "Interface count mismatch",
		}

	var results: Dictionary[String, Dictionary] = { }
	var is_correct: bool = true

	for interface_id: String in correct_interfaces:
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


# Verify DHCP relays
func _verify_dhcp_relays(
		correct_relays: Dictionary[String, DHCPRelay],
) -> Dictionary:
	if dhcp_relays.size() != correct_relays.size():
		return {
			"status": false,
			"error": "DHCP relay count mismatch",
		}

	var results: Dictionary[String, Dictionary] = { }
	var is_correct: bool = true

	for interface_id: String in correct_relays:
		if not dhcp_relays.has(interface_id):
			results[interface_id] = {
				"status": false,
				"error": "Missing relay",
			}

			is_correct = false
			continue

		var verify_result: Dictionary = _verify_dhcp_relay(
			dhcp_relays[interface_id],
			correct_relays[interface_id],
		)

		results[interface_id] = verify_result

		if not verify_result.status:
			is_correct = false

	return {
		"status": is_correct,
		"results": results,
	}


# Verify single DHCP relay
func _verify_dhcp_relay(
		current: DHCPRelay,
		correct: DHCPRelay,
) -> Dictionary:
	if not current or not correct:
		return {
			"status": false,
			"error": "Invalid relay",
		}

	var interface_result: bool = (
			current.interface_id == correct.interface_id
	)

	var ip_result: Dictionary = {
		"status": false,
	}

	if current.ip_address and correct.ip_address:
		ip_result = current.ip_address.verify_configuration(
			correct.ip_address,
		)

	var is_correct: bool = (
			interface_result
			and ip_result.status
	)

	return {
		"status": is_correct,
		"interface_id": {
			"value": current.interface_id,
			"correct": correct.interface_id,
			"status": interface_result,
		},
		"ip_address": ip_result,
	}
