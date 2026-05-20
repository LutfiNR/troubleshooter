extends Resource

class_name MissionData

@export var id: String
@export var title: String
@export_multiline var description: String
@export var computer_devices: Dictionary[String, ComputerDevice]
@export var router_devices: Dictionary[String, RouterDevice]
@export var switch_devices: Dictionary[String, SwitchDevice]
@export var server_devices: Dictionary[String, ServerDevice]
@export var connections: Dictionary[String, NetworkConnection]
