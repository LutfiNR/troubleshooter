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

enum IPAllocationMode {
	STATIC,
	DHCP,
}

@export var id: String = ""
@export var mac_address: String = ""
@export var layer: InterfaceLayer = InterfaceLayer.THIRDLAYER
@export var state: InterfaceState = InterfaceState.DOWN
@export_group("Layer 3 Configuration")
@export var ip_allocation_mode: IPAllocationMode = IPAllocationMode.STATIC
@export var export_ip_address: String = ""
@export var export_subnet_mask: String = ""

var has_connection: bool = false
var ip: IPAddress

func initialize_ip_from_export() -> void:
	if layer == InterfaceLayer.SECONDLAYER:
		ip = null
		return

	if ip_allocation_mode == IPAllocationMode.DHCP:
		ip = IPAddress.new("0.0.0.0/0")
		return

	if export_ip_address == "":
		ip = IPAddress.new("192.168.1.1/24")
	else:
		ip = IPAddress.new(export_ip_address, -1)
		if export_subnet_mask != "":
			var prefix = IPAddress.prefix_from_mask(export_subnet_mask)
			if prefix >= 0:
				ip.prefix = prefix

func is_up()->bool:
	if state == InterfaceState.UP:
		return true
	else:
		return false

func verify_config(runtime_interface_config: NetworkInterface) -> Dictionary:
	var runtime_id = runtime_interface_config.id
	var runtime_mac = runtime_interface_config.mac_address
	var runtime_layer = runtime_interface_config.layer
	var runtime_state = runtime_interface_config.state
	var runtime_allocation_mode = runtime_interface_config.ip_allocation_mode

	var res_id = _verify(id, runtime_id)
	var res_mac = _verify(mac_address, runtime_mac)
	var res_layer = _verify(InterfaceLayer.keys()[layer], InterfaceLayer.keys()[runtime_layer])
	var res_state = _verify(InterfaceState.keys()[state], InterfaceState.keys()[runtime_state])
	var res_allocation_mode = _verify(IPAllocationMode.keys()[ip_allocation_mode], IPAllocationMode.keys()[runtime_allocation_mode])

	var overall_ok: bool = res_id["status"] and res_mac["status"] and res_layer["status"] and res_state["status"] and res_allocation_mode["status"]

	# Layer 3 specific verification
	var res_ip: Dictionary = { }
	if layer == InterfaceLayer.THIRDLAYER:
		if ip != null and runtime_interface_config.ip != null:
			var ip_match = ip.ip_to_string() == runtime_interface_config.ip.ip_to_string()
			res_ip = {
				"value": runtime_interface_config.ip.ip_to_string(),
				"correct": ip.ip_to_string(),
				"status": ip_match,
			}
			overall_ok = overall_ok and res_ip["status"]
		else:
			res_ip = {
				"value": runtime_interface_config.ip.ip_to_string() if runtime_interface_config.ip != null else "null",
				"correct": ip.ip_to_string() if ip != null else "null",
				"status": false,
				"error": "IP not initialized",
			}
			overall_ok = false

	var key := id.strip_edges()

	var iface := { }
	iface["status"] = overall_ok
	iface["id"] = res_id
	iface["mac_address"] = res_mac
	iface["layer"] = res_layer
	iface["state"] = res_state
	iface["ip_allocation_mode"] = res_allocation_mode
	if layer == InterfaceLayer.THIRDLAYER:
		iface["ip"] = res_ip

	var report := { }
	report[key] = iface
	return report


func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
