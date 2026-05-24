class_name IPAddress
extends RefCounted

const IPV4_MAX_STRING_LENGTH := 15
const IPV4_OCTET_COUNT := 4
const IPV4_MAX_PREFIX_LENGTH := 32

var address: String = ""
var subnet_mask: String = ""
var prefix_length: int = 32
var valid: bool = false


func setup_ip_address(ip: String = "", mask: String = "255.255.255.0") -> void:
	address = ip
	subnet_mask = mask
	valid = is_host_address_valid(ip, mask)


# Static Validation Helpers
static func is_ip_address_valid(ip_address: String) -> bool:
	if ip_address.length() > IPV4_MAX_STRING_LENGTH:
		return false
	var parts := ip_address.split(".")
	if parts.size() != IPV4_OCTET_COUNT:
		return false
	for part in parts:
		if part.is_empty() or not part.is_valid_int():
			return false
		if part.length() > 1 and part.begins_with("0"):
			return false
		var value := int(part)
		if value < 0 or value > 255:
			return false
	return true


static func is_subnet_mask_valid(mask: String) -> bool:
	if not is_ip_address_valid(mask):
		return false
	var value := ipv4_string_to_int(mask)
	if value == 0:
		return false
	value &= 0xffffffff
	var inverted := (~value) & 0xffffffff
	return (inverted & (inverted + 1)) == 0


static func is_prefix_length_valid(prefix: int) -> bool:
	return prefix >= 0 and prefix <= IPV4_MAX_PREFIX_LENGTH


static func is_host_address_valid(ip: String, mask: String) -> bool:
	if not is_ip_address_valid(ip):
		return false
	if not is_subnet_mask_valid(mask):
		return false
	var ip_int := ipv4_string_to_int(ip) & 0xffffffff
	var mask_int := ipv4_string_to_int(mask) & 0xffffffff
	var network := ip_int & mask_int
	var broadcast := network | ((~mask_int) & 0xffffffff)
	if ip_int == network:
		return false
	if ip_int == broadcast:
		return false
	return true


# Instance Methods
func to_int() -> int:
	return ipv4_string_to_int(address)


func get_network_address() -> String:
	var ip := ipv4_string_to_int(address)
	var mask := ipv4_string_to_int(subnet_mask)
	return int_to_ipv4(ip & mask)


func get_broadcast_address() -> String:
	var ip := ipv4_string_to_int(address)
	var mask := ipv4_string_to_int(subnet_mask)
	var broadcast := (ip & mask) | ((~mask) & 0xffffffff)
	return int_to_ipv4(broadcast)


func get_prefix_length() -> int:
	return subnet_mask_to_prefix(subnet_mask)


func set_prefix_length(prefix: int) -> void:
	if not is_prefix_length_valid(prefix):
		return
	prefix_length = prefix
	subnet_mask = prefix_to_subnet_mask(prefix)


# Internal Conversion Utils
static func ipv4_string_to_int(ip: String) -> int:
	var result := 0
	for part in ip.split("."):
		result = (result << 8) | int(part)
	return result & 0xffffffff


static func int_to_ipv4(value: int) -> String:
	value &= 0xffffffff
	return "%d.%d.%d.%d" % [
		(value >> 24) & 0xff,
		(value >> 16) & 0xff,
		(value >> 8) & 0xff,
		value & 0xff,
	]


static func prefix_to_subnet_mask(prefix: int) -> String:
	if not is_prefix_length_valid(prefix):
		return ""
	var mask := 0
	if prefix > 0:
		mask = ((1 << prefix) - 1) << (32 - prefix)
	return int_to_ipv4(mask)


static func subnet_mask_to_prefix(mask: String) -> int:
	if not is_subnet_mask_valid(mask):
		return -1
	var value := ipv4_string_to_int(mask)
	var prefix := 0
	for i in range(32):
		if value & (1 << (31 - i)):
			prefix += 1
		else:
			break
	return prefix


# Verify IP configuration
func verify_configuration(correct_configuration: IPAddress) -> Dictionary:
	var address_result := _verify_address(correct_configuration.address)
	var subnet_result := _verify_subnet_mask(correct_configuration.subnet_mask)
	var is_correct: bool = (
			address_result.status
			and subnet_result.status
	)
	if not correct_configuration:
		return {
			"status": false,
			"address": address_result,
			"subnet_mask": subnet_result,
			"error": "Invalid comparison IP",
		}

	return {
		"address": address_result,
		"subnet_mask": subnet_result,
		"status": is_correct,
	}


# Verify IP address
func _verify_address(correct_address: String) -> Dictionary:
	var result := address == correct_address
	return {
		"value": address,
		"correct": correct_address,
		"status": result,
	}


# Verify subnet mask
func _verify_subnet_mask(correct_subnet: String) -> Dictionary:
	var result := subnet_mask == correct_subnet
	return {
		"value": subnet_mask,
		"correct": correct_subnet,
		"status": result,
	}
