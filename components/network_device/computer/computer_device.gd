extends NetworkDevice
class_name ComputerDevice

enum IPAllocationType{
	STATIC,
	DHCP
}

@export var ip_allocation_type: IPAllocationType = IPAllocationType.STATIC
@export var default_gateway: String = ""
@export var dns_server: String = ""
@export var interface: NetworkInterface

func _init(_device_id: String) -> void:
	device_id = _device_id
	interface = NetworkInterface.new("eth0")
