extends Resource

class_name DNSRecord

enum RecordType { A_RECORD, CNAME, MX_RECORD }

@export var domain_name: String = "example.com"
@export var type: RecordType = RecordType.A_RECORD
@export var target_ip_or_name: String = ""


func verify_configuration(runtime_record: DNSRecord = null) -> Dictionary:
	var runtime_domain_name: Variant = null
	var runtime_type: Variant = null
	var runtime_target: Variant = null

	if runtime_record:
		runtime_domain_name = runtime_record.domain_name
		runtime_type = RecordType.keys()[runtime_record.type]
		runtime_target = runtime_record.target_ip_or_name

	var res_domain_name = _verify(domain_name,runtime_domain_name)
	var res_type = _verify(RecordType.keys()[type],runtime_type)
	var res_target = _verify(target_ip_or_name,runtime_target)
	var status: bool = (res_domain_name.status and res_type.status and res_target.status)

	return {
		"status": status,
		"domain_name": res_domain_name,
		"type": res_type,
		"target": res_target,
	}

func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null

	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
