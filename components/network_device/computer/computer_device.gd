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


func setup_device() -> void:
	if interfaces.is_empty():
		var iface: NetworkInterface = NetworkInterface.new()
		iface.id = "eth0"
		# Restore connection state from neighbors
		for neighbor: NeighborhoodData in neighbors:
			if neighbor.interface == iface.id:
				iface.has_connection = true
				break
		interfaces[iface.id] = iface
	for iface_id in interfaces:
		interfaces[iface_id].setup_ip()

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
func get_interface(_interface_id: String = "") -> NetworkInterface:
	if _interface_id != "":
		return interfaces.get(_interface_id, null)
	return interfaces.values()[0]

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
func get_neighbors() -> NeighborhoodData:
	return neighbors[0]

func verify_configuration(runtime_device_configuration: NetworkDevice) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(runtime_device_configuration)
	var runtime_computer: ComputerDevice = runtime_device_configuration as ComputerDevice
	if not runtime_computer:
		push_error("Runtime device configuration is empty or invalid")
		return base_result

	var result := base_result.duplicate()
	var is_correct: bool = base_result.status
	# Network verification
	var ip_result: Dictionary = _verify_ip_allocation(runtime_computer.ip_allocation_type)
	var gateway_result: Dictionary = _verify_gateway(runtime_computer.default_gateway)
	var dns_result: Dictionary = _verify_dns(runtime_computer.dns_server)
	var interfaces_result: Dictionary = _verify_interfaces(
		runtime_computer.interfaces,
		runtime_computer.ip_allocation_type
		)
	# Attach to result
	result["ip_allocation"] = ip_result
	result["gateway"] = gateway_result
	result["dns"] = dns_result
	result["interfaces"] = interfaces_result
	# Final status evaluation
	is_correct = (
		is_correct
		and ip_result.status
		and gateway_result.status
		and dns_result.status
		and interfaces_result.status
	)
	result["status"] = is_correct
	return result


# Verify IP allocation type
func _verify_ip_allocation(runtime_type: IPAllocationType) -> Dictionary:
	var result: bool = (ip_allocation_type == runtime_type)
	return {
		"correct": ip_allocation_type,
		"value": runtime_type,
		"status": result,
	}


# Verify gateway
func _verify_gateway(runtime_ip_gateway: String) -> Dictionary:
	var result: bool = (default_gateway == runtime_ip_gateway)
	return {
		"correct": default_gateway,
		"value": runtime_ip_gateway,
		"status": result,
	}

# Verify DNS server
func _verify_dns(runtime_ip_dns: String) -> Dictionary:
	var result: bool = (dns_server == runtime_ip_dns)
	return {
		"correct": dns_server,
		"value": runtime_ip_dns,
		"status": result,
	}

# Verify interfaces
func _verify_interfaces(runtime_interfaces: Dictionary, runtime_ip_allocation_type: IPAllocationType) -> Dictionary:
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
			runtime_interfaces[interface_id],
			ip_allocation_type,
			runtime_ip_allocation_type,
		)
		results[interface_id] = verify_result
		if not verify_result.status:
			is_correct = false
	return {
		"status": is_correct,
		"results": results,
	}
