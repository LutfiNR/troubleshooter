extends Resource

class_name DHCPService

@export var pool_name: String
@export var interface_id: String = ""
@export var default_gateway: String
@export var dns_server: String
@export var start_ip_address: String
@export var subnet_mask: String
@export var pool_size: int = 254

var leased_ips: Dictionary = { }
var used_ips: Array[String] = []


func _ip_to_int(address: String) -> int:
	var ip_obj = IPAddress.new(address, -1)
	if not ip_obj.is_valid():
		return -1
	var octets = ip_obj.get_octets()
	return (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3]


func _int_to_ip(value: int) -> String:
	return "%d.%d.%d.%d" % [
		(value >> 24) & 0xFF,
		(value >> 16) & 0xFF,
		(value >> 8) & 0xFF,
		value & 0xFF,
	]


func _generate_ip(index: int) -> String:
	var base_value = _ip_to_int(start_ip_address)
	if base_value < 0:
		push_error("DHCPService._generate_ip(): invalid start_ip_address %s" % start_ip_address)
		return ""

	var generated_value = base_value + index
	if generated_value < 0 or generated_value > 0xFFFFFFFF:
		push_error("DHCPService._generate_ip(): generated IP out of range")
		return ""

	return _int_to_ip(generated_value)


func _is_ip_in_current_pool(ip_address: String) -> bool:
	var ip_value := _ip_to_int(ip_address)
	var pool_start := _ip_to_int(start_ip_address)
	if ip_value < 0 or pool_start < 0 or pool_size <= 0:
		return false
	return ip_value >= pool_start and ip_value < pool_start + pool_size


func request_ip(mac: String) -> Dictionary:
	if leased_ips.has(mac):
		var existing_ip: String = leased_ips[mac]
		if _is_ip_in_current_pool(existing_ip):
			return _build_config(existing_ip)
		release_ip(mac)

	# Find the next available IP in the pool
	for i in range(pool_size):
		var ip = _generate_ip(i)
		if ip == "":
			continue
		if not used_ips.has(ip):
			used_ips.append(ip)
			leased_ips[mac] = ip
			return _build_config(ip)

	push_error("DHCP Pool '%s' is full!" % pool_name)
	return { "success": false }


func release_ip(mac: String) -> void:
	if leased_ips.has(mac):
		var ip = leased_ips[mac]
		used_ips.erase(ip)
		leased_ips.erase(mac)


func _build_config(ip_address: String) -> Dictionary:
	return {
		"success": true,
		"ip_address": ip_address,
		"default_gateway": default_gateway,
		"dns_server": dns_server,
		"subnet_mask": subnet_mask,
	}


func verify_configuration(runtime_dhcp_service: DHCPService = null) -> Dictionary:
	var runtime_pool_name: Variant = null
	var runtime_interface_id: Variant = null
	var runtime_start_ip_address: Variant = null
	var runtime_subnet_mask: Variant = null
	var runtime_default_gateway: Variant = null
	var runtime_dns_server: Variant = null
	var runtime_pool_size: Variant = null

	if runtime_dhcp_service:
		runtime_pool_name = runtime_dhcp_service.pool_name
		runtime_interface_id = runtime_dhcp_service.interface_id
		runtime_start_ip_address = runtime_dhcp_service.start_ip_address
		runtime_subnet_mask = runtime_dhcp_service.subnet_mask
		runtime_default_gateway = runtime_dhcp_service.default_gateway
		runtime_dns_server = runtime_dhcp_service.dns_server
		runtime_pool_size = runtime_dhcp_service.pool_size

	var res_pool_name = _verify(pool_name, runtime_pool_name)
	var res_interface_id = _verify(interface_id, runtime_interface_id)
	var res_start_ip_address = _verify(start_ip_address, runtime_start_ip_address)
	var res_subnet_mask = _verify(subnet_mask, runtime_subnet_mask)
	var res_default_gateway = _verify(default_gateway, runtime_default_gateway)
	var res_dns_server = _verify(dns_server, runtime_dns_server)
	var res_pool_size = _verify(pool_size, runtime_pool_size)

	var status: bool = (
		res_pool_name.status and res_interface_id.status
		and res_start_ip_address.status and res_subnet_mask.status
		and res_default_gateway.status and res_dns_server.status and res_pool_size.status
	)

	var key: String = pool_name if pool_name != "" else "unnamed"
	return {
		key: {
			"status": status,
			"pool_name": res_pool_name,
			"interface_id": res_interface_id,
			"start_ip_address": res_start_ip_address,
			"subnet_mask": res_subnet_mask,
			"default_gateway": res_default_gateway,
			"dns_server": res_dns_server,
			"pool_size": res_pool_size,
		},
	}


func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
