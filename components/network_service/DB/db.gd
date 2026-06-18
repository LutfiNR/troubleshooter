class_name MariaDBDatabase extends Resource
@export var db_name: String = ""

func verify_configuration(runtime_db: MariaDBDatabase = null) -> Dictionary:
	var runtime_db_name: Variant = null
	if runtime_db:
		runtime_db_name = runtime_db.db_name
	var res_db_name = _verify(db_name, runtime_db_name)
	return {
		"status": res_db_name.status,
		"db_name": res_db_name,
	}

func _verify(config: Variant, runtime_config: Variant = null) -> Dictionary:
	var has_runtime := runtime_config != null
	return {
		"value": runtime_config if has_runtime else null,
		"correct": config,
		"status": has_runtime and config == runtime_config,
	}
