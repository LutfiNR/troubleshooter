extends Node
class_name Networkmanager

var devices: Dictionary[String,NetworkDevice]

func setup_device(network_device: NetworkDevice)-> void:
	devices[network_device.id] = network_device
	print("Setup Device --- " + network_device.id)
	print("Total Device: " + str(devices.size()))

func get_devices_size()-> int:
	return devices.size()
