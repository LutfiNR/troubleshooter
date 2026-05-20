extends NetworkDevice

class_name ComputerDevice

enum IPAllocationType {
	STATIC,
	DHCP,
}

@export var ip_allocation_type: IPAllocationType = IPAllocationType.STATIC
@export var default_gateway: String = ""
@export var dns_server: String = ""

@export var interfaces: Dictionary[String, NetworkInterface] = { }
@export var neighbors: Array[NeighborhoodData] = []


func _init() -> void:
	# Default interface
	if interfaces.is_empty():
		var iface: NetworkInterface = NetworkInterface.new()

		iface.id = "eth0"

		# Restore connection state from neighbors
		for neighbor: NeighborhoodData in neighbors:
			if neighbor.interface == iface.id:
				iface.has_connection = true
				break

		interfaces[iface.id] = iface


# Set IP allocation type
func set_ip_allocation_type(value: IPAllocationType) -> void:
	ip_allocation_type = value


# Get IP allocation type
func get_ip_allocation_type() -> IPAllocationType:
	return ip_allocation_type


# Set default gateway
func set_gateway(value: String) -> void:
	default_gateway = value


# Get default gateway
func get_gateway() -> String:
	return default_gateway


# Set DNS server
func set_dns_server(value: String) -> void:
	dns_server = value


# Get DNS server
func get_dns_server() -> String:
	return dns_server


# Add interface
func add_interface(interface_data: NetworkInterface) -> void:
	if not interface_data:
		return

	interfaces[interface_data.id] = interface_data


# Remove interface
func remove_interface(interface_id: String) -> void:
	if interfaces.has(interface_id):
		interfaces.erase(interface_id)


# Get interface by id
func get_interface(interface_id: String) -> NetworkInterface:
	return interfaces.get(interface_id)


# Get all interfaces
func get_interfaces() -> Dictionary[String, NetworkInterface]:
	return interfaces


# Check interface exists
func has_interface(interface_id: String) -> bool:
	return interfaces.has(interface_id)


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
func get_neighbors() -> Array[NeighborhoodData]:
	return neighbors


# Verify full computer configuration
func verify_configuration(correct_config: NetworkDevice) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(
		correct_config,
	)

	var correct_computer: ComputerDevice = (
			correct_config as ComputerDevice
	)

	if not correct_computer:
		return {
			"device_id": device_id,
			"status": false,
			"error": "Invalid comparison device",
		}

	var ip_result: Dictionary = _verify_ip_allocation(
		correct_computer.ip_allocation_type,
	)

	var gateway_result: Dictionary = _verify_gateway(
		correct_computer.default_gateway,
	)

	var dns_result: Dictionary = _verify_dns(
		correct_computer.dns_server,
	)

	var interface_result: Dictionary = _verify_interfaces(
		correct_computer.interfaces,
	)

	var is_correct: bool = (
			base_result.status
			and ip_result.status
			and gateway_result.status
			and dns_result.status
			and interface_result.status
	)

	var result: Dictionary = base_result.duplicate()

	result.merge(
		{
			"status": is_correct,
			"ip_allocation": ip_result,
			"gateway": gateway_result,
			"dns": dns_result,
			"interfaces": interface_result,
		},
		true,
	)

	return result


# Verify IP allocation type
func _verify_ip_allocation(
		correct_type: IPAllocationType,
) -> Dictionary:
	var result: bool = (
			ip_allocation_type == correct_type
	)

	return {
		"value": ip_allocation_type,
		"correct": correct_type,
		"status": result,
	}


# Verify gateway
func _verify_gateway(correct_gateway: String) -> Dictionary:
	var result: bool = (
			default_gateway == correct_gateway
	)

	return {
		"value": default_gateway,
		"correct": correct_gateway,
		"status": result,
	}


# Verify DNS server
func _verify_dns(correct_dns: String) -> Dictionary:
	var result: bool = (
			dns_server == correct_dns
	)

	return {
		"value": dns_server,
		"correct": correct_dns,
		"status": result,
	}


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

		var verify_result: Dictionary = (
				interfaces[interface_id]
				.verify_configuration(
					correct_interfaces[interface_id],
				)
		)

		results[interface_id] = verify_result

		if not verify_result.status:
			is_correct = false

	return {
		"status": is_correct,
		"results": results,
	}
