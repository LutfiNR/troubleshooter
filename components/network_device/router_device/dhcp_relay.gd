extends Resource
class_name DHCPRelayData

@export var interface_id: String = ""
@export var export_ip_address: String = ""

var ip_address: IPAddress


func setup_relay() -> void:
	# If no IP is provided in the inspector, leave it null
	if export_ip_address.is_empty():
		ip_address = null
		return

	ip_address = IPAddress.new(export_ip_address, -1)

	if not ip_address.is_valid():
		push_error("Invalid IP configuration on DHCP Relay for interface '%s'" % interface_id)
		ip_address = null


# Verify this specific relay configuration
func verify_configuration(runtime_relay: DHCPRelayData = null) -> Dictionary:
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
		var ip_match = ip_address.ip_to_string() == runtime_ip.ip_to_string()
		ip_result = {
			"value": runtime_ip.ip_to_string(),
			"correct": ip_address.ip_to_string(),
			"status": ip_match,
		}
	elif not ip_address and not runtime_ip:
		ip_result = {
			"value": "null",
			"correct": "null",
			"status": true,
		}
	else:
		ip_result = {
			"value": runtime_ip.ip_to_string() if runtime_ip != null else "null",
			"correct": ip_address.ip_to_string() if ip_address != null else "null",
			"status": false,
		}

	var is_correct: bool = (interface_result and ip_result["status"])

	return {
		"status": is_correct,
		"interface_id": {
			"correct": interface_id,
			"value": runtime_interface_id,
			"status": interface_result,
		},
		"ip_address": ip_result,
	}
