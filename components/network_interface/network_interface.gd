extends Resource
class_name NetworkInterface

enum InterfaceLayer {
	SECONDLAYER,
	THIRDLAYER
}

enum InterfaceState {
	DOWN,
	UP
}

@export var id: String = ""
@export var mac_address: String = ""
@export var layer: InterfaceLayer = InterfaceLayer.THIRDLAYER
@export var state: InterfaceState = InterfaceState.DOWN
@export_group("Layer 3 Configuration")
@export var export_ip_address: String = ""
@export var export_subnet_mask: String = ""

var ip_address: IPAddress = null

func _init() -> void:
	setup_ip_address()

func setup_ip_address() -> void:
	# Layer 2 interfaces do not use IP
	if is_layer2():
		ip_address = null
		return
	ip_address = IPAddress.new(
		export_ip_address,
		export_subnet_mask
	)
	if not ip_address.valid:
		push_error(
			"Invalid IP configuration on interface '%s'" % id
		)
		ip_address = null

func clear_ip_address() -> void:
	export_ip_address = ""
	export_subnet_mask = ""
	ip_address = null

func has_ip_address() -> bool:
	return ip_address != null

func is_layer2() -> bool:
	return layer == InterfaceLayer.SECONDLAYER

func is_layer3() -> bool:
	return layer == InterfaceLayer.THIRDLAYER

func is_up() -> bool:
	return state == InterfaceState.UP

func verify_configuration(correct_configuration: NetworkInterface)-> bool:
	var is_correct: bool = true
	is_correct = is_correct and _verify_id(correct_configuration.id)
	is_correct = is_correct and _verify_state(correct_configuration.state)
	is_correct = is_correct and _verify_mac_address(correct_configuration.mac_address)
	is_correct = is_correct and _verify_layer(correct_configuration.layer)
	if is_layer3():
		is_correct = is_correct and ip_address.verify_configuration(correct_configuration.ip_address)
	return is_correct

func _verify_id(correct_id)-> bool:
	if id != correct_id:
		return false
	return true

func _verify_state(correct_state: InterfaceState) -> bool:
	if state != correct_state:
		return false
	return true

func _verify_mac_address(correct_mac_address: String) -> bool:
	if mac_address != correct_mac_address:
		return false
	return true

func _verify_layer(correct_layer: InterfaceLayer) -> bool:
	if layer != correct_layer:
		return false
	return true
