extends Resource

class_name DHCPService

@export var interface_id: String
@export var pool_name: String
@export var default_gateway: String
@export var dns_server: String
@export var start_ip_address: String
@export var subnet_mask: String
@export var pool_size: int = 254

var leased_ips: Dictionary = { }
var used_ips: Array[String] = []


func _generate_ip(index: int) -> String:
	var parts = start_ip_address.split(".")
	parts[3] = str(int(parts[3]) + index)
	return ".".join(parts)


func request_ip(mac: String) -> Dictionary:
	if leased_ips.has(mac):
		return _build_config(leased_ips[mac])
	for i in range(pool_size):
		var ip = _generate_ip(i)
		if not used_ips.has(ip):
			used_ips.append(ip)
			leased_ips[mac] = ip
			return _build_config(ip)
	push_error("DHCP Pool full!")
	return { }


func _build_config(ip_address: String) -> Dictionary:
	return {
		"ip_address": ip_address,
		"default_gateway": default_gateway,
		"dns_server": dns_server,
		"subnet_mask": subnet_mask,
	}


func verify_configuration(correct_dhcp: DHCPService) -> Dictionary:
	if not correct_dhcp:
		return { "status": false, "error": "Invalid DHCP config" }

	var checks = {
		"interface_id": interface_id == correct_dhcp.interface_id,
		"start_ip_address": start_ip_address == correct_dhcp.start_ip_address,
		"subnet_mask": subnet_mask == correct_dhcp.subnet_mask,
		"default_gateway": default_gateway == correct_dhcp.default_gateway,
		"dns_server": dns_server == correct_dhcp.dns_server,
		"pool_size": pool_size == correct_dhcp.pool_size,
	}

	var is_correct = true
	var result = { "status": false }

	for key in checks:
		if not checks[key]:
			is_correct = false
		result[key] = { "status": checks[key] }

	result.status = is_correct
	return result
