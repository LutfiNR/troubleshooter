extends Resource

class_name NetworkConnection

@export var connection_id := ""

@export var device_a_id := ""
@export var interface_a_id := ""

@export var device_b_id := ""
@export var interface_b_id := ""


func is_valid() -> bool:
	return (
			not connection_id.is_empty()
			and not device_a_id.is_empty()
			and not interface_a_id.is_empty()
			and not device_b_id.is_empty()
			and not interface_b_id.is_empty()
	)


func matches(other: NetworkConnection) -> bool:
	if not other:
		return false

	return (
			(
					device_a_id == other.device_a_id
					and interface_a_id == other.interface_a_id
					and device_b_id == other.device_b_id
					and interface_b_id == other.interface_b_id
			)
			or
			(
					device_a_id == other.device_b_id
					and interface_a_id == other.interface_b_id
					and device_b_id == other.device_a_id
					and interface_b_id == other.interface_a_id
			)
	)


func contains(device_id: String, interface_id: String) -> bool:
	return (
			(device_a_id == device_id and interface_a_id == interface_id)
			or
			(device_b_id == device_id and interface_b_id == interface_id)
	)


func get_other(device_id: String, interface_id: String) -> Dictionary:
	if device_a_id == device_id and interface_a_id == interface_id:
		return {
			"device_id": device_b_id,
			"interface_id": interface_b_id,
		}

	if device_b_id == device_id and interface_b_id == interface_id:
		return {
			"device_id": device_a_id,
			"interface_id": interface_a_id,
		}

	return { }
