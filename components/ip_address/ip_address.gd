class_name IPAddress
extends RefCounted

const DEFAULT_MASKS = {
	"A": "255.0.0.0",
	"B": "255.255.0.0",
	"C": "255.255.255.0",
	"D": "255.255.255.255",
	"E": "255.255.255.255",
}

var octets: Array[int] = [0, 0, 0, 0]
var prefix: int = -1


func _init(ip: String = "", prefix_length: int = -1) -> void:
	if ip != "":
		set_ip(ip, prefix_length)


static func parse(ip: String) -> IPAddress:
	var instance = IPAddress.new()
	instance.set_ip(ip)
	return instance


static func is_valid_ip(ip: String) -> bool:
	var raw = ip.strip_edges()
	if raw == "":
		return false

	var parts = raw.split("/")
	var prefix_length = -1
	if parts.size() > 2 or parts[0] == "":
		return false
	if parts.size() == 2:
		if not parts[1].is_valid_int():
			return false
		prefix_length = int(parts[1])

	var octet_strings = parts[0].split(".")
	if octet_strings.size() != 4:
		return false

	for octet_string in octet_strings:
		if not octet_string.is_valid_int():
			return false
		var n = int(octet_string)
		if n < 0 or n > 255:
			return false

	if prefix_length != -1 and (prefix_length < 0 or prefix_length > 32):
		return false

	return true


func set_ip(ip: String, prefix_length: int = -1) -> void:
	var raw = ip.strip_edges()
	if raw == "":
		push_error("IPAddress.set_ip(): empty address")
		return

	var parts = raw.split("/")
	if parts.size() > 2 or parts[0] == "":
		push_error("IPAddress.set_ip(): invalid IPv4 format")
		return
	if parts.size() == 2:
		if not parts[1].is_valid_int():
			push_error("IPAddress.set_ip(): invalid prefix %s" % parts[1])
			return
		prefix_length = int(parts[1])

	var octet_strings = parts[0].split(".")
	if octet_strings.size() != 4:
		push_error("IPAddress.set_ip(): invalid IPv4 format")
		return

	for i in range(4):
		if not octet_strings[i].is_valid_int():
			push_error("IPAddress.set_ip(): invalid octet %s" % octet_strings[i])
			return
		var value = int(octet_strings[i])
		if value < 0 or value > 255:
			push_error("IPAddress.set_ip(): invalid octet %s" % octet_strings[i])
			return
		octets[i] = value

	if prefix_length >= 0 and prefix_length <= 32:
		prefix = prefix_length
	else:
		prefix = -1


func set_ip_and_mask(ip: String, subnet_mask: String) -> bool:
	if not is_valid_ip(ip):
		push_error("IPAddress.set_ip_and_mask(): invalid IP %s" % ip)
		return false
	if not is_valid_mask(subnet_mask):
		push_error("IPAddress.set_ip_and_mask(): invalid subnet mask %s" % subnet_mask)
		return false

	set_ip(ip)
	var new_prefix = prefix_from_mask(subnet_mask)
	if new_prefix < 0:
		push_error("IPAddress.set_ip_and_mask(): invalid subnet mask %s" % subnet_mask)
		self.prefix = -1
		return false
	self.prefix = new_prefix
	return true


func ip_to_string() -> String:
	var text = "%d.%d.%d.%d" % [octets[0], octets[1], octets[2], octets[3]]
	if prefix >= 0:
		text += "/%d" % prefix
	return text


func is_valid() -> bool:
	for octet in octets:
		if octet < 0 or octet > 255:
			return false
	return prefix == -1 or (prefix >= 0 and prefix <= 32)


func get_ip_class() -> String:
	var first = octets[0]
	if first >= 0 and first <= 127:
		return "A"
	if first >= 128 and first <= 191:
		return "B"
	if first >= 192 and first <= 223:
		return "C"
	if first >= 224 and first <= 239:
		return "D"
	return "E"


func get_default_mask() -> String:
	return DEFAULT_MASKS[get_ip_class()]


