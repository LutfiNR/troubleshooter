extends NetworkDevice

class_name SwitchDevice

@export_group("Switch Configuration")
@export var total_ports: int = 8

@export var interfaces: Dictionary[String, NetworkInterface] = { }


func _init() -> void:
	# Create default switch ports
	if interfaces.is_empty():
		for i: int in range(total_ports):
			var iface: NetworkInterface = NetworkInterface.new()

			iface.id = "fa0/%d" % i
			iface.layer = NetworkInterface.InterfaceLayer.SECONDLAYER

			interfaces[iface.id] = iface


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


# Clear interfaces
func clear_interfaces() -> void:
	interfaces.clear()


# Verify switch configuration
func verify_configuration(correct_config: NetworkDevice) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(
		correct_config,
	)

	var correct_switch: SwitchDevice = (
			correct_config as SwitchDevice
	)

	if not correct_switch:
		return {
			"device_id": device_id,
			"status": false,
			"error": "Invalid comparison device",
		}

	var port_result: Dictionary = _verify_total_ports(
		correct_switch.total_ports,
	)

	var interface_result: Dictionary = _verify_interfaces(
		correct_switch.interfaces,
	)

	var is_correct: bool = (
			base_result.status
			and port_result.status
			and interface_result.status
	)

	var result: Dictionary = base_result.duplicate()

	result.merge(
		{
			"status": is_correct,
			"total_ports": port_result,
			"interfaces": interface_result,
		},
		true,
	)

	return result


# Verify total ports
func _verify_total_ports(correct_ports: int) -> Dictionary:
	var result: bool = (
			total_ports == correct_ports
	)

	return {
		"value": total_ports,
		"correct": correct_ports,
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
