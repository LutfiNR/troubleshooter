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
	# Layer 2 interfaces do not use IP
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


func verify_configuration(correct_configuration: NetworkInterface) -> Dictionary:
	var id_result := _verify_id(correct_configuration.id)
	var state_result := _verify_state(correct_configuration.state)
	var mac_result := _verify_mac_address(correct_configuration.mac_address)
	var layer_result := _verify_layer(correct_configuration.layer)

	var ip_result := {
		"status": true,
	}
	var ip_correct = IPAddress.new()
	ip_correct.setup_ip_address(correct_configuration.export_ip_address, correct_configuration.export_subnet_mask)
	if is_layer3():
		if ip and ip_correct:
			ip_result = ip.verify_configuration(ip_correct)
		else:
			ip_result = {
				"status": false,
				"id": id_result,
				"state": state_result,
				"mac_address": mac_result,
				"layer": layer_result,
				"ip": ip_result,
				"error": "Missing IP configuration",
			}

	var is_correct: bool = (
			id_result.status
			and state_result.status
			and mac_result.status
			and layer_result.status
			and ip_result.status
	)

	return {
		"id": id_result,
		"state": state_result,
		"mac_address": mac_result,
		"layer": layer_result,
		"ip": ip_result,
		"status": is_correct,
	}


# Verify interface id
func _verify_id(correct_id: String) -> Dictionary:
	var result := id == correct_id

	return {
		"value": id,
		"correct": correct_id,
		"status": result,
	}


# Verify interface state
func _verify_state(correct_state: InterfaceState) -> Dictionary:
	var result := state == correct_state

	return {
		"value": state,
		"correct": correct_state,
		"status": result,
	}


# Verify MAC address
func _verify_mac_address(correct_mac_address: String) -> Dictionary:
	var result := mac_address == correct_mac_address

	return {
		"value": mac_address,
		"correct": correct_mac_address,
		"status": result,
	}


# Verify interface layer
func _verify_layer(correct_layer: InterfaceLayer) -> Dictionary:
	var result := layer == correct_layer
	return {
		"value": layer,
		"correct": correct_layer,
		"status": result,
	}
