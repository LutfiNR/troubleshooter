extends DeviceData
class_name ComputerDeviceData

@export var default_gateway: String = ""
@export var dns_server: String = ""


func setup_device() -> void:
	if interfaces.is_empty():
		var iface: NetworkInterface = NetworkInterface.new()
		iface.id = "eth0"
		interfaces[0] = iface
	for interface in interfaces:
		interface.initialize_ip_from_export()
		
func get_interface(_interface_id: String) -> NetworkInterface:
	return interfaces[0]
	
func verify_configuration(runtime_device_configuration: DeviceData) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(runtime_device_configuration)
	var runtime_computer: ComputerDeviceData = runtime_device_configuration as ComputerDeviceData
	if not runtime_computer:
		push_error("Runtime device configuration is empty or invalid")
		return base_result

	var result : Dictionary = base_result[device_id].duplicate()
	var is_correct: bool = result.status
	var gateway_result: Dictionary = _verify_gateway(runtime_computer.default_gateway)
	var dns_result: Dictionary = _verify_dns(runtime_computer.dns_server)

	# Attach to result
	result["gateway"] = gateway_result
	result["dns"] = dns_result
	# Final status evaluation
	is_correct = (
		is_correct
		and gateway_result.status
		and dns_result.status
	)
	result["status"] = is_correct
	return {
		device_id: result
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
