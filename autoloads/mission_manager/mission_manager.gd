extends Node

@onready var correct_configuration: MissionData = preload("uid://dnhqwjp4v230l")
@onready var empty_configuration: MissionData = preload("uid://w7qdrtr7ey75")

var correct_computer_devices

func _ready() -> void:
	NetworkDeviceManager.device_updated.connect(_on_device_updated)
	load_mission_configuration(empty_configuration)
	correct_computer_devices = correct_configuration.computer_devices
	
func load_mission_configuration(configuration: MissionData)-> void:
	if configuration:
		for device_id in configuration.computer_devices:
			NetworkDeviceManager.add_device_data(configuration.computer_devices.get(device_id))
		print("[MissionManager] Mission loaded: " + configuration.title)

func _on_device_updated(device_id: String) -> void:
	for device_key in NetworkDeviceManager.computer_devices:
		var current_device: ComputerDevice = NetworkDeviceManager.computer_devices[device_key]
		var correct_device: ComputerDevice = correct_computer_devices[device_key]
		
		var result := current_device.verify_configuration(correct_device)
		
		print_rich("\n[color=cyan]=== Verification Result ===[/color]")
		print_rich("[b]Device:[/b] ", result.device_id)
		print_rich("[b]Overall:[/b] ", result.status)
		
		for key in result.keys():
			if key in ["device_id", "status"]:
				continue
			
			if result[key] is Dictionary and result[key].has("status"):
				print_rich(
					"• ",
					key.capitalize(),
					": ",
					result[key].status
				)