func get_octets() -> Array[int]:
	return octets.duplicate()


func get_mask_octets() -> Array[int]:
	var mask = get_subnet_mask()
	var octet_strings = mask.split(".")
	var mask_octets: Array[int] = []
	for s in octet_strings:
		mask_octets.append(int(s))
	return mask_octets


func get_subnet_mask() -> String:
	if prefix >= 0:
		return subnet_mask_from_prefix(prefix)
	return get_default_mask()


static func subnet_mask_from_prefix(prefix_length: int) -> String:
	if prefix_length < 0 or prefix_length > 32:
		push_error("IPAddress.subnet_mask_from_prefix(): invalid prefix %d" % prefix_length)
		return "0.0.0.0"

	var parts: Array[String] = []
	for i in range(4):
		var value = 0
		for bit in range(8):
			var bit_index = i * 8 + bit
			if bit_index < prefix_length:
				value |= 1 << (7 - bit)
		parts.append(str(value))
	return ".".join(parts)


static func prefix_from_mask(mask: String) -> int:
	var parts = mask.strip_edges().split(".")
	if parts.size() != 4:
		push_error("IPAddress.prefix_from_mask(): invalid mask format")
		return -1

	var mask_int = 0
	for part in parts:
		if not part.is_valid_int():
			push_error("IPAddress.prefix_from_mask(): invalid octet %s" % part)
			return -1
		var n = int(part)
		if n < 0 or n > 255:
			push_error("IPAddress.prefix_from_mask(): invalid octet %s" % part)
			return -1
		mask_int = mask_int << 8 | n

	var seen_zero = false
	var count = 0
	for i in range(31, -1, -1):
		var bit = (mask_int >> i) & 1
		if bit == 1:
			if seen_zero:
				push_error("IPAddress.prefix_from_mask(): invalid non-contiguous mask %s" % mask)
				return -1
			count += 1
		else:
			seen_zero = true

	return count


static func is_valid_mask(mask: String) -> bool:
	return prefix_from_mask(mask) >= 0


static func is_valid_host_ip(ip: String, subnet_mask: String) -> bool:
	if not is_valid_ip(ip) or not is_valid_mask(subnet_mask):
		return false

	var address := IPAddress.parse(ip)
	address.set_ip_and_mask(ip, subnet_mask)
	var address_text := address.ip_to_string().split("/")[0]
	return address_text != address.get_network_address() \
			and address_text != address.get_broadcast_address()


func get_network_address() -> String:
	var mask_octets = get_mask_octets()
	var network = []
	for i in range(4):
		network.append(octets[i] & mask_octets[i])
	return "%d.%d.%d.%d" % [network[0], network[1], network[2], network[3]]


func get_broadcast_address() -> String:
	var mask_octets = get_mask_octets()
	var network = []
	for i in range(4):
		network.append(octets[i] & mask_octets[i])
	var broadcast = []
	for i in range(4):
		broadcast.append(network[i] | (~mask_octets[i] & 0xFF))
	return "%d.%d.%d.%d" % [broadcast[0], broadcast[1], broadcast[2], broadcast[3]]


func total_hosts() -> int:
	if prefix < 0 or prefix > 32:
		return 0
	var host_bits = 32 - prefix
	if host_bits == 0:
		return 1
	if host_bits == 1:
		return 2
	return (1 << host_bits) - 2


func is_same_subnet(other: IPAddress) -> bool:
	if other == null:
		return false
	if prefix < 0 or other.prefix < 0:
		return false
	return get_network_address() == other.get_network_address()


func is_private() -> bool:
	var n = octets[0]
	var m = octets[1]
	if n == 10:
		return true
	if n == 172 and m >= 16 and m <= 31:
		return true
	if n == 192 and m == 168:
		return true
	return false


func copy() -> IPAddress:
	var duplicate = IPAddress.new()
	duplicate.octets = get_octets()
	duplicate.prefix = prefix
	return duplicate
