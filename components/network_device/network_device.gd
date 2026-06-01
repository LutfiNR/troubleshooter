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
func verify_configuration(runtime_device_configuration: NetworkDevice) -> Dictionary:
	var hostname_result := _verify_hostname(runtime_device_configuration.hostname)
	var power_result := _verify_power(runtime_device_configuration.power)

	var is_correct: bool = (
			hostname_result.status
			and power_result.status
	)

	return {
		"device_id": device_id,
		"status": is_correct,
		"hostname": hostname_result,
		"power": power_result,
	}


# Verify hostname
func _verify_hostname(runtime_device_hostname: String) -> Dictionary:
	var result := hostname == runtime_device_hostname

	return {
		"correct": hostname,
		"value": runtime_device_hostname,
		"status": result,
	}


# Verify power state
func _verify_power(runtime_device_power: PowerState) -> Dictionary:
	var result := power == runtime_device_power

	return {
		"correct": PowerState.keys()[power],
		"value": PowerState.keys()[runtime_device_power],
		"status": result,
	}
