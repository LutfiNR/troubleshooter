extends Node
class_name Networkmanager

enum PlayMode{
	MISSION,
	EXPLORATION
}

var play_mode: PlayMode
var devices: Dictionary[String,NetworkDevice]

func setup_device(network_device: NetworkDevice)-> void:
	devices[network_device.id] = network_device
	print("[NETWORK MANAGR] Setup Device " + network_device.id)
	print("[NETWORK MANAGER] Total Device: " + str(devices.size()))

func get_devices_size()-> int:
	return devices.size()
