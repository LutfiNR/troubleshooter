extends Resource
class_name DHCPRelay

@export var interface_id: String = ""
@export var export_ip_address: String = ""

var ip_address: IPAddress

func setup_relay() -> void:
	# If no IP is provided in the inspector, leave it null
	if export_ip_address.is_empty():
		ip_address = null
		return
		
	ip_address = IPAddress.new()
	# We pass 255.255.255.255 because a relay targets a single host server
	ip_address.setup_ip_address(export_ip_address, "255.255.255.0")
	
	if not ip_address.valid:
		push_error("Invalid IP configuration on DHCP Relay for interface '%s'" % interface_id)
		ip_address = null

# Verify this specific relay configuration
func verify_configuration(runtime_relay: DHCPRelay = null) -> Dictionary:
	var has_runtime := runtime_relay != null
	var runtime_interface_id: Variant = null
	var runtime_ip: IPAddress = null
	if has_runtime:
		runtime_interface_id = runtime_relay.interface_id
		runtime_ip = runtime_relay.ip_address
	var interface_result: bool = has_runtime and (interface_id == runtime_interface_id)
	var ip_result: Dictionary
	
	# Handle the nested IPAddress verification safely
	if ip_address and runtime_ip:
		ip_result = ip_address.verify_configuration(runtime_ip)
	elif not ip_address and not runtime_ip:
		ip_result = { "status": true }
	else:
		if ip_address:
			ip_result = ip_address.verify_configuration(IPAddress.new())
			ip_result["status"] = false
		else:
			ip_result = { "status": false }
	
	if ip_result.has("subnet_mask"):
		ip_result.erase("subnet_mask")

	var is_correct: bool = (interface_result and ip_result.status)
	
	return {
		"status": is_correct,
		"interface_id": {
			"correct": interface_id,
			"value": runtime_interface_id,
			"status": interface_result,
		},
		"ip_address": ip_result,
	}
