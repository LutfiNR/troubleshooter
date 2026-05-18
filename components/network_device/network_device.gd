extends Resource
class_name NetworkDevice

enum PowerState{
	OFF,
	ON
}

@export var device_id: String = ""
@export var hostname: String = ""
@export var power: PowerState = PowerState.OFF

func set_hostname(_hostname)-> void:
	hostname = _hostname
	
func set_power(_power: PowerState)-> void:
	power = _power

func verify_configuration(correct_config: NetworkDevice)-> bool:
	var is_correct = false
	is_correct = _verify_id(correct_config.id)
	is_correct = _verify_hostname(correct_config.hostname)
	is_correct = _verify_power(correct_config.power)
	return is_correct
	
func _verify_id(correct_id)-> bool:
	if device_id != correct_id:
		return false
	return true

func _verify_hostname(correct_hostname)-> bool:
	if device_id != correct_hostname:
		return false
	return true

func _verify_power(correct_power)-> bool:
	if device_id != correct_power:
		return false
	return true
