extends Resource
class_name NetworkDevice

enum PowerState{
	OFF,
	ON
}

@export var id: String = ""
@export var hostname: String = ""
@export var power: PowerState = PowerState.OFF

func _init(_id: String) -> void:
	id = _id

func verify_configuration(correct_config: NetworkDevice)-> bool:
	var is_correct = false
	is_correct = _verify_id(correct_config.id)
	is_correct = _verify_hostname(correct_config.hostname)
	is_correct = _verify_power(correct_config.power)
	return is_correct
	
func _verify_id(correct_id)-> bool:
	if id != correct_id:
		return false
	return true

func _verify_hostname(correct_hostname)-> bool:
	if id != correct_hostname:
		return false
	return true

func _verify_power(correct_power)-> bool:
	if id != correct_power:
		return false
	return true
