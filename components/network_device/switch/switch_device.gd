extends NetworkDevice

class_name SwitchDevice

@export_group("Switch Configuration")
@export var total_ports: int = 8

@export var interfaces: Dictionary[String, NetworkInterface] = { }


func setup_device() -> void:
	if interfaces.is_empty():
		for i: int in range(total_ports):
			var iface: NetworkInterface = NetworkInterface.new()
			iface.id = "fa0/%d" % i
			iface.layer = NetworkInterface.InterfaceLayer.SECONDLAYER
			interfaces[iface.id] = iface
	for iface_id in interfaces:
		interfaces[iface_id].setup_ip()

# Add interface
func add_interface(interface_data: NetworkInterface) -> void:
	if not interface_data:
		return
	interfaces[interface_data.id] = interface_data

# Remove interface
func remove_interface(interface_id: String) -> void:
	if interfaces.has(interface_id):
		interfaces.erase(interface_id)

# Set interface
func set_interface( interface_id: String, interface_data: NetworkInterface, ) -> void:
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

# Clear interfaces
func clear_interfaces() -> void:
	interfaces.clear()

# Verify switch configuration
func verify_configuration(runtime_device_configuration: NetworkDevice) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(runtime_device_configuration)
	var runtime_switch: SwitchDevice = runtime_device_configuration as SwitchDevice

	if not runtime_switch:
		push_error("Runtime device configuration is empty or invalid")
		return base_result

	var result: Dictionary = base_result.duplicate()
	var is_correct: bool = base_result.status

	# Network verification
	var port_result: Dictionary = _verify_total_ports(runtime_switch.total_ports)
	var interface_result: Dictionary = _verify_interfaces(runtime_switch.interfaces)

	# Attach to result
	result["total_ports"] = port_result
	result["interfaces"] = interface_result

	# Final status evaluation
	is_correct = ( is_correct and port_result.status and interface_result.status )
	result["status"] = is_correct
	return result

# Verify total ports
func _verify_total_ports(runtime_ports: int) -> Dictionary:
	var result: bool = (total_ports == runtime_ports)
	return {
		"correct": total_ports,
		"value": runtime_ports,
		"status": result,
	}

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
