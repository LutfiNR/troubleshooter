extends Resource
class_name NetworkDevice

enum PowerState{
	OFF,
	ON
}

@export var id: String = ""
@export var hostname: String = ""
@export var power: PowerState = PowerState.OFF

func verify_configuration(correct_config: NetworkDevice)-> bool:
	var is_correct = false
	is_correct = verify_id(correct_config.id)
	is_correct = verify_hostname(correct_config.hostname)
	is_correct = verify_power(correct_config.power)
	return is_correct
	
func verify_id(correct_id)-> bool:
	if id != correct_id:
		return false
	return true

func verify_hostname(correct_hostname)-> bool:
	if id != correct_hostname:
		return false
	return true

func verify_power(correct_power)-> bool:
	if id != correct_power:
		return false
	return true
