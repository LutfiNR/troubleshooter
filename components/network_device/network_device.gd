extends Resource

class_name NetworkDevice

enum PowerState {
	OFF,
	ON,
}

@export var device_id: String = ""
@export var hostname: String = ""
@export var power: PowerState = PowerState.OFF


# Set device hostname
func set_hostname(value: String) -> void:
	hostname = value


# Set device power state
func set_power(value: PowerState) -> void:
	power = value


# Verify full device configuration
func verify_configuration(correct_device: NetworkDevice) -> Dictionary:
	var id_result := _verify_id(correct_device.device_id)
	var hostname_result := _verify_hostname(correct_device.hostname)
	var power_result := _verify_power(correct_device.power)

	var is_correct: bool = (
			id_result.status
			and hostname_result.status
			and power_result.status
	)

	return {
		"device_id": device_id,
		"status": is_correct,
		"id": id_result,
		"hostname": hostname_result,
		"power": power_result,
	}


# Verify device id
func _verify_id(correct_id: String) -> Dictionary:
	var result := device_id == correct_id
	return {
		"value": device_id,
		"correct": correct_id,
		"status": result,
	}


# Verify hostname
func _verify_hostname(correct_hostname: String) -> Dictionary:
	var result := hostname == correct_hostname

	return {
		"value": hostname,
		"correct": correct_hostname,
		"status": result,
	}


# Verify power state
func _verify_power(correct_power: PowerState) -> Dictionary:
	var result := power == correct_power

	return {
		"value": power,
		"correct": correct_power,
		"status": result,
	}
