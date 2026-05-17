extends Node
class_name Networkmanager

enum PlayMode{
	MISSION,
	EXPLORATION
}

var play_mode: PlayMode
# temp var for generating computer's id
var computer_number_id: int = -1
var computer_devices: Dictionary[String,ComputerDevice]
var router_number_id: int = -1
#var computer_devices: Dictionary[String,ServerDevice]
var server_number_id: int = -1
#var computer_devices: Dictionary[String,RouterDevice]
var switch_number_id: int = -1
#var computer_devices: Dictionary[String,SwitchDevice]

func setup_device(device_type)-> void:
	var device
	if device_type == PlaceableItem.Type.COMPUTER:
		device = ComputerDevice.new(_generate_id(device_type))
		computer_devices[device.id] = device
		print("[NETWORK MANAGER] Total Device: " + str(computer_devices.size()))
	if device:
		print("[NETWORK MANAGER] Setup Device " + device.id)

func _generate_id(type: PlaceableItem.Type)-> String:
	var id: String
	if type == PlaceableItem.Type.COMPUTER:
		id = "computer_" + str(computer_number_id)
		computer_number_id += 1
	#if type == PlaceableItem.Type.SERVER:
		#id = "server_" + str(server_number_id)
		#server_number_id += 1
	#if type == PlaceableItem.Type.ROUTER:
		#id = "router_" + str(router_number_id)
		#router_number_id += 1
	#if type == PlaceableItem.Type.SWITCH:
		#id = "switch_" + str(switch_number_id)
		#switch_number_id += 1
	return id
