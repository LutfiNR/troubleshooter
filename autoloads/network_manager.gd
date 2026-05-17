extends Node
class_name Networkmanager
signal device_updated(id: String)

enum PlayMode{
	MISSION,
	EXPLORATION
}

var play_mode: PlayMode
# temp var for generating id's device
var computer_number_id: int = 0
var server_number_id: int = 0
var router_number_id: int = 0
var switch_number_id: int = 0
var computer_devices: Dictionary[String,ComputerDevice]
#var computer_devices: Dictionary[String,ServerDevice]
#var computer_devices: Dictionary[String,RouterDevice]
#var computer_devices: Dictionary[String,SwitchDevice]

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
func setup_device(device_type)-> void:
	var device
	if device_type == PlaceableItem.Type.COMPUTER:
		device = ComputerDevice.new(_generate_id(device_type))
		computer_devices[device.id] = device
		print("[NETWORK MANAGER] Total Device: " + str(computer_devices.size()))
	if device:
		print("[NETWORK MANAGER] Setup Device " + device.id)

func get_device(id: String):
	if computer_devices.get(id):
		return computer_devices.get(id)
	return null

func set_device_power(id: String)-> void:
	var dev = get_device(id)
	if dev == null:
		return
	if dev.power == NetworkDevice.PowerState.ON:
		dev.set_power(NetworkDevice.PowerState.OFF)
	else:
		dev.set_power(NetworkDevice.PowerState.ON)
	print("[NetworkManager] ", dev.id, "'s Power State change to ", dev.power)
	device_updated.emit(id)
