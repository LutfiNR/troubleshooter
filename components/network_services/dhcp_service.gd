extends Resource

class_name DHCPService

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


func verify_configuration(runtime_dhcp_service: DHCPService = null) -> Dictionary:
	var runtime_pool_name: Variant = null
	var runtime_start_ip_address: Variant = null
	var runtime_subnet_mask: Variant = null
	var runtime_default_gateway: Variant = null
	var runtime_dns_server: Variant = null
	var runtime_pool_size: Variant = null

	if runtime_dhcp_service:
		runtime_pool_name = runtime_dhcp_service.pool_name
		runtime_start_ip_address = runtime_dhcp_service.start_ip_address
		runtime_subnet_mask = runtime_dhcp_service.subnet_mask
		runtime_default_gateway = runtime_dhcp_service.default_gateway
		runtime_dns_server = runtime_dhcp_service.dns_server
		runtime_pool_size = runtime_dhcp_service.pool_size

	var res_pool_name = _verify(pool_name, runtime_pool_name)
	var res_start_ip_address = _verify(start_ip_address, runtime_start_ip_address)
	var res_subnet_mask = _verify(subnet_mask, runtime_subnet_mask)
	var res_default_gateway = _verify(default_gateway, runtime_default_gateway)
	var res_dns_server = _verify(dns_server, runtime_dns_server)
	var res_pool_size = _verify(pool_size, runtime_pool_size)

	var status: bool = (
			res_pool_name.status
			and res_start_ip_address.status
			and res_subnet_mask.status
			and res_default_gateway.status
			and res_dns_server.status
			and res_pool_size.status
	)

	return {
		pool_name: {
			"status": status,
			"pool_name": res_pool_name,
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
