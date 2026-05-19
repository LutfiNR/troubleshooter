extends NetworkDevice
class_name ComputerDevice

enum IPAllocationType{
	STATIC,
	DHCP
}

@export var ip_allocation_type: IPAllocationType = IPAllocationType.STATIC
@export var default_gateway: String = ""
@export var dns_server: String = ""
@export var interfaces: Array[NetworkInterface] = []

func _init() -> void:
	var iface: NetworkInterface = NetworkInterface.new()
	iface.id = "eth0"
	interfaces.append(iface) 
