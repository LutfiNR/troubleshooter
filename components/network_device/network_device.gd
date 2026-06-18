extends Resource
class_name DeviceData

enum PowerState {
	OFF,
	ON,
}

@export var device_id: String = ""
@export var hostname: String = ""
@export var power: PowerState = PowerState.OFF
@export var interfaces: Array[NetworkInterface]


func setup_device() -> void:
	if interfaces == null:
		interfaces = []
	for interface in interfaces:
		interface.initialize_ip_from_export()

func get_interface(interface_id: String) -> NetworkInterface:
	var interface
	for iface in interfaces:
		if iface.id == interface_id:
			interface = iface
	return interface

func get_interfaces()-> Array:
	return interfaces

func verify_configuration(runtime_network_device: DeviceData) -> Dictionary:
	var runtime_device_id = runtime_network_device.device_id
	var runtime_hostname = runtime_network_device.hostname
	var runtime_power = runtime_network_device.power

	var res_device_id = _verify(device_id, runtime_device_id)
	var res_hostname = _verify(hostname, runtime_hostname)
	var res_power = _verify(PowerState.keys()[power], PowerState.keys()[runtime_power])

	var interfaces_ok: bool = true
	var interfaces_results: Dictionary
	for i in interfaces.size():
		var interface_report = interfaces[i].verify_config(runtime_network_device.interfaces[i])
		interfaces_results.merge(interface_report)
		interfaces_ok = interfaces_ok and interface_report[interfaces[i].id]["status"]
	var overall_ok: bool = res_device_id["status"] and res_hostname["status"] and res_power["status"] and interfaces_ok

	var key := device_id.strip_edges()
	var dev := { }
	dev["status"] = overall_ok
	dev["device_id"] = res_device_id
	dev["hostname"] = res_hostname
	dev["power"] = res_power
	dev["interfaces"] = interfaces_results

	var report := { }
	report[key] = dev
	return report


func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
