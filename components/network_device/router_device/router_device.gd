extends DeviceData

class_name RouterDeviceData

@export var dhcp_relays: Dictionary[String, DHCPRelayData] = { }


func setup_device() -> void:
	if interfaces.is_empty():
		for i: int in range(4):
			var iface: NetworkInterface = NetworkInterface.new()
			iface.id = "fa0/%d" % i
			iface.layer = NetworkInterface.InterfaceLayer.THIRDLAYER
			interfaces[i] = iface
	for interface in interfaces:
		interface.layer = NetworkInterface.InterfaceLayer.THIRDLAYER
	super.setup_device()
	for interface in interfaces:
		interface.initialize_ip_from_export()

	# Initialize DHCP Relays
	for relay_id in dhcp_relays:
		dhcp_relays[relay_id].setup_relay()


func add_dhcp_relay(interface_id: String, relay: DHCPRelayData) -> void:
	if interface_id.is_empty() or not relay:
		return
	dhcp_relays[interface_id] = relay


func remove_dhcp_relay(interface_id: String) -> void:
	if dhcp_relays.has(interface_id):
		dhcp_relays.erase(interface_id)


func set_dhcp_relay_ip(interface_id: String, ip_address: IPAddress) -> void:
	if not dhcp_relays.has(interface_id):
		dhcp_relays[interface_id] = DHCPRelayData.new()
	dhcp_relays[interface_id].ip_address = ip_address
	dhcp_relays[interface_id].interface_id = interface_id


func get_dhcp_relay(interface_id: String) -> DHCPRelayData:
	return dhcp_relays.get(interface_id)


func get_dhcp_relay_ip(interface_id: String) -> IPAddress:
	var relay: DHCPRelayData = get_dhcp_relay(interface_id)
	if not relay:
		return null
	return relay.ip_address


func has_dhcp_relay(interface_id: String) -> bool:
	return dhcp_relays.has(interface_id)


func get_all_dhcp_relays() -> Dictionary[String, DHCPRelayData]:
	return dhcp_relays


func clear_dhcp_relays() -> void:
	dhcp_relays.clear()


# Verify router configuration
func verify_configuration(runtime_device_configuration: DeviceData) -> Dictionary:
	var base_result: Dictionary = super.verify_configuration(runtime_device_configuration)
	var runtime_router: RouterDeviceData = runtime_device_configuration as RouterDeviceData

	if not runtime_router:
		push_error("Runtime device configuration is empty or invalid")
		return base_result

	var result: Dictionary = base_result[device_id].duplicate()
	var is_correct: bool = result["status"]

	# Network verification
	var relay_result: Dictionary = _verify_dhcp_relays(runtime_router.dhcp_relays)

	# Attach to result
	result["dhcp_relays"] = relay_result

	# Final status evaluation
	is_correct = (is_correct and relay_result["status"])
	result["status"] = is_correct

	return { device_id: result }


# Verify DHCP relays
func _verify_dhcp_relays(runtime_relays: Dictionary) -> Dictionary:
	var results: Dictionary = { }
	var is_correct: bool = true

	if dhcp_relays.size() != runtime_relays.size():
		is_correct = false

	for interface_id: String in dhcp_relays:
		var runtime_relay: DHCPRelayData = runtime_relays.get(interface_id)
		var verify_result: Dictionary = dhcp_relays[interface_id].verify_configuration(
			runtime_relay,
		)
		results[interface_id] = verify_result
		if not verify_result["status"]:
			is_correct = false
	return { "status": is_correct, "results": results }
