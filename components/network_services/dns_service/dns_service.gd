extends Resource

class_name DNSService

@export var records: Array[DNSRecord] = []

func resolve(domain: String) -> String:
	for record in records:
		if record != null and record.type == DNSRecord.RecordType.A_RECORD and record.domain_name == domain:
			return record.target_ip_or_name
	for record in records:
		if record != null and record.type == DNSRecord.RecordType.CNAME and record.domain_name == domain:
			return resolve(record.target_ip_or_name)
	return ""


func resolve_mx(domain: String) -> String:
	for record in records:
		if record != null and record.type == DNSRecord.RecordType.MX_RECORD and record.domain_name == domain:
			var ip_address = resolve(record.target_ip_or_name)
			if ip_address != "":
				return ip_address
			if record.target_ip_or_name.count(".") == 3:
				return record.target_ip_or_name
	return ""


func verify_configuration(correct_dns: DNSService) -> Dictionary:
	if not correct_dns:
		return { "status": false, "error": "Invalid DNS config" }

	var is_correct = true
	var records_result = { "status": true, "details": { } }

	for c_record in correct_dns.records:
		var found = false
		for p_record in records:
			if p_record.domain_name == c_record.domain_name and p_record.type == c_record.type:
				found = true
				var v = p_record.verify_configuration(c_record)
				records_result.details[c_record.domain_name] = v
				if not v.status:
					records_result.status = false
				break
		if not found:
			records_result.details[c_record.domain_name] = { "status": false, "error": "Missing record" }
			records_result.status = false

	if not records_result.status:
		is_correct = false
	return { "status": is_correct, "records": records_result }
