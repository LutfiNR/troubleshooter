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

func set_ip_address(ip: String, subnet: String) -> bool:
	if is_layer2():
		return false
	var new_ip := IPAddress.new(ip, subnet)
	if not new_ip.valid:
		return false
	export_ip_address = ip
	export_subnet_mask = subnet
	ip_address = new_ip
	return true

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
