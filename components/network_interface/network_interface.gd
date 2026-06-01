extends Resource

class_name NetworkInterface

enum InterfaceLayer {
	SECONDLAYER,
	THIRDLAYER,
}

enum InterfaceState {
	DOWN,
	UP,
}

@export var id: String = ""
@export var mac_address: String = ""
@export var layer: InterfaceLayer = InterfaceLayer.THIRDLAYER
@export var state: InterfaceState = InterfaceState.DOWN
@export_group("Layer 3 Configuration")
@export var export_ip_address: String = ""
@export var export_subnet_mask: String = ""

var has_connection: bool = false
var ip: IPAddress


func setup_ip() -> void:
	if is_layer2():
		ip = null
		return
	ip = IPAddress.new()
	ip.setup_ip_address(export_ip_address, export_subnet_mask)
	if not ip.valid:
		if ip.address != "":
			push_error("Invalid IP configuration on interface '%s'" % id)
		ip = null


func clear_ip_address() -> void:
	export_ip_address = ""
	export_subnet_mask = ""
	ip = null


func has_ip_address() -> bool:
	return ip != null


func is_layer2() -> bool:
	return layer == InterfaceLayer.SECONDLAYER


func is_layer3() -> bool:
	return layer == InterfaceLayer.THIRDLAYER


func is_up() -> bool:
	return state == InterfaceState.UP


func verify_configuration(
		runtime_interface: NetworkInterface,
		allocation_type_dhcp: bool = false,
		runtime_allocation_type_dhcp: bool = false
) -> Dictionary:
	var state_result := _verify_state(runtime_interface.state)
	var mac_result := _verify_mac_address(runtime_interface.mac_address)

	var ip_result := {
		"status": true,
	}
	if is_layer3():
		if allocation_type_dhcp:
			if runtime_allocation_type_dhcp:
				ip_result = {
					"status": true,
					"address": {
						"value": "",
						"correct": "[DHCP]",
						"status": true,
					},
					"subnet_mask": {
						"value": "",
						"correct": "[DHCP]",
						"status": true,
					},
				}
			else:
				ip_result = {
					"status": false,
					"address": {
						"value": "",
						"correct": "[DHCP]",
						"status": false,
					},
					"subnet_mask": {
						"value": "",
						"correct": "[DHCP]",
						"status": false,
					},
				}
		elif ip and runtime_interface.ip:
			ip_result = ip.verify_configuration(runtime_interface.ip)
		else:
			ip_result = {
			"status": false,
			"address": {
					"value": "",
					"correct": ip.address,
					"status": false,
				},
			"subnet_mask": {
					"value": "",
					"correct": ip.subnet_mask,
					"status": false,
				},
			"error": "Missing IP configuration",
			}

	var is_correct: bool = (
			state_result.status
			and mac_result.status
			and ip_result.status
	)

	return {
		"state": state_result,
		"mac_address": mac_result,
		"ip": ip_result,
		"status": is_correct,
	}


# Verify interface state
func _verify_state(runtime_interface_state: InterfaceState) -> Dictionary:
	var result := state == runtime_interface_state
	return {
		"correct": InterfaceState.keys()[state],
		"value": InterfaceState.keys()[runtime_interface_state],
		"status": result,
	}


# Verify MAC address
func _verify_mac_address(runtime_interface_mac: String) -> Dictionary:
	var result := mac_address == runtime_interface_mac

	return {
		"correct": mac_address,
		"value": runtime_interface_mac,
		"status": result,
	}
