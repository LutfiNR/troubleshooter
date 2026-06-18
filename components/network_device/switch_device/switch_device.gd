extends DeviceData
class_name SwitchDeviceData

@export_group("Switch Configuration")
@export var total_ports: int = 8

func setup_device() -> void:
	super.setup_device()
	if interfaces.is_empty():
		for i: int in range(total_ports):
			var iface: NetworkInterface = NetworkInterface.new()
			iface.id = "fa0/%d" % i
			iface.layer = NetworkInterface.InterfaceLayer.SECONDLAYER
			interfaces.append(iface)
	for iface in interfaces:
		iface.initialize_ip_from_export()

# Verify switch configuration
func verify_configuration(runtime_device_configuration: DeviceData) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(runtime_device_configuration)
	var runtime_switch: SwitchDeviceData = runtime_device_configuration as SwitchDeviceData

	if not runtime_switch:
		push_error("Runtime device configuration is empty or invalid")
		return base_result

	var result: Dictionary = base_result[device_id].duplicate()
	var is_correct: bool = result["status"]

	var port_result: Dictionary = _verify_total_ports(runtime_switch.total_ports)

	result["total_ports"] = port_result

	# Final status evaluation
	is_correct = ( is_correct and port_result.status )
	result["status"] = is_correct
	return {
		device_id: result
	}

# Verify total ports
func _verify_total_ports(runtime_ports: int) -> Dictionary:
	var result: bool = (total_ports == runtime_ports)
	return {
		"correct": total_ports,
		"value": runtime_ports,
		"status": result,
	}
