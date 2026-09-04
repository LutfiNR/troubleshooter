extends Resource

class_name DNSService

@export var records: Array[DNSRecord] = []


func _ready() -> void:
	_check_duplicate_record()


func resolve(domain: String) -> String:
	for record in records:
		if (
			record != null and record.type == DNSRecord.RecordType.A_RECORD
			and record.domain_name == domain
		):
			return record.target_ip_or_name
	for record in records:
		if (
			record != null and record.type == DNSRecord.RecordType.CNAME
			and record.domain_name == domain
		):
			return resolve(record.target_ip_or_name)
	return ""


func resolve_mx(domain: String) -> String:
	for record in records:
		if (
			record != null and record.type == DNSRecord.RecordType.MX_RECORD
			and record.domain_name == domain
		):
			var ip_address = resolve(record.target_ip_or_name)
			if ip_address != "":
				return ip_address
			if record.target_ip_or_name.count(".") == 3:
				return record.target_ip_or_name
	return ""


func _check_duplicate_record() -> void:
	var is_duplicate: bool = false
	for record in records:
		for rec in records:
			if (
				record.domain_name == rec.domain_name
				and record.type == rec.type and record.target == rec.target
			):
				is_duplicate = true

	if is_duplicate:
		push_warning("there is duplicate record")


func verify_configuration(runtime_dns_service: DNSService = null) -> Dictionary:
	var result: Dictionary = { }
	for record in records:
		var matched_record: DNSRecord = null
		if runtime_dns_service:
			for runtime_record in runtime_dns_service.records:
				if (
					runtime_record.domain_name == record.domain_name
					and runtime_record.type == record.type
				):
					matched_record = runtime_record
					break
		result[record.domain_name + ":" + DNSRecord.RecordType.keys()[record.type]] = (
			record.verify_configuration(matched_record)
			if matched_record
			else record.verify_configuration()
		)
	return result
