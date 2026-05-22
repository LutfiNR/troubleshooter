extends Resource
class_name DNSRecord

enum RecordType { A_RECORD, CNAME, MX_RECORD }

@export var domain_name: String = ""
@export var type: RecordType = RecordType.A_RECORD
@export var target_ip_or_name: String = ""

func verify_configuration(correct_record: DNSRecord) -> Dictionary:
	if not correct_record:
		return { "status": false, "error": "Invalid record" }
	var is_correct = (
			domain_name == correct_record.domain_name and
			type == correct_record.type and
			target_ip_or_name == correct_record.target_ip_or_name
	)
	return {
		"status": is_correct,
		"domain_name": { "value": domain_name, "correct": correct_record.domain_name },
		"type": { "value": type, "correct": correct_record.type },
		"target": { "value": target_ip_or_name, "correct": correct_record.target_ip_or_name },
	}
